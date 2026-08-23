import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/constants/hive_box_names.dart';
import 'mock_interceptor.dart';

/// In-memory mock Identity store for Sprint 1 auth flows.
class _MockAuthStore {
  String? phone;
  String? role;
  String? displayName;
  String? accessToken;
  String? refreshToken;

  void clearSession() {
    accessToken = null;
    refreshToken = null;
  }

  void reset() {
    phone = null;
    role = null;
    displayName = null;
    clearSession();
  }
}

final _mockAuth = _MockAuthStore();

/// Seeded with a ready-to-use demo account so the phone+password login
/// screen (`/account-login`) works standalone in mock mode, without first
/// requiring a full OTP-verify → set-password run in the same session to
/// populate an entry. Real accounts created via [ApiPaths.passwordSet]
/// during that session are added alongside it.
final Map<String, String> _passwordsByPhone = {
  kMockDemoPhoneNormalized: kMockDemoPassword,
};

/// Dev OTP accepted by mock verify. Shown in debug UI hint.
const kMockOtpCode = '123456';

/// Pre-seeded demo account for the phone+password login screen
/// (`/account-login`). [kMockDemoPhone] is what to type into the phone
/// field; [kMockDemoPhoneNormalized] is the E.164 form
/// `normalizeEgyptPhone` converts it to, which is what the mock keys on.
/// Both are shown in the debug UI hint.
const kMockDemoPhone = '01000000000';
const kMockDemoPhoneNormalized = '+201000000000';
const kMockDemoPassword = 'Test1234';

Map<String, dynamic> _error(int status, String code, String message) => {
  'statusCode': status,
  'data': {
    'error': {
      'code': code,
      'message': message,
      'correlation_id': 'mock-corr-auth',
    },
  },
};

Map<String, dynamic>? _body(RequestOptions options) {
  final data = options.data;
  if (data is Map<String, dynamic>) return data;
  if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return null;
}

String? _bearer(RequestOptions options) {
  final raw =
      options.headers['Authorization'] ?? options.headers['authorization'];
  if (raw is! String) return null;
  if (raw.startsWith('Bearer ')) return raw.substring(7);
  return raw;
}

Map<String, dynamic> _userPayload() => {
  'id': 'user-001',
  'phone': _mockAuth.phone ?? kMockDemoPhoneNormalized,
  'roles': [_mockAuth.role ?? 'PATIENT'],
  'active_role': _mockAuth.role ?? 'PATIENT',
  'display_name': _mockAuth.displayName,
};

/// Registers foundation + Sprint 1 auth mock responses on [interceptor].
void registerFoundationMocks(MockInterceptor interceptor) {
  interceptor.register(
    'GET',
    '/health',
    (_) => {
      'statusCode': 200,
      'data': {'status': 'ok', 'version': '0.0.1-mock'},
    },
  );

  interceptor.register('POST', ApiPaths.otpRequest, (options) {
    final body = _body(options);
    final phone = body?['phone'] as String?;
    final role = (body?['role'] as String?)?.toUpperCase() ?? 'PATIENT';
    if (phone == null || phone.isEmpty) {
      return _error(422, 'VALIDATION_ERROR', 'phone is required');
    }
    _mockAuth.phone = phone;
    _mockAuth.role = role;
    return {
      'statusCode': 200,
      'data': {'request_id': 'otp-req-001', 'expires_in': 60},
    };
  });

  interceptor.register('POST', ApiPaths.otpVerify, (options) {
    final body = _body(options);
    final phone = body?['phone'] as String?;
    final code = body?['code'] as String?;
    final role = (body?['role'] as String?)?.toUpperCase() ?? 'PATIENT';

    if (phone == null || code == null) {
      return _error(422, 'VALIDATION_ERROR', 'phone and code are required');
    }
    if (code != kMockOtpCode) {
      return _error(401, 'OTP_INVALID', 'Invalid or expired OTP');
    }

    final isProvider = role != 'PATIENT';
    final access = isProvider ? 'dev_provider_$phone' : 'dev_patient_$phone';
    final refresh = 'dev_refresh_$phone';
    _mockAuth
      ..phone = phone
      ..role = role
      ..accessToken = access
      ..refreshToken = refresh;

    return {
      'statusCode': 200,
      'data': {'access_token': access, 'refresh_token': refresh},
    };
  });

  interceptor.register('POST', ApiPaths.passwordSet, (options) {
    final body = _body(options);
    final phone = body?['phone'] as String?;
    final password = body?['password'] as String?;

    if (phone == null || password == null || password.length < 8) {
      return _error(
        422,
        'VALIDATION_ERROR',
        'Password must be at least 8 characters',
      );
    }

    _passwordsByPhone[phone] = password;

    final access = _mockAuth.accessToken ?? 'dev_patient_$phone';
    final refresh = _mockAuth.refreshToken ?? 'dev_refresh_$phone';
    _mockAuth
      ..phone = phone
      ..accessToken = access
      ..refreshToken = refresh;

    return {
      'statusCode': 200,
      'data': {'access_token': access, 'refresh_token': refresh},
    };
  });

  interceptor.register('POST', ApiPaths.passwordLogin, (options) {
    final body = _body(options);
    final phone = body?['phone'] as String?;
    final password = body?['password'] as String?;
    final role = (body?['role'] as String?)?.toUpperCase() ?? 'PATIENT';

    if (phone == null || password == null) {
      return _error(422, 'VALIDATION_ERROR', 'phone and password are required');
    }

    final storedPassword = _passwordsByPhone[phone];
    if (storedPassword == null) {
      return _error(
        404,
        'ACCOUNT_NOT_FOUND',
        'No account found for this number.',
      );
    }
    if (storedPassword != password) {
      return _error(
        401,
        'INVALID_CREDENTIALS',
        'Incorrect phone number or password.',
      );
    }

    final isProvider = role != 'PATIENT';
    final access = isProvider ? 'dev_provider_$phone' : 'dev_patient_$phone';
    final refresh = 'dev_refresh_$phone';
    _mockAuth
      ..phone = phone
      ..role = role
      ..accessToken = access
      ..refreshToken = refresh;

    return {
      'statusCode': 200,
      'data': {'access_token': access, 'refresh_token': refresh},
    };
  });

  interceptor.register('POST', ApiPaths.refresh, (options) {
    final body = _body(options);
    final refresh = body?['refresh_token'] as String?;
    if (refresh == null ||
        _mockAuth.refreshToken == null ||
        refresh != _mockAuth.refreshToken) {
      return _error(401, 'TOKEN_INVALID', 'Refresh token not recognised');
    }
    final access = _mockAuth.accessToken ?? 'dev_patient_refreshed';
    return {
      'statusCode': 200,
      'data': {'access_token': access, 'refresh_token': refresh},
    };
  });

  interceptor.register('GET', ApiPaths.me, (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(401, 'UNAUTHENTICATED', 'No token provided');
    }

    // Accept mock session tokens and legacy dev_ bypass tokens.
    final ok = token == _mockAuth.accessToken || token.startsWith('dev_');
    if (!ok) {
      return _error(401, 'TOKEN_INVALID', 'Token not recognised in mock mode');
    }

    if (token.startsWith('dev_') && _mockAuth.accessToken == null) {
      final isProvider = token.contains('provider');
      _mockAuth
        ..phone ??= kMockDemoPhoneNormalized
        ..role ??= isProvider ? 'DOCTOR' : 'PATIENT'
        ..accessToken = token;
    }

    return {'statusCode': 200, 'data': _userPayload()};
  });

  interceptor.register('PATCH', ApiPaths.me, (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(401, 'UNAUTHENTICATED', 'No token provided');
    }
    final body = _body(options);
    final name = body?['display_name'] as String?;
    if (name != null) {
      _mockAuth.displayName = name.trim().isEmpty ? null : name.trim();
    }
    return {'statusCode': 200, 'data': _userPayload()};
  });

  interceptor.register('POST', ApiPaths.logout, (options) {
    _mockAuth.clearSession();
    return {
      'statusCode': 200,
      'data': {'ok': true},
    };
  });
}

// ─── Sprint 2: provider directory mocks ───────────────────────────────────────

List<Map<String, dynamic>> get _mockDoctorsCatalog => [
  {
    'id': 'doc-sara',
    'name': 'د. سارة المنصور',
    'specialty': 'استشارية طب الأطفال - أمراض حديثي الولادة',
    'specialty_short': 'استشاري طب الأطفال',
    'specialty_key': 'pediatrics',
    'experience_years': 15,
    'rating': 4.9,
    'review_count': 120,
    'location_label': 'الرياض، حي الملقا',
    'distance_km': 2.5,
    'consultation_fee': 300,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': true,
    'clinic_name': 'مركز العناية بالطفل',
    'languages': ['العربية', 'الإنجليزية'],
    'bio':
        'طبيبة أطفال معتمدة من البورد الأمريكي، متخصصة في رعاية حديثي الولادة والأطفال. تتميز بنهج شامل يركز على الوقاية والتواصل الفعّال مع الأهل لضمان أفضل رعاية للطفل.',
    'qualifications': ['البورد الأمريكي في طب الأطفال'],
    'fellowships': ['زمالة الكلية الملكية لطب الأطفال'],
    'photo_url': null,
  },
  {
    'id': 'doc-ahmed',
    'name': 'د. أحمد خالد',
    'specialty': 'استشاري طب الأطفال',
    'specialty_short': 'استشاري طب الأطفال',
    'specialty_key': 'pediatrics',
    'experience_years': 12,
    'rating': 4.8,
    'review_count': 95,
    'location_label': 'الرياض، حي النرجس',
    'distance_km': 3.1,
    'consultation_fee': 280,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': true,
    'clinic_name': 'عيادة الأطفال المتقدمة',
    'languages': ['العربية', 'الإنجليزية'],
    'bio':
        'استشاري طب أطفال بخبرة واسعة في الأمراض المزمنة ومتابعة النمو والتطور. يقدّم رعاية مبنية على أحدث البروتوكولات الطبية.',
    'qualifications': ['البورد السعودي في طب الأطفال'],
    'fellowships': ['زمالة طب الأطفال التنفسي'],
    'photo_url': null,
  },
  {
    'id': 'doc-layla',
    'name': 'د. ليلى حسن',
    'specialty': 'استشارية طب الأطفال',
    'specialty_short': 'استشارية طب الأطفال',
    'specialty_key': 'pediatrics',
    'experience_years': 10,
    'rating': 4.7,
    'review_count': 78,
    'location_label': 'الرياض، حي الياسمين',
    'distance_km': 4.0,
    'consultation_fee': 250,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': false,
    'clinic_name': 'مستشفى الطفل التخصصي',
    'languages': ['العربية'],
    'bio':
        'طبيبة أطفال متخصصة في التغذية والسمنة لدى الأطفال، مع اهتمام خاص بالتوعية الصحية للأسرة.',
    'qualifications': ['ماجستير طب الأطفال'],
    'fellowships': ['زمالة تغذية الأطفال'],
    'photo_url': null,
  },
  {
    'id': 'doc-mahmoud',
    'name': 'د. محمود حامد',
    'specialty': 'استشاري جراحة القلب',
    'specialty_short': 'استشاري جراحة القلب',
    'specialty_key': 'cardio',
    'experience_years': 18,
    'rating': 4.9,
    'review_count': 210,
    'location_label': 'الرياض، حي العليا',
    'distance_km': 4.2,
    'consultation_fee': 500,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': true,
    'clinic_name': 'مركز القلب التخصصي',
    'languages': ['العربية', 'الإنجليزية'],
    'bio':
        'استشاري جراحة قلب وصدر بخبرة طويلة في العمليات المعقدة ومتابعة مرضى القلب المزمنين.',
    'qualifications': ['البورد الأوروبي في جراحة القلب'],
    'fellowships': ['زمالة جراحة القلب طفيفة التوغل'],
    'photo_url': null,
  },
];

List<Map<String, dynamic>> _defaultAvailableDays() => [
  {
    'id': 'day-today',
    'label': 'اليوم',
    'day_number': 12,
    'slots': [
      {'id': 's1', 'label': '09:00 ص', 'available': true},
      {'id': 's2', 'label': '09:30 ص', 'available': true},
      {'id': 's3', 'label': '10:00 ص', 'available': false},
      {'id': 's4', 'label': '10:30 ص', 'available': true},
    ],
  },
  {
    'id': 'day-tomorrow',
    'label': 'غداً',
    'day_number': 13,
    'slots': [
      {'id': 's5', 'label': '09:00 ص', 'available': true},
      {'id': 's6', 'label': '11:00 ص', 'available': true},
      {'id': 's7', 'label': '12:30 م', 'available': true},
      {'id': 's8', 'label': '04:00 م', 'available': false},
    ],
  },
  {
    'id': 'day-thu',
    'label': 'الخميس',
    'day_number': 14,
    'slots': [
      {'id': 's9', 'label': '10:00 ص', 'available': true},
      {'id': 's10', 'label': '10:30 ص', 'available': true},
      {'id': 's11', 'label': '01:00 م', 'available': true},
      {'id': 's12', 'label': '05:00 م', 'available': true},
    ],
  },
];

Map<String, dynamic> _doctorSummaryJson(Map<String, dynamic> d) => {
  'id': d['id'],
  'name': d['name'],
  'specialty': d['specialty_short'] ?? d['specialty'],
  'specialty_key': d['specialty_key'],
  'experience_years': d['experience_years'],
  'rating': d['rating'],
  'review_count': d['review_count'],
  'location_label': d['location_label'],
  'distance_km': d['distance_km'],
  'consultation_fee': d['consultation_fee'],
  'currency': d['currency'],
  'is_verified': d['is_verified'],
  'photo_url': d['photo_url'],
};

Map<String, dynamic> _doctorProfileJson(Map<String, dynamic> d) => {
  ..._doctorSummaryJson(d),
  'specialty': d['specialty'],
  'clinic_name': d['clinic_name'],
  'languages': d['languages'],
  'bio': d['bio'],
  'qualifications': d['qualifications'],
  'fellowships': d['fellowships'],
  'is_online': d['is_online'],
  // Kept for backward compatibility (used only if the real availability
  // call below has no data yet) — real availability now comes from
  // registerAvailabilityMocks / GET /v1/doctors/{id}/slots.
  'available_days': _defaultAvailableDays(),
  // One mock clinic branch per doctor. The real backend exposes this via
  // affiliations[].clinic_branch on the doctor-detail response (currently
  // raw snake_case Prisma fields, not this flat shape — see
  // med-super/docs/backend_frontend_parity_matrix.md).
  'clinic_branch_id': 'branch-${d['id']}',
  'iana_timezone': 'Africa/Cairo',
};

/// Registers the real Phase 3 availability contract's mock:
/// `GET /v1/doctors/{doctorId}/slots?clinicBranchId=&from=&to=` →
/// `{ slots: [{ slotId, startAt, endAt, status: 'OPEN' }] }` — matches
/// clinic-reservations' `GetDoctorSlotsUseCase` response shape exactly.
/// Must be registered before `registerSearchMocks`'s doctor-detail handler
/// (see the ordering note there) since `/v1/doctors/{id}/slots` also
/// contains `/v1/doctors/`.
void registerAvailabilityMocks(MockInterceptor interceptor) {
  interceptor.register('GET', '/slots', (options) {
    final clinicBranchId = options.queryParameters['clinicBranchId'] as String?;
    if (clinicBranchId == null || clinicBranchId.isEmpty) {
      return _error(400, 'VALIDATION_ERROR', 'clinicBranchId is required.');
    }

    final fromParam = options.queryParameters['from'] as String?;
    final toParam = options.queryParameters['to'] as String?;
    final nowUtc = DateTime.now().toUtc();
    final from =
        (fromParam != null ? DateTime.tryParse(fromParam) : null) ??
        DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final to =
        (toParam != null ? DateTime.tryParse(toParam) : null) ??
        from.add(const Duration(days: 14));

    // 09:00–16:30 Cairo-local (UTC+2), 30-min slots, next 14 days — a
    // deterministic mock standing in for real GenerateSlotsUseCase output.
    const cairoOffset = Duration(hours: 2);
    final slots = <Map<String, dynamic>>[];
    for (var dayOffset = 0; dayOffset < 14; dayOffset++) {
      final dayStartLocal = DateTime.utc(
        from.year,
        from.month,
        from.day,
      ).add(Duration(days: dayOffset)).add(const Duration(hours: 9));
      for (var i = 0; i < 16; i++) {
        final startLocal = dayStartLocal.add(Duration(minutes: 30 * i));
        final startUtc = startLocal.subtract(cairoOffset);
        final endUtc = startUtc.add(const Duration(minutes: 30));
        if (startUtc.isBefore(from) || !startUtc.isBefore(to)) continue;
        slots.add({
          'slotId': '$clinicBranchId-${startUtc.toIso8601String()}',
          'startAt': startUtc.toIso8601String(),
          'endAt': endUtc.toIso8601String(),
          'status': 'OPEN',
        });
      }
    }

    return {
      'statusCode': 200,
      'data': {'slots': slots},
    };
  });
}

/// Registers Sprint 2 doctor search + profile mock responses.
void registerSearchMocks(MockInterceptor interceptor) {
  // MockInterceptor matches by first-registered-wins substring containment
  // (mock_interceptor.dart:58-69), so the more specific pattern must be
  // registered first. `ApiPaths.searchDoctors` ('/v1/doctors/search') is now
  // *itself* a substring match for the detail pattern below
  // ('/v1/doctors/'), so search must register before detail — the reverse of
  // this file's previous ordering, which predates the doctors/search path fix
  // (see ApiPaths.searchDoctors and med-super/docs/backend_frontend_parity_matrix.md).
  interceptor.register('GET', ApiPaths.searchDoctors, (options) {
    final q = (options.queryParameters['q'] as String?)?.trim().toLowerCase();
    final specialty = options.queryParameters['specialty'] as String?;
    final sort = options.queryParameters['sort'] as String? ?? 'top_rated';
    // Cursor is just a stringified offset into the sorted/filtered list —
    // opaque to the client, matching 05_API_RULES.md's cursor contract.
    final cursor = int.tryParse(
      options.queryParameters['cursor'] as String? ?? '',
    );
    final limit =
        int.tryParse('${options.queryParameters['limit'] ?? ''}') ?? 20;

    var list = List<Map<String, dynamic>>.from(_mockDoctorsCatalog);

    if (specialty != null && specialty.isNotEmpty) {
      list = list
          .where((d) => d['specialty_key'] == specialty)
          .toList(growable: false);
    }

    if (q != null && q.isNotEmpty) {
      list = list
          .where((d) {
            final name = '${d['name']}'.toLowerCase();
            final spec = '${d['specialty']}'.toLowerCase();
            final clinic = '${d['clinic_name']}'.toLowerCase();
            return name.contains(q) || spec.contains(q) || clinic.contains(q);
          })
          .toList(growable: false);
    }

    list = [...list]
      ..sort((a, b) {
        switch (sort) {
          case 'nearest':
            return ((a['distance_km'] as num).compareTo(
              b['distance_km'] as num,
            ));
          case 'price_asc':
            return ((a['consultation_fee'] as num).compareTo(
              b['consultation_fee'] as num,
            ));
          default:
            final ratingCmp = (b['rating'] as num).compareTo(
              a['rating'] as num,
            );
            if (ratingCmp != 0) return ratingCmp;
            return ((b['review_count'] as num).compareTo(
              a['review_count'] as num,
            ));
        }
      });

    final totalCount = list.length;
    // Avoid num.clamp() here — it returns num, not int, and list.sublist()
    // requires int bounds.
    var start = cursor ?? 0;
    if (start < 0) start = 0;
    if (start > totalCount) start = totalCount;
    var end = start + limit;
    if (end > totalCount) end = totalCount;
    if (end < start) end = start;
    final page = list.sublist(start, end);
    final nextCursor = end < totalCount ? '$end' : null;

    return {
      'statusCode': 200,
      'data': {
        'doctors': page.map(_doctorSummaryJson).toList(),
        'total_count': totalCount,
        'next_cursor': nextCursor,
      },
    };
  });

  interceptor.register('GET', '${ApiPaths.doctors}/', (options) {
    final segments = options.path.split('/');
    final id = segments.isNotEmpty ? segments.last.split('?').first : '';
    Map<String, dynamic>? doctor;
    for (final d in _mockDoctorsCatalog) {
      if (d['id'] == id) {
        doctor = d;
        break;
      }
    }
    if (doctor == null) {
      return _error(404, 'NOT_FOUND', 'Doctor not found');
    }
    return {'statusCode': 200, 'data': _doctorProfileJson(doctor)};
  });
}

// ─── Lab Booking mocks ─────────────────────────────────────────────────────

const _labPartnersJson = [
  {
    'id': 'lab-al-borg',
    'name': 'مختبرات البرج',
    'address': 'شارع الجمهورية، مفاعية',
    'distance_km': 2.5,
    'rating': 4.8,
    'rating_count': 124,
    'starting_price': 150,
    'latitude': 24.7136,
    'longitude': 46.6753,
    'status': 'open_now',
  },
  {
    'id': 'lab-alpha',
    'name': 'مختبرات ألفا',
    'address': 'شارع طه حسين، مفاعية',
    'distance_km': 3.2,
    'rating': 4.5,
    'rating_count': 89,
    'starting_price': 165,
    'latitude': 24.7255,
    'longitude': 46.6893,
    'status': 'closed_now',
  },
  {
    'id': 'lab-smart',
    'name': 'المختبرات الذكية',
    'address': 'شارع عبد العظيم',
    'distance_km': 5.1,
    'rating': 4.9,
    'rating_count': 210,
    'starting_price': 140,
    'latitude': 24.6980,
    'longitude': 46.6612,
    'status': 'busy_now',
  },
];

/// Registers Lab Booking mock responses.
void registerLabBookingMocks(MockInterceptor interceptor) {
  interceptor.register('GET', ApiPaths.labPartners, (options) {
    final sort = options.uri.queryParameters['sort'] ?? 'nearest';
    final partners = [..._labPartnersJson];
    switch (sort) {
      case 'price_asc':
        partners.sort(
          (a, b) => (a['starting_price'] as int).compareTo(
            b['starting_price'] as int,
          ),
        );
      case 'rating_desc':
        partners.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
      default:
        partners.sort(
          (a, b) => (a['distance_km'] as double).compareTo(
            b['distance_km'] as double,
          ),
        );
    }
    return {
      'statusCode': 200,
      'data': {'lab_partners': partners},
    };
  });

  interceptor.register('POST', ApiPaths.labBookings, (options) {
    final body = _body(options) ?? const {};
    final labId = body['lab_id'] as String? ?? _labPartnersJson.first['id'];
    final lab = _labPartnersJson.firstWhere(
      (l) => l['id'] == labId,
      orElse: () => _labPartnersJson.first,
    );
    final serviceType = body['service_type'] as String? ?? 'branch_visit';
    return {
      'statusCode': 200,
      'data': {
        'booking_number': 'LAB-${88000 + lab['id'].hashCode.abs() % 999}',
        'lab_name': lab['name'],
        'lab_address': 'طريق الملك فهد، الرياض',
        // The lab hasn't reviewed the uploaded request image yet, so the
        // response is only an ETA — home-collection requests need a courier
        // dispatched first, hence the slightly longer window.
        'expected_response_hours': serviceType == 'home_collection' ? 3 : 2,
      },
    };
  });
}

// ─── Provider Registration mocks ───────────────────────────────────────────

/// Registers Doctor/Provider Registration mock responses.
void registerProviderRegistrationMocks(MockInterceptor interceptor) {
  interceptor.register('GET', ApiPaths.providerRegistrationLookups, (options) {
    return {
      'statusCode': 200,
      'data': {
        'specialties': [
          {'id': 'family-medicine', 'label': 'طب الأسرة والمجتمع'},
          {'id': 'pediatrics', 'label': 'طب الأطفال'},
          {'id': 'cardiology', 'label': 'جراحة القلب'},
          {'id': 'dermatology', 'label': 'الأمراض الجلدية'},
          {'id': 'ophthalmology', 'label': 'طب وجراحة العيون'},
        ],
        'cities': [
          {'id': 'cairo', 'label': 'القاهرة'},
          {'id': 'giza', 'label': 'الجيزة'},
          {'id': 'alexandria', 'label': 'الإسكندرية'},
          {'id': 'riyadh', 'label': 'الرياض'},
        ],
      },
    };
  });

  interceptor.register('POST', ApiPaths.providerRegistrationSubmit, (options) {
    final body = _body(options) ?? {};

    // Seed the provider-dashboard mock store from the actual registration
    // submission, so Profile/Clinic Settings/Schedule show what the doctor
    // really entered instead of an unrelated hardcoded seed. Only overwrite
    // a field when the submission actually carried a value for it.
    String? str(String key) {
      final value = body[key];
      return (value is String && value.trim().isNotEmpty) ? value : null;
    }

    _mockProviderDashboardStore.doctorAccount = {
      ..._mockProviderDashboardStore.doctorAccount,
      if (str('full_name') != null) 'name': str('full_name'),
      if (str('specialty_label') != null) 'specialty': str('specialty_label'),
      if (body['experience_years'] is int)
        'years_of_experience': body['experience_years'],
      if (str('bio') != null) 'bio': str('bio'),
      if (str('clinic_name') != null) 'hospital_name': str('clinic_name'),
      if (str('photo_data_uri') != null) 'avatar_url': str('photo_data_uri'),
    };
    _mockProviderDashboardStore.persistDoctorAccount();

    _mockProviderDashboardStore.clinicSettings = {
      ..._mockProviderDashboardStore.clinicSettings,
      if (str('clinic_name') != null) 'clinic_name': str('clinic_name'),
      if (str('clinic_address') != null) 'address': str('clinic_address'),
      if (str('phone') != null) 'phone': str('phone'),
      if (str('email') != null) 'email': str('email'),
      if (str('city_label') != null) 'city': str('city_label'),
    };
    _mockProviderDashboardStore.persistClinicSettings();

    final workingDays = body['working_days'];
    if (workingDays is List && workingDays.isNotEmpty) {
      _mockProviderDashboardStore.schedule = {'working_days': workingDays};
      _mockProviderDashboardStore.persistSchedule();
    }

    return {
      'statusCode': 200,
      'data': {
        'status': 'pending_review',
        'submitted_at': DateTime.now().toIso8601String(),
      },
    };
  });
}

// ─── Provider Dashboard mocks ────────────────────────────────────────────────

// ─── Seed data helpers ────────────────────────────────────────────────────────

List<Map<String, dynamic>> _seedAppointments() => [
  {
    'id': 'apt-1',
    'patient_name': 'سارة المحمد',
    'patient_avatar_url': null,
    'scheduled_start': DateTime.now().toLocal().toIso8601String(),
    'scheduled_end': DateTime.now()
        .toLocal()
        .add(const Duration(minutes: 30))
        .toIso8601String(),
    'location_status': 'في العيادة',
    'med_id': 'MED-1234',
    'status': 'pending',
  },
  {
    'id': 'apt-2',
    'patient_name': 'أحمد العتيبي',
    'patient_avatar_url': null,
    'scheduled_start': DateTime.now()
        .toLocal()
        .add(const Duration(hours: 1))
        .toIso8601String(),
    'scheduled_end': DateTime.now()
        .toLocal()
        .add(const Duration(hours: 1, minutes: 30))
        .toIso8601String(),
    'location_status': 'في العيادة',
    'med_id': 'MED-1235',
    'status': 'confirmed',
  },
  {
    'id': 'apt-3',
    'patient_name': 'خالد بن فهد',
    'patient_avatar_url': null,
    'scheduled_start': DateTime.now()
        .toLocal()
        .add(const Duration(hours: 2))
        .toIso8601String(),
    'scheduled_end': DateTime.now()
        .toLocal()
        .add(const Duration(hours: 2, minutes: 30))
        .toIso8601String(),
    'location_status': 'في العيادة',
    'med_id': 'MED-1236',
    'status': 'cancelled',
  },
  {
    'id': 'apt-4',
    'patient_name': 'فاطمة الشهري',
    'patient_avatar_url': null,
    'scheduled_start': DateTime.now()
        .toLocal()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
    'scheduled_end': DateTime.now()
        .toLocal()
        .subtract(const Duration(hours: 1, minutes: 30))
        .toIso8601String(),
    'location_status': 'في العيادة',
    'med_id': 'MED-1237',
    'status': 'completed',
  },
  {
    'id': 'apt-5',
    'patient_name': 'نورة العمري',
    'patient_avatar_url': null,
    'scheduled_start': DateTime.now()
        .toLocal()
        .add(const Duration(days: 1))
        .toIso8601String(),
    'scheduled_end': DateTime.now()
        .toLocal()
        .add(const Duration(days: 1, hours: 1))
        .toIso8601String(),
    'location_status': 'عيادة خارجية',
    'med_id': 'MED-1238',
    'status': 'pending',
  },
  {
    'id': 'apt-6',
    'patient_name': 'محمد الغامدي',
    'patient_avatar_url': null,
    'scheduled_start': DateTime.now()
        .toLocal()
        .add(const Duration(days: 2))
        .toIso8601String(),
    'scheduled_end': DateTime.now()
        .toLocal()
        .add(const Duration(days: 2, hours: 1))
        .toIso8601String(),
    'location_status': 'في العيادة',
    'med_id': 'MED-1239',
    'status': 'confirmed',
  },
];

List<Map<String, dynamic>> _seedPatients() => [
  {
    'id': 'pat-1',
    'name': 'سارة المحمد',
    'med_id': 'MED-1234',
    'avatar_url': null,
    'status': 'مؤكد',
    'next_appointment': DateTime.now().toLocal().toIso8601String(),
  },
  {
    'id': 'pat-2',
    'name': 'أحمد العتيبي',
    'med_id': 'MED-1235',
    'avatar_url': null,
    'status': 'مؤكد',
    'next_appointment': DateTime.now()
        .toLocal()
        .add(const Duration(hours: 1))
        .toIso8601String(),
  },
  {
    'id': 'pat-3',
    'name': 'خالد بن فهد',
    'med_id': 'MED-1236',
    'avatar_url': null,
    'status': 'ملغى',
    'next_appointment': DateTime.now()
        .toLocal()
        .add(const Duration(hours: 2))
        .toIso8601String(),
  },
  {
    'id': 'pat-4',
    'name': 'فاطمة الشهري',
    'med_id': 'MED-1237',
    'avatar_url': null,
    'status': 'مكتمل',
    'next_appointment': DateTime.now()
        .toLocal()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
  },
  {
    'id': 'pat-5',
    'name': 'نورة العمري',
    'med_id': 'MED-1238',
    'avatar_url': null,
    'status': 'مؤكد',
    'next_appointment': DateTime.now()
        .toLocal()
        .add(const Duration(days: 1))
        .toIso8601String(),
  },
  {
    'id': 'pat-6',
    'name': 'محمد الغامدي',
    'med_id': 'MED-1239',
    'avatar_url': null,
    'status': 'مؤكد',
    'next_appointment': DateTime.now()
        .toLocal()
        .add(const Duration(days: 2))
        .toIso8601String(),
  },
];

List<Map<String, dynamic>> _seedNotifications() => [
  {
    'id': 'notif-1',
    'type': 'newBookingRequest',
    'title': 'طلب حجز جديد',
    'subtitle': 'قامت سارة المحمد بحجز موعد جديد الساعة 09:00 ص',
    'created_at': DateTime.now()
        .toLocal()
        .subtract(const Duration(minutes: 45))
        .toIso8601String(),
    'is_unread': true,
    'deep_link_route': '/provider/home',
  },
  {
    'id': 'notif-2',
    'type': 'appointmentConfirmed',
    'title': 'تأكيد موعد',
    'subtitle': 'تم تأكيد موعد أحمد العتيبي الساعة 10:00 ص',
    'created_at': DateTime.now()
        .toLocal()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
    'is_unread': true,
    'deep_link_route': '/provider/home',
  },
  {
    'id': 'notif-3',
    'type': 'labReportReady',
    'title': 'تقرير مختبر جاهز',
    'subtitle': 'تقرير التحاليل الطبية الخاص بـ خالد بن فهد جاهز',
    'created_at': DateTime.now()
        .toLocal()
        .subtract(const Duration(hours: 5))
        .toIso8601String(),
    'is_unread': false,
  },
  {
    'id': 'notif-4',
    'type': 'reminder',
    'title': 'تذكير بمؤتمر',
    'subtitle': 'مؤتمر الطب الباطني يبدأ غداً الساعة 10:00 ص',
    'created_at': DateTime.now()
        .toLocal()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
    'is_unread': false,
  },
];

// ─── Hive-backed mock store ────────────────────────────────────────────────────

/// Gets the providerDashboardCache Hive box, returning null if Hive is not
/// yet initialised (e.g. in unit tests that don't call HiveService.init).
Box<String>? get _cacheBox {
  try {
    return Hive.isBoxOpen(HiveBoxNames.providerDashboardCache)
        ? Hive.box<String>(HiveBoxNames.providerDashboardCache)
        : null;
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> _loadOrSeed(
  String key,
  List<Map<String, dynamic>> Function() seed,
) {
  final box = _cacheBox;
  if (box != null) {
    final raw = box.get(key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded.cast<Map<String, dynamic>>();
        if (list.isNotEmpty) {
          return list;
        }
      } catch (_) {}
    }
  }
  final seeded = seed();
  _cacheBox?.put(key, jsonEncode(seeded));
  return seeded;
}

void _persist(String key, List<Map<String, dynamic>> list) {
  _cacheBox?.put(key, jsonEncode(list));
}

class _MockProviderDashboardStore {
  _MockProviderDashboardStore() {
    appointments = _loadOrSeed('appointments', _seedAppointments);
    patients = _loadOrSeed('patients', _seedPatients);
    notifications = _loadOrSeed('notifications', _seedNotifications);
    doctorAccount = _loadOrSeedSingle('doctor_account', _seedDoctorAccount);
    clinicSettings = _loadOrSeedSingle('clinic_settings', _seedClinicSettings);
    schedule = _loadOrSeedSingle('schedule', _seedSchedule);
  }

  late List<Map<String, dynamic>> appointments;
  late List<Map<String, dynamic>> patients;
  late List<Map<String, dynamic>> notifications;
  late Map<String, dynamic> doctorAccount;
  late Map<String, dynamic> clinicSettings;
  late Map<String, dynamic> schedule;

  static Map<String, dynamic> _seedDoctorAccount() => {
    'id': 'doc-001',
    'name': 'د. أحمد علي',
    'specialty': 'استشاري الطب الباطني',
    'hospital_name': 'مستشفى الملك فيصل التخصصي',
    'avatar_url': null,
    'years_of_experience': 12,
    'bio': 'استشاري خبرة أكثر من 12 عاماً في الطب الباطني والأمراض المزمنة.',
  };

  static Map<String, dynamic> _seedClinicSettings() => {
    'clinic_name': 'مستشفى الملك فيصل التخصصي',
    'address': 'شارع التخصصي، المعذر، الرياض',
    'phone': '+20221234567',
    'email': 'dr.ahmed@kfshrc.edu.sa',
    'city': 'الرياض',
  };

  static Map<String, dynamic> _seedSchedule() => {
    'working_days': [
      {
        'day': 'saturday',
        'is_enabled': true,
        'from': {'hour': 9, 'minute': 0},
        'to': {'hour': 17, 'minute': 0},
      },
      {
        'day': 'sunday',
        'is_enabled': true,
        'from': {'hour': 9, 'minute': 0},
        'to': {'hour': 17, 'minute': 0},
      },
      {
        'day': 'monday',
        'is_enabled': true,
        'from': {'hour': 9, 'minute': 0},
        'to': {'hour': 17, 'minute': 0},
      },
      {
        'day': 'tuesday',
        'is_enabled': true,
        'from': {'hour': 9, 'minute': 0},
        'to': {'hour': 17, 'minute': 0},
      },
      {
        'day': 'wednesday',
        'is_enabled': true,
        'from': {'hour': 9, 'minute': 0},
        'to': {'hour': 17, 'minute': 0},
      },
      {'day': 'thursday', 'is_enabled': false, 'from': null, 'to': null},
      {'day': 'friday', 'is_enabled': false, 'from': null, 'to': null},
    ],
  };

  static Map<String, dynamic> _loadOrSeedSingle(
    String key,
    Map<String, dynamic> Function() seed,
  ) {
    final box = _cacheBox;
    if (box != null) {
      final raw = box.get(key);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          if (decoded.isNotEmpty) return decoded;
        } catch (_) {}
      }
    }
    final seeded = seed();
    _cacheBox?.put(key, jsonEncode(seeded));
    return seeded;
  }

  void persistAppointments() => _persist('appointments', appointments);
  void persistPatients() => _persist('patients', patients);
  void persistNotifications() => _persist('notifications', notifications);
  void persistDoctorAccount() =>
      _cacheBox?.put('doctor_account', jsonEncode(doctorAccount));
  void persistClinicSettings() =>
      _cacheBox?.put('clinic_settings', jsonEncode(clinicSettings));
  void persistSchedule() => _cacheBox?.put('schedule', jsonEncode(schedule));
}

final _mockProviderDashboardStore = _MockProviderDashboardStore();

void registerProviderDashboardMocks(MockInterceptor interceptor) {
  interceptor.register('GET', ApiPaths.providerAppointments, (options) {
    final dateParam = options.queryParameters['date'] as String?;
    final statusParam = options.queryParameters['status'] as String?;

    if (_mockProviderDashboardStore.appointments.isEmpty) {
      _mockProviderDashboardStore.appointments = _seedAppointments();
      _mockProviderDashboardStore.persistAppointments();
    }

    var filtered = List<Map<String, dynamic>>.from(
      _mockProviderDashboardStore.appointments,
    );
    if (dateParam != null && dateParam.isNotEmpty) {
      // Parse year/month/day from the query param (YYYY-MM-DD format)
      // and compare with appointment date in local time — timezone-safe on Web.
      final parts = dateParam.split('-');
      if (parts.length == 3) {
        final qYear = int.tryParse(parts[0]);
        final qMonth = int.tryParse(parts[1]);
        final qDay = int.tryParse(parts[2]);
        filtered = filtered.where((a) {
          try {
            final dt = DateTime.parse(a['scheduled_start'] as String).toLocal();
            return dt.year == qYear && dt.month == qMonth && dt.day == qDay;
          } catch (_) {
            return false;
          }
        }).toList();
      }
    }

    if (statusParam != null && statusParam.isNotEmpty) {
      final statuses = statusParam
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .toList();
      filtered = filtered.where((a) {
        final st = (a['status'] as String).toLowerCase();
        return statuses.contains(st);
      }).toList();
    }

    return {
      'statusCode': 200,
      'data': {'items': filtered},
    };
  });

  interceptor.register('POST', ApiPaths.providerAppointments, (options) {
    final path = options.path;
    if (path.contains('/accept') || path.contains('/reject')) {
      final isAccept = path.contains('/accept');
      final parts = path.split('/');
      final actionIndex = parts.indexWhere(
        (p) => p == 'accept' || p == 'reject',
      );
      final id = actionIndex > 0 ? parts[actionIndex - 1] : '';

      final index = _mockProviderDashboardStore.appointments.indexWhere(
        (a) => a['id'] == id,
      );
      if (index == -1) {
        return _error(404, 'NOT_FOUND', 'Appointment not found');
      }

      final updated = Map<String, dynamic>.from(
        _mockProviderDashboardStore.appointments[index],
      );
      updated['status'] = isAccept ? 'confirmed' : 'cancelled';
      _mockProviderDashboardStore.appointments[index] = updated;
      // Persist mutation to Hive so it survives a cold restart.
      _mockProviderDashboardStore.persistAppointments();

      return {'statusCode': 200, 'data': updated};
    }

    final body = _body(options) ?? {};
    final newId = 'apt-${_mockProviderDashboardStore.appointments.length + 1}';
    final medId =
        'MED-${1240 + _mockProviderDashboardStore.appointments.length}';
    final newApt = {
      'id': newId,
      'patient_name': body['patient_name'] ?? 'مريض جديد',
      'patient_avatar_url': null,
      'scheduled_start':
          body['scheduled_start'] ?? DateTime.now().toIso8601String(),
      'scheduled_end':
          body['scheduled_end'] ??
          DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
      'location_status': 'في العيادة',
      'med_id': medId,
      'status': 'pending',
    };
    _mockProviderDashboardStore.appointments.add(newApt);
    _mockProviderDashboardStore.patients.add({
      'id': 'pat-${_mockProviderDashboardStore.patients.length + 1}',
      'name': newApt['patient_name'],
      'med_id': medId,
      'avatar_url': null,
      'status': 'مؤكد',
      'next_appointment': newApt['scheduled_start'],
    });
    // Persist both lists to Hive so new appointment survives restart.
    _mockProviderDashboardStore.persistAppointments();
    _mockProviderDashboardStore.persistPatients();

    return {'statusCode': 200, 'data': newApt};
  });

  interceptor.register('GET', ApiPaths.providerPatients, (options) {
    final q = (options.queryParameters['q'] as String?)?.toLowerCase();
    final filter = options.queryParameters['filter'] as String?;

    if (_mockProviderDashboardStore.patients.isEmpty) {
      _mockProviderDashboardStore.patients = _seedPatients();
      _mockProviderDashboardStore.persistPatients();
    }

    var filtered = List<Map<String, dynamic>>.from(
      _mockProviderDashboardStore.patients,
    );
    if (q != null && q.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = (p['name'] as String).toLowerCase();
        final medId = (p['med_id'] as String).toLowerCase();
        return name.contains(q) || medId.contains(q);
      }).toList();
    }

    if (filter != null && filter != 'all' && filter != 'الكل') {
      final now = DateTime.now();
      if (filter == 'today' || filter == 'اليوم') {
        filtered = filtered.where((p) {
          final next = DateTime.parse(p['next_appointment'] as String);
          return next.year == now.year &&
              next.month == now.month &&
              next.day == now.day;
        }).toList();
      } else if (filter == 'week' || filter == 'هذا الأسبوع') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        filtered = filtered.where((p) {
          final next = DateTime.parse(p['next_appointment'] as String);
          return next.isAfter(startOfWeek) && next.isBefore(endOfWeek);
        }).toList();
      }
    }

    return {
      'statusCode': 200,
      'data': {'items': filtered},
    };
  });

  interceptor.register('GET', ApiPaths.providerNotifications, (options) {
    if (_mockProviderDashboardStore.notifications.isEmpty) {
      _mockProviderDashboardStore.notifications = _seedNotifications();
      _mockProviderDashboardStore.persistNotifications();
    }

    return {
      'statusCode': 200,
      'data': {'items': _mockProviderDashboardStore.notifications},
    };
  });

  interceptor.register('POST', ApiPaths.providerNotifications, (options) {
    final path = options.path;
    if (path.contains('/read')) {
      final parts = path.split('/');
      final readIndex = parts.indexWhere((p) => p == 'read');
      final id = readIndex > 0 ? parts[readIndex - 1] : '';

      final index = _mockProviderDashboardStore.notifications.indexWhere(
        (n) => n['id'] == id,
      );
      if (index != -1) {
        final updated = Map<String, dynamic>.from(
          _mockProviderDashboardStore.notifications[index],
        );
        updated['is_unread'] = false;
        _mockProviderDashboardStore.notifications[index] = updated;
        // Persist to Hive so read-state survives a cold restart.
        _mockProviderDashboardStore.persistNotifications();
      }

      return {
        'statusCode': 200,
        'data': {'success': true},
      };
    }

    return {
      'statusCode': 200,
      'data': {'success': true},
    };
  });

  interceptor.register('GET', ApiPaths.providerMe, (options) {
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.doctorAccount,
    };
  });

  interceptor.register('PATCH', ApiPaths.providerMe, (options) {
    final body = _body(options) ?? {};
    if (body.containsKey('name')) {
      _mockProviderDashboardStore.doctorAccount['name'] = body['name'];
    }
    if (body.containsKey('specialty')) {
      _mockProviderDashboardStore.doctorAccount['specialty'] =
          body['specialty'];
    }
    if (body.containsKey('years_of_experience')) {
      _mockProviderDashboardStore.doctorAccount['years_of_experience'] =
          body['years_of_experience'];
    }
    if (body.containsKey('bio')) {
      _mockProviderDashboardStore.doctorAccount['bio'] = body['bio'];
    }
    _mockProviderDashboardStore.persistDoctorAccount();
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.doctorAccount,
    };
  });

  interceptor.register('GET', '/v1/provider/clinic-settings', (options) {
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.clinicSettings,
    };
  });

  interceptor.register('PATCH', '/v1/provider/clinic-settings', (options) {
    final body = _body(options) ?? {};
    _mockProviderDashboardStore.clinicSettings = {
      ..._mockProviderDashboardStore.clinicSettings,
      ...body,
    };
    _mockProviderDashboardStore.persistClinicSettings();
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.clinicSettings,
    };
  });

  interceptor.register('GET', '/v1/provider/schedule', (options) {
    return {'statusCode': 200, 'data': _mockProviderDashboardStore.schedule};
  });

  interceptor.register('PATCH', '/v1/provider/schedule', (options) {
    final body = _body(options) ?? {};
    if (body.containsKey('working_days')) {
      _mockProviderDashboardStore.schedule['working_days'] =
          body['working_days'];
    }
    _mockProviderDashboardStore.persistSchedule();
    return {'statusCode': 200, 'data': _mockProviderDashboardStore.schedule};
  });

  interceptor.register('POST', '/v1/provider/change-password', (options) {
    final body = _body(options) ?? {};
    final cur = body['current_password'] as String?;
    final next = body['new_password'] as String?;
    if (cur == null || cur.isEmpty || next == null || next.length < 6) {
      return _error(
        422,
        'VALIDATION_ERROR',
        'كلمة المرور غير صحيحة أو قصيرة جداً',
      );
    }
    return {
      'statusCode': 200,
      'data': {'success': true},
    };
  });

  interceptor.register('POST', '/v1/provider/avatar', (options) {
    final body = _body(options) ?? {};
    final path = body['file_path'] as String? ?? 'uploaded_avatar.jpg';
    if (path.isEmpty) {
      // Empty path is the "remove photo" signal from the edit-profile screen.
      _mockProviderDashboardStore.doctorAccount['avatar_url'] = null;
    } else if (path.startsWith('data:')) {
      // Real picked-image bytes (base64 data URI) — store as-is so the
      // actually-uploaded photo displays. A fake stock-photo URL would
      // show the same generic image regardless of what was picked, which
      // reads as "the upload didn't do anything."
      _mockProviderDashboardStore.doctorAccount['avatar_url'] = path;
    } else {
      final fakeUrl =
          'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=300&q=80#path=$path';
      _mockProviderDashboardStore.doctorAccount['avatar_url'] = fakeUrl;
    }
    _mockProviderDashboardStore.persistDoctorAccount();
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.doctorAccount,
    };
  });
}

class _MockWalletStore {
  double availableBalance = 2450.0;
  String currency = 'EGP';

  final List<Map<String, dynamic>> transactions = [
    {
      'id': 'tx-101',
      'title': 'استشارة عامة - د. أسامة علي',
      'type': 'payment',
      'amount': 350.0,
      'currency': 'EGP',
      'timestamp': '2026-08-18T14:30:00Z',
      'status': 'completed',
      'service_name': 'كشف عيادة (حجز أونلاين)',
      'doctor_name': 'د. أسامة علي',
      'fees': 15.0,
      'net_amount': 335.0,
      'reference_number': 'REF-2026818101',
    },
    {
      'id': 'tx-102',
      'title': 'شحن رصيد المحفظة',
      'type': 'deposit',
      'amount': 1000.0,
      'currency': 'EGP',
      'timestamp': '2026-08-15T10:15:00Z',
      'status': 'completed',
      'service_name': 'إيداع بطاقة ائتمان',
      'doctor_name': null,
      'fees': 0.0,
      'net_amount': 1000.0,
      'reference_number': 'REF-DEP-8892',
    },
    {
      'id': 'tx-103',
      'title': 'مستحقات استشارة تحاليل - المختبر',
      'type': 'payment',
      'amount': 600.0,
      'currency': 'EGP',
      'timestamp': '2026-08-10T09:00:00Z',
      'status': 'completed',
      'service_name': 'تحليل شامل صائم',
      'doctor_name': 'معمل النيل للتحاليل',
      'fees': 25.0,
      'net_amount': 575.0,
      'reference_number': 'REF-LAB-3312',
    },
    {
      'id': 'tx-104',
      'title': 'استرداد مبلغ استشارة ملغاة',
      'type': 'refund',
      'amount': 250.0,
      'currency': 'EGP',
      'timestamp': '2026-08-05T16:45:00Z',
      'status': 'completed',
      'service_name': 'استرداد حجز ملغى',
      'doctor_name': 'د. مروة سالم',
      'fees': 0.0,
      'net_amount': 250.0,
      'reference_number': 'REF-RFD-0091',
    },
  ];

  final Map<String, Map<String, dynamic>> refunds = {};
}

final _mockWalletStore = _MockWalletStore();

void registerWalletMocks(MockInterceptor interceptor) {
  interceptor.register('GET', '/v1/wallet/balance', (_) {
    return {
      'statusCode': 200,
      'data': {
        'available_balance': _mockWalletStore.availableBalance,
        'pending_balance': 350.0,
        'currency': _mockWalletStore.currency,
      },
    };
  });

  // Specific detail before list
  interceptor.register('GET', '/v1/wallet/transactions/', (options) {
    final pathParts = options.path.split('/');
    final id = pathParts.isNotEmpty ? pathParts.last : 'tx-101';
    final tx = _mockWalletStore.transactions.firstWhere(
      (element) => element['id'] == id,
      orElse: () => _mockWalletStore.transactions.first,
    );
    return {
      'statusCode': 200,
      'data': {
        ...tx,
        'created_at': tx['timestamp'] ?? '2026-08-18T14:30:00Z',
        'fee': tx['fees'],
      },
    };
  });

  interceptor.register('GET', '/v1/wallet/transactions', (_) {
    final mapped = _mockWalletStore.transactions.map((tx) => {
      ...tx,
      'created_at': tx['timestamp'] ?? '2026-08-18T14:30:00Z',
      'fee': tx['fees'],
    }).toList();
    return {
      'statusCode': 200,
      'data': {'items': mapped},
    };
  });

  interceptor.register('POST', '/v1/wallet/deposits', (options) {
    final body = _body(options) ?? {};
    final amount = (body['amount'] as num?)?.toDouble() ?? 100.0;
    _mockWalletStore.availableBalance += amount;
    final newTx = {
      'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'إيداع في المحفظة',
      'type': 'deposit',
      'amount': amount,
      'currency': _mockWalletStore.currency,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
      'service_name': 'إيداع إلكتروني',
      'doctor_name': null,
      'fees': 0.0,
      'net_amount': amount,
      'reference_number': 'REF-DEP-${DateTime.now().millisecondsSinceEpoch}',
      'payment_method': body['payment_method_id'] ?? 'بطاقة ائتمانية',
    };
    _mockWalletStore.transactions.insert(0, newTx);
    return {
      'statusCode': 200,
      'data': newTx,
    };
  });

  interceptor.register('POST', '/v1/wallet/transfers', (options) {
    final body = _body(options) ?? {};
    final amount = (body['amount'] as num?)?.toDouble() ?? 0.0;
    _mockWalletStore.availableBalance -= amount;
    final destinationLabel = body['destination_account_id'] == 'bank_nbe_5566'
        ? 'البنك الأهلي المصري **** 5566'
        : (body['destination_account_id'] ?? 'الحساب البنكي');
    final newTx = {
      'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'تحويل إلى الحساب البنكي',
      'type': 'withdrawal',
      'amount': amount,
      'currency': _mockWalletStore.currency,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
      'service_name': 'تحويل بنكي',
      'doctor_name': null,
      'fees': 0.0,
      'net_amount': amount,
      'reference_number': 'REF-TRF-${DateTime.now().millisecondsSinceEpoch}',
      'payment_method': destinationLabel,
    };
    _mockWalletStore.transactions.insert(0, newTx);
    return {
      'statusCode': 200,
      'data': newTx,
    };
  });

  interceptor.register('GET', '/v1/wallet/refunds/', (options) {
    final pathParts = options.path.split('/');
    final id = pathParts.isNotEmpty ? pathParts.last : 'ref-201';
    final refundObj = _mockWalletStore.refunds[id] ?? {
      'id': id.isEmpty ? 'ref-201' : id,
      'transaction_id': 'tx-101',
      'reason': 'إلغاء الموعد قبل 24 ساعة',
      'details': 'تم إلغاء الجلسة بسبب عدم تناسب الموعد',
      'status': 'under_review',
      'created_at': '2026-08-19T10:00:00Z',
      'amount': 450.0,
    };

    return {
      'statusCode': 200,
      'data': refundObj,
    };
  });

  interceptor.register('POST', '/v1/wallet/refunds', (options) {
    final body = _body(options) ?? {};
    final txId = body['transaction_id'] as String? ?? 'tx-101';
    final reason = body['reason'] as String? ?? 'سبب آخر';
    final details = body['details'] as String? ?? '';
    final refundId = 'ref-${DateTime.now().millisecondsSinceEpoch}';

    final refundObj = {
      'id': refundId,
      'transaction_id': txId,
      'reason': reason,
      'details': details,
      'status': 'submitted',
      'created_at': DateTime.now().toIso8601String(),
      'amount': 450.0,
    };

    _mockWalletStore.refunds[refundId] = refundObj;

    return {
      'statusCode': 200,
      'data': refundObj,
    };
  });
}


