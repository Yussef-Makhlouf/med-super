import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
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

/// Dev OTP accepted by mock verify. Shown in debug UI hint.
const kMockOtpCode = '123456';

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
  'phone': _mockAuth.phone ?? '+966500000000',
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
        ..phone ??= '+966500000000'
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
  'available_days': _defaultAvailableDays(),
};

/// Registers Sprint 2 doctor search + profile mock responses.
void registerSearchMocks(MockInterceptor interceptor) {
  // More specific path first so detail wins over bare /v1/doctors.
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

  interceptor.register('GET', ApiPaths.searchDoctors, (options) {
    final q = (options.queryParameters['q'] as String?)?.trim().toLowerCase();
    final specialty = options.queryParameters['specialty'] as String?;
    final sort = options.queryParameters['sort'] as String? ?? 'top_rated';

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

    return {
      'statusCode': 200,
      'data': {
        'doctors': list.map(_doctorSummaryJson).toList(),
        'total_count': list.length,
      },
    };
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
    return {
      'statusCode': 200,
      'data': {
        'status': 'pending_review',
        'submitted_at': DateTime.now().toIso8601String(),
      },
    };
  });
}
