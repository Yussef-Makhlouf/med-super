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
  String? email;
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
    email = null;
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

Map<String, dynamic> _userPayload() {
  final role = _mockAuth.role ?? 'PATIENT';
  final phone = _mockAuth.phone ?? kMockDemoPhoneNormalized;
  // Resolve display_name: for CLINIC_STAFF sessions use the assistant record's
  // name if available, otherwise fall back to the stored display_name.
  String? displayName = _mockAuth.displayName;
  if (role == 'CLINIC_STAFF' && displayName == null) {
    for (final asst in _mockAssistants.values) {
      if (asst['phone'] == phone) {
        displayName = asst['display_name'] as String?;
        break;
      }
    }
    displayName ??= kMockAssistantDisplayName;
  }
  return {
    'id': role == 'CLINIC_STAFF'
        ? 'user-asst-${phone.hashCode.abs()}'
        : 'user-001',
    'phone': phone,
    'roles': [role],
    'active_role': role,
    'display_name': displayName,
  };
}

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
    // Real backend body is {phone} only — `role` travels as a query param
    // (see auth_remote_datasource.dart) purely for this mock's role-toggle
    // UI in dev; a real controller would never see it since it only reads
    // `@Body()`.
    final role =
        options.uri.queryParameters['role']?.toUpperCase() ?? 'PATIENT';
    if (phone == null || phone.isEmpty) {
      return _error(422, 'VALIDATION_ERROR', 'رقم الهاتف مطلوب.');
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
    final code = body?['code'] as String?;
    // Real backend body is {requestId, code} only — `phone`/`role` travel as
    // query params (see auth_remote_datasource.dart), same reasoning as
    // otpRequest above.
    final phone = options.uri.queryParameters['phone'] ?? _mockAuth.phone;
    final role =
        options.uri.queryParameters['role']?.toUpperCase() ?? 'PATIENT';

    if (phone == null || code == null) {
      return _error(422, 'VALIDATION_ERROR', 'رقم الهاتف ورمز التحقق مطلوبان.');
    }
    if (code != kMockOtpCode) {
      return _error(
        401,
        'OTP_INVALID',
        'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزًا جديدًا.',
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

  interceptor.register('POST', ApiPaths.passwordSet, (options) {
    // Real endpoint takes {password} only — the caller is identified by the
    // JWT already stored from OTP-verify, not by a phone in the body — and
    // returns 204/no token body. Mirror both here.
    final body = _body(options);
    final password = body?['password'] as String?;

    if (password == null || password.length < 8) {
      return _error(
        422,
        'VALIDATION_ERROR',
        'كلمة المرور يجب ألا تقل عن 8 أحرف.',
      );
    }

    final phone = _mockAuth.phone;
    if (phone == null) {
      return _error(
        401,
        'UNAUTHENTICATED',
        'لا توجد جلسة نشِطة. سجّل الدخول مرة أخرى.',
      );
    }

    _passwordsByPhone[phone] = password;

    return {
      'statusCode': 200,
      'data': {'ok': true},
    };
  });

  interceptor.register('POST', ApiPaths.passwordLogin, (options) {
    final body = _body(options);
    final phone = body?['phone'] as String?;
    final password = body?['password'] as String?;
    // Real backend body is {phone, password} only — role isn't part of the
    // wire contract there. The datasource sends it as a query param purely
    // for this mock to honor the role-toggle UI in dev; a real backend
    // would ignore an unbound query param on a POST it only reads @Body()
    // from, so this has no effect outside mock mode.
    final role =
        options.uri.queryParameters['role']?.toUpperCase() ?? 'PATIENT';

    if (phone == null || password == null) {
      return _error(
        422,
        'VALIDATION_ERROR',
        'رقم الهاتف وكلمة المرور مطلوبان.',
      );
    }

    final storedPassword = _passwordsByPhone[phone];
    if (storedPassword == null) {
      return _error(404, 'ACCOUNT_NOT_FOUND', 'لا يوجد حساب مرتبط بهذا الرقم.');
    }
    if (storedPassword != password) {
      return _error(
        401,
        'INVALID_CREDENTIALS',
        'رقم الهاتف أو كلمة المرور غير صحيحة.',
      );
    }

    // Determine role: CLINIC_STAFF if this phone belongs to a known, active
    // assistant, otherwise honour the role toggle (DOCTOR/PATIENT). A
    // suspended assistant's password still matches (still in
    // _passwordsByPhone above), but login must be rejected — mirrors the
    // real backend's expected behaviour.
    Map<String, dynamic>? assistantRecord;
    for (final a in _mockAssistants.values) {
      if (a['phone'] == phone) {
        assistantRecord = a;
        break;
      }
    }
    if (assistantRecord != null && assistantRecord['status'] == 'SUSPENDED') {
      return _error(403, 'ACCOUNT_SUSPENDED', 'تم إيقاف حساب المساعد هذا.');
    }
    final resolvedRole = assistantRecord != null ? 'CLINIC_STAFF' : role;

    final isProvider = resolvedRole != 'PATIENT';
    final access = isProvider ? 'dev_provider_$phone' : 'dev_patient_$phone';
    final refresh = 'dev_refresh_$phone';
    _mockAuth
      ..phone = phone
      ..role = resolvedRole
      ..accessToken = access
      ..refreshToken = refresh;

    return {
      'statusCode': 200,
      'data': {'access_token': access, 'refresh_token': refresh},
    };
  });

  interceptor.register('POST', ApiPaths.passwordForgot, (options) {
    final body = _body(options);
    final phone = body?['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      return _error(422, 'VALIDATION_ERROR', 'رقم الهاتف مطلوب.');
    }
    // Remembered so the passwordReset mock below (which only gets
    // requestId/code/newPassword, no phone, matching the real endpoint)
    // knows which phone's password to update. Deliberately doesn't check
    // whether an account exists for this phone — same as a real
    // forgot-password endpoint shouldn't leak account existence via its
    // response.
    _mockAuth.phone = phone;
    return {
      'statusCode': 200,
      'data': {'request_id': 'pwd-reset-req-001', 'expires_in': 60},
    };
  });

  // Must be registered before ApiPaths.passwordReset below — its path
  // ('/v1/auth/password/reset/verify-code') contains passwordReset's path
  // ('/v1/auth/password/reset') as a substring, and MockInterceptor matches
  // first-registered-wins substring containment (mock_interceptor.dart:58-69).
  interceptor.register('POST', ApiPaths.passwordResetVerifyCode, (options) {
    final body = _body(options);
    final requestId = body?['requestId'] as String?;
    final code = body?['code'] as String?;

    if (requestId == null || requestId.isEmpty || code == null) {
      return _error(422, 'VALIDATION_ERROR', 'رمز التحقق مطلوب.');
    }
    if (code != kMockOtpCode) {
      return _error(
        401,
        'OTP_INVALID',
        'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزًا جديدًا.',
      );
    }

    // Checks-only — no side effects, no tokens, unlike passwordReset below.
    return {'statusCode': 200, 'data': <String, dynamic>{}};
  });

  interceptor.register('POST', ApiPaths.passwordReset, (options) {
    final body = _body(options);
    final requestId = body?['requestId'] as String?;
    final code = body?['code'] as String?;
    final newPassword = body?['newPassword'] as String?;

    if (requestId == null || requestId.isEmpty || code == null) {
      return _error(422, 'VALIDATION_ERROR', 'رمز التحقق مطلوب.');
    }
    if (code != kMockOtpCode) {
      return _error(
        401,
        'OTP_INVALID',
        'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزًا جديدًا.',
      );
    }
    if (newPassword == null || newPassword.length < 8) {
      return _error(
        422,
        'VALIDATION_ERROR',
        'كلمة المرور يجب ألا تقل عن 8 أحرف.',
      );
    }

    // Real endpoint has no notion of "which phone" beyond requestId — the
    // mock store only keys passwords by phone, so fall back to whichever
    // phone last went through forgot-password/OTP in this session.
    final phone = _mockAuth.phone ?? kMockDemoPhoneNormalized;
    _passwordsByPhone[phone] = newPassword;

    // No tokens in the response — matches the real backend, and keeps this
    // flow from silently logging the user in.
    return {'statusCode': 200, 'data': <String, dynamic>{}};
  });

  interceptor.register('POST', ApiPaths.refresh, (options) {
    final body = _body(options);
    // Real backend request/response fields are camelCase
    // (`RefreshTokenDto.refreshToken` / `RefreshTokenResult`), no
    // snake_case fallback — match that exactly here.
    final refresh = body?['refreshToken'] as String?;
    if (refresh == null ||
        _mockAuth.refreshToken == null ||
        refresh != _mockAuth.refreshToken) {
      return _error(
        401,
        'TOKEN_INVALID',
        'جلستك غير معروفة أو منتهية. سجّل الدخول مرة أخرى.',
      );
    }
    final access = _mockAuth.accessToken ?? 'dev_patient_refreshed';
    return {
      'statusCode': 200,
      'data': {
        'accessToken': access,
        'refreshToken': refresh,
        'expiresIn': 900,
      },
    };
  });

  interceptor.register('GET', ApiPaths.me, (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(
        401,
        'UNAUTHENTICATED',
        'يلزم تسجيل الدخول لإتمام هذا الإجراء.',
      );
    }

    // Accept mock session tokens and legacy dev_ bypass tokens.
    final ok = token == _mockAuth.accessToken || token.startsWith('dev_');
    if (!ok) {
      return _error(
        401,
        'TOKEN_INVALID',
        'جلستك غير معروفة أو منتهية. سجّل الدخول مرة أخرى.',
      );
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
      return _error(
        401,
        'UNAUTHENTICATED',
        'يلزم تسجيل الدخول لإتمام هذا الإجراء.',
      );
    }
    final body = _body(options);
    final name = body?['display_name'] as String?;
    if (name != null) {
      _mockAuth.displayName = name.trim().isEmpty ? null : name.trim();
    }
    final email = body?['email'] as String?;
    if (email != null) {
      _mockAuth.email = email.trim().isEmpty ? null : email.trim();
    }
    return {'statusCode': 200, 'data': _userPayload()};
  });

  interceptor.register('POST', ApiPaths.authDevices, (_) {
    return {
      'statusCode': 200,
      'data': {'deviceId': 'mock-device-1', 'registered': true},
    };
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
    'specialty_key': 'PEDIATRICS',
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
    'specialty_key': 'PEDIATRICS',
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
    'specialty_key': 'PEDIATRICS',
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
    'specialty_key': 'CARDIOLOGY',
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
  {
    'id': 'doc-mona',
    'name': 'د. منى فتحي',
    'specialty': 'استشارية الأمراض الجلدية والتجميل',
    'specialty_short': 'استشارية جلدية',
    'specialty_key': 'DERMATOLOGY',
    'experience_years': 11,
    'rating': 4.8,
    'review_count': 132,
    'location_label': 'القاهرة، مدينة نصر',
    'distance_km': 1.8,
    'consultation_fee': 350,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': true,
    'clinic_name': 'عيادة الجلدية والتجميل',
    'languages': ['العربية', 'الإنجليزية'],
    'bio':
        'استشارية أمراض جلدية وتناسلية، متخصصة في علاج حب الشباب والتصبغات والليزر التجميلي.',
    'qualifications': ['البورد المصري في الأمراض الجلدية'],
    'fellowships': ['زمالة الجلدية التجميلية'],
    'photo_url': null,
  },
  {
    'id': 'doc-khaled',
    'name': 'د. خالد عبد الرحمن',
    'specialty': 'استشاري طب وجراحة الأسنان',
    'specialty_short': 'استشاري أسنان',
    'specialty_key': 'DENTAL',
    'experience_years': 9,
    'rating': 4.6,
    'review_count': 64,
    'location_label': 'الإسكندرية، سموحة',
    'distance_km': 3.6,
    'consultation_fee': 220,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': false,
    'clinic_name': 'مركز ابتسامة لطب الأسنان',
    'languages': ['العربية'],
    'bio': 'استشاري طب وجراحة الفم والأسنان، متخصص في زراعة وتقويم الأسنان.',
    'qualifications': ['ماجستير طب وجراحة الفم والأسنان'],
    'fellowships': ['زمالة زراعة الأسنان'],
    'photo_url': null,
  },
  {
    'id': 'doc-nourhan',
    'name': 'د. نورهان سامي',
    'specialty': 'استشارية طب وجراحة العيون',
    'specialty_short': 'استشارية عيون',
    'specialty_key': 'OPHTHALMOLOGY',
    'experience_years': 13,
    'rating': 4.7,
    'review_count': 88,
    'location_label': 'الجيزة، الدقي',
    'distance_km': 5.1,
    'consultation_fee': 300,
    'currency': 'EGP',
    'is_verified': true,
    'is_online': true,
    'clinic_name': 'مركز الرؤية لطب العيون',
    'languages': ['العربية', 'الإنجليزية'],
    'bio': 'استشارية طب وجراحة العيون، متخصصة في جراحات الليزك والمياه البيضاء.',
    'qualifications': ['البورد المصري في طب وجراحة العيون'],
    'fellowships': ['زمالة جراحات الشبكية'],
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

/// Matches the real `GET /v1/doctors/{id}` response shape exactly
/// (`GetDoctorUseCase` — a flat camelCase object, `DoctorProfileDto.fromJson`
/// no longer dispatches on structure since both shapes are now identical).
/// `languages`/`fellowships`/`isOnline` are deliberately absent — no
/// backend column backs any of them, so this mock doesn't fabricate values
/// the real backend could never actually send.
Map<String, dynamic> _doctorProfileJson(Map<String, dynamic> d) => {
  'id': d['id'],
  'name': d['name'],
  'specialty': d['specialty'],
  'specialtyKey': d['specialty_key'],
  'experienceYears': d['experience_years'],
  'rating': d['rating'],
  'reviewCount': d['review_count'],
  'clinicName': d['clinic_name'],
  'bio': d['bio'],
  'qualifications': d['qualifications'],
  'consultationFee': d['consultation_fee'],
  'currency': d['currency'],
  'isVerified': d['is_verified'],
  'photoUrl': d['photo_url'],
  // Kept for backward compatibility (used only if the real availability
  // call below has no data yet) — real availability now comes from
  // registerAvailabilityMocks / GET /v1/doctors/{id}/slots.
  'available_days': _defaultAvailableDays(),
  'clinicBranchId': 'branch-${d['id']}',
  'ianaTimezone': 'Africa/Cairo',
  'affiliationId': 'affiliation-${d['id']}',
  'affiliations': [
    {
      'affiliationId': 'affiliation-${d['id']}',
      'clinicBranchId': 'branch-${d['id']}',
      'clinicName': d['clinic_name'],
      'addressLine1': d['clinic_name'],
      'city': '',
      'consultationFee': '${d['consultation_fee']}',
      'currency': d['currency'],
      'ianaTimezone': 'Africa/Cairo',
    },
  ],
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
      return _error(400, 'VALIDATION_ERROR', 'اختر فرع العيادة.');
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

/// In-memory mock state for the Phase 4 booking loop — module-level so it
/// survives across calls within one app session (there is no persistence
/// layer to fake against here, mirroring how `_mockDoctorsCatalog` etc. are
/// plain in-memory lists elsewhere in this file).
final Map<String, _MockHold> _mockHolds = {};
final Map<String, _MockAppointment> _mockAppointments = {};
int _mockAppointmentSeq = 0;

class _MockHold {
  _MockHold({
    required this.slotId,
    required this.doctorClinicAffiliationId,
    required this.expiresAt,
    this.rescheduledFromAppointmentId,
  });
  final String slotId;
  final String doctorClinicAffiliationId;
  /// Mutable so the Fawry mock can extend it the way
  /// `InitiateOnlineAppointmentPaymentUseCase` does (15 min, File 12 Part 50.1).
  DateTime expiresAt;
  final String? rescheduledFromAppointmentId;
}

class _MockAppointment {
  _MockAppointment({
    required this.slotId,
    required this.doctorClinicAffiliationId,
    required this.startAt,
    required this.endAt,
    this.rescheduledFromAppointmentId,
  });
  final String slotId;
  final String doctorClinicAffiliationId;
  final DateTime startAt;
  final DateTime endAt;
  String status = 'CONFIRMED';
  String? cancelledReason;
  String? rescheduledFromAppointmentId;
}

/// Registers real Phase 4 (Appointments) mocks — File 10 §2.3 / File 12 Part
/// 35's exact response shapes, so switching `BASE_URL` to a real backend
/// later needs no client-side change (same principle as
/// `registerAvailabilityMocks`). Simplified vs. the real backend in one
/// deliberate way: holds never actually expire here (no background sweep to
/// fake), so `HOLD_EXPIRED` only ever occurs for an unknown/already-used
/// `holdId` — the concurrency guarantee itself is proven server-side
/// (`appointment-hold-concurrency.integration.spec.ts`), not re-tested here.
void registerAppointmentMocks(MockInterceptor interceptor) {
  interceptor.register('POST', '/appointments/hold', (options) {
    final body = _body(options) ?? {};
    final slotId = body['slotId'] as String?;
    final affiliationId = body['doctorClinicAffiliationId'] as String?;
    final patientId = body['patientId'] as String?;
    if (slotId == null || affiliationId == null || patientId == null) {
      return _error(
        400,
        'VALIDATION_ERROR',
        'بيانات الحجز غير مكتملة. أعد المحاولة.',
      );
    }

    final holdId = 'mock-hold-${DateTime.now().microsecondsSinceEpoch}';
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));
    _mockHolds[holdId] = _MockHold(
      slotId: slotId,
      doctorClinicAffiliationId: affiliationId,
      expiresAt: expiresAt,
    );

    return {
      'statusCode': 201,
      'data': {
        'holdId': holdId,
        'slotId': slotId,
        'expiresAt': expiresAt.toIso8601String(),
        'status': 'HELD',
      },
    };
  });

  // Registered before `/confirm` only for readability — neither pattern is
  // a substring of the other, so order is not load-bearing here.
  //
  // `POST /v1/appointments/{holdId}/payments` (File 12 Part 50.1): unlike
  // confirm, this does NOT create an appointment. It extends the hold and
  // hands back a Fawry reference; the real backend only books the slot once
  // the gateway webhook arrives, which nothing in mock mode simulates — so
  // a mock Fawry booking correctly never shows up in "My Appointments".
  interceptor.register('POST', '/payments', (options) {
    final segments = options.path.split('/');
    final holdId = segments.length >= 2 ? segments[segments.length - 2] : '';
    final hold = _mockHolds[holdId];
    if (hold == null) {
      return _error(
        410,
        'HOLD_EXPIRED',
        'انتهت مدة حجز هذا الموعد. اختر موعدًا آخر وابدأ من جديد.',
      );
    }

    final body = _body(options) ?? {};
    final method = body['method'] as String? ?? 'FAWRY';
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 15));
    hold.expiresAt = expiresAt;

    return {
      'statusCode': 200,
      'data': {
        'paymentIntentId': 'mock-pi-${DateTime.now().microsecondsSinceEpoch}',
        'method': method,
        'referenceCode':
            '${DateTime.now().millisecondsSinceEpoch}'.padLeft(11, '0'),
        'expiresAt': expiresAt.toIso8601String(),
      },
    };
  });

  interceptor.register('POST', '/confirm', (options) {
    final segments = options.path.split('/');
    final holdId = segments.length >= 2 ? segments[segments.length - 2] : '';
    final hold = _mockHolds[holdId];
    if (hold == null) {
      return _error(
        410,
        'HOLD_EXPIRED',
        'انتهت مدة حجز هذا الموعد. اختر موعدًا آخر وابدأ من جديد.',
      );
    }

    // Wallet payment debits before anything else, and an insufficient
    // balance leaves the hold untouched — mirroring the real use-case,
    // where the debit is the first write and its failure rolls the whole
    // confirm transaction back (File 12 Part 50.4).
    final paymentMethod =
        (_body(options) ?? {})['paymentMethod'] as String? ?? 'PAY_AT_CLINIC';
    if (paymentMethod == 'INTERNAL_WALLET') {
      if (_mockWalletStore.availableBalance < _kMockConsultFee) {
        return _error(
          422,
          'INSUFFICIENT_WALLET_BALANCE',
          'رصيد المحفظة غير كافٍ لإتمام هذه العملية.',
        );
      }
      _mockWalletStore.debitForAppointment(_kMockConsultFee);
    }

    _mockHolds.remove(holdId);
    final now = DateTime.now().toUtc();
    _mockAppointmentSeq++;
    final appointmentId = 'mock-appointment-$_mockAppointmentSeq';
    _mockAppointments[appointmentId] = _MockAppointment(
      slotId: hold.slotId,
      doctorClinicAffiliationId: hold.doctorClinicAffiliationId,
      startAt: now,
      endAt: now.add(const Duration(minutes: 20)),
      rescheduledFromAppointmentId: hold.rescheduledFromAppointmentId,
    );

    return {
      'statusCode': 200,
      'data': {'appointmentId': appointmentId, 'status': 'CONFIRMED'},
    };
  });

  interceptor.register('POST', '/cancel', (options) {
    final segments = options.path.split('/');
    final appointmentId = segments.length >= 2
        ? segments[segments.length - 2]
        : '';
    final appointment = _mockAppointments[appointmentId];
    if (appointment == null) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد غير موجود.');
    }
    if (appointment.status != 'CONFIRMED') {
      return _error(
        422,
        'APPOINTMENT_NOT_CANCELLABLE',
        'لا يمكن إلغاء هذا الموعد إلا وهو مؤكّد.',
      );
    }

    final body = _body(options) ?? {};
    appointment.status = 'CANCELLED';
    appointment.cancelledReason =
        body['reason'] as String? ?? 'PATIENT_REQUEST';

    return {
      'statusCode': 200,
      'data': {'status': 'CANCELLED', 'refundAmount': 0, 'feeApplied': 0},
    };
  });

  interceptor.register('POST', '/reschedule', (options) {
    final segments = options.path.split('/');
    final appointmentId = segments.length >= 2
        ? segments[segments.length - 2]
        : '';
    final appointment = _mockAppointments[appointmentId];
    if (appointment == null) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد غير موجود.');
    }
    if (appointment.status != 'CONFIRMED') {
      return _error(
        422,
        'APPOINTMENT_NOT_RESCHEDULABLE',
        'لا يمكن تغيير هذا الموعد إلا وهو مؤكّد.',
      );
    }

    final body = _body(options) ?? {};
    final newSlotId = body['newSlotId'] as String?;
    if (newSlotId == null) {
      return _error(400, 'VALIDATION_ERROR', 'اختر الموعد الجديد.');
    }

    appointment.status = 'RESCHEDULED';
    final holdId = 'mock-hold-${DateTime.now().microsecondsSinceEpoch}';
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));
    _mockHolds[holdId] = _MockHold(
      slotId: newSlotId,
      doctorClinicAffiliationId: appointment.doctorClinicAffiliationId,
      expiresAt: expiresAt,
      rescheduledFromAppointmentId: appointmentId,
    );

    return {
      'statusCode': 200,
      'data': {
        'holdId': holdId,
        'slotId': newSlotId,
        'expiresAt': expiresAt.toIso8601String(),
        'status': 'HELD',
        'previousAppointmentId': appointmentId,
      },
    };
  });

  // Must be registered after '/cancel'/'/reschedule'/'/confirm' — those are
  // all substring-contained within '/appointments/{id}' too, and
  // first-registered-wins (see registerSearchMocks' ordering note).
  interceptor.register('GET', ApiPaths.appointments, (options) {
    final segments = options.path.split('/');
    final last = segments.isNotEmpty ? segments.last.split('?').first : '';
    final isDetail = last.isNotEmpty && _mockAppointments.containsKey(last);

    if (isDetail) {
      return {
        'statusCode': 200,
        'data': _mockAppointmentJson(last, _mockAppointments[last]!),
      };
    }

    final items = _mockAppointments.entries
        .map((e) => _mockAppointmentJson(e.key, e.value))
        .toList();
    return {
      'statusCode': 200,
      'data': {'items': items, 'nextCursor': null},
    };
  });
}

Map<String, dynamic> _mockAppointmentJson(String id, _MockAppointment a) {
  // Mock-only convention: `affiliation-{doctorId}` (see
  // `_mockOnlyDoctorIdFromAffiliation`'s doc comment in
  // `reschedule_screen.dart`) — lets this mock stand in a doctor/clinic
  // name without a real affiliation table to join against.
  const prefix = 'affiliation-';
  final doctorId = a.doctorClinicAffiliationId.startsWith(prefix)
      ? a.doctorClinicAffiliationId.substring(prefix.length)
      : a.doctorClinicAffiliationId;
  final doctor = _mockDoctorsCatalog.firstWhere(
    (d) => d['id'] == doctorId,
    orElse: () => _mockDoctorsCatalog.first,
  );
  return {
    'appointmentId': id,
    'status': a.status,
    'slotId': a.slotId,
    'startAt': a.startAt.toIso8601String(),
    'endAt': a.endAt.toIso8601String(),
    'doctorClinicAffiliationId': a.doctorClinicAffiliationId,
    'cancelledReason': a.cancelledReason,
    'rescheduledFromAppointmentId': a.rescheduledFromAppointmentId,
    'doctorId': doctorId,
    'doctorName': doctor['name'],
    'clinicBranchId': 'branch-$doctorId',
    'clinicName': doctor['clinic_name'],
    'clinicAddressLine1': '12 Demo St',
    'clinicCity': 'Cairo',
    'clinicPhone': '+20221230000',
  };
}

/// Registers `GET`/`PATCH /v1/doctors/me`. Must run BEFORE
/// `registerSearchMocks` below — that function's `GET '${ApiPaths.doctors}/'`
/// doctor-detail-by-id handler would otherwise swallow `/v1/doctors/me` too
/// (first-registered-wins substring containment), the same reasoning the
/// real backend's route-order comment on `DoctorsController.getMe` gives.
void registerDoctorMeMocks(MockInterceptor interceptor) {
  interceptor.register('GET', ApiPaths.doctorMe, (options) {
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.doctorAccount,
    };
  });

  interceptor.register('PATCH', ApiPaths.doctorMe, (options) {
    final body = _body(options) ?? {};
    if (body.containsKey('bio')) {
      _mockProviderDashboardStore.doctorAccount['bio'] = body['bio'];
    }
    if (body.containsKey('degree')) {
      _mockProviderDashboardStore.doctorAccount['degree'] = body['degree'];
    }
    if (body.containsKey('experienceYears')) {
      _mockProviderDashboardStore.doctorAccount['experienceYears'] =
          body['experienceYears'];
    }
    _mockProviderDashboardStore.persistDoctorAccount();
    return {
      'statusCode': 200,
      'data': _mockProviderDashboardStore.doctorAccount,
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
    final sort = options.queryParameters['sort'] as String? ?? 'rating:desc';
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
          case 'distance:asc':
            return ((a['distance_km'] as num).compareTo(
              b['distance_km'] as num,
            ));
          case 'price:asc':
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
      return _error(404, 'NOT_FOUND', 'الطبيب غير موجود.');
    }
    return {'statusCode': 200, 'data': _doctorProfileJson(doctor)};
  });
}

// ─── Clinic / Clinic Branch mocks ──────────────────────────────────────────
//
// Path prefixes are `/v1/clinics` and `/v1/clinic-branches` respectively —
// neither is a substring of the other (`/v1/clinics/` vs
// `/v1/clinic-branches/`), so registration order between the two groups is
// not load-bearing under MockInterceptor's first-registered-wins
// substring-containment rule.

/// Registers `GET /v1/clinic-branches/:branchId` — the clinic branch detail
/// screen. Mirrors clinic-reservations' `GetClinicBranchUseCase` response
/// shape: the raw Prisma `ClinicBranch` row plus its `address`/`clinic`
/// relations, so this payload is snake_case, matching every real field name.
void registerClinicBranchMocks(MockInterceptor interceptor) {
  interceptor.register('GET', '${ApiPaths.clinicBranches}/', (options) {
    final segments = options.path.split('/');
    final branchId = segments.isNotEmpty ? segments.last.split('?').first : '';

    // Mirrors the doctor-detail mock's `clinic_branch_id: 'branch-${d['id']}'`
    // convention (see `_doctorProfileJson`) so a branch id reached via a
    // doctor's `clinicBranchId` resolves to a matching clinic name here.
    final doctorId = branchId.startsWith('branch-')
        ? branchId.substring('branch-'.length)
        : null;
    Map<String, dynamic>? doctor;
    if (doctorId != null) {
      for (final d in _mockDoctorsCatalog) {
        if (d['id'] == doctorId) {
          doctor = d;
          break;
        }
      }
    }

    final clinicName =
        doctor?['clinic_name'] as String? ?? 'Nile Medical Center';
    final clinicId = 'clinic-${doctorId ?? branchId}';

    return {
      'statusCode': 200,
      'data': {
        'id': branchId,
        'clinic_id': clinicId,
        'address_id': 'address-$branchId',
        'phone': '+201000000000',
        'iana_timezone': 'Africa/Cairo',
        'status': 'VERIFIED',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'version': 1,
        'address': {
          'id': 'address-$branchId',
          'line1': 'Building 12, Tahrir Street',
          'city': 'Cairo',
          'region_code': 'CAI',
          'country_code': 'EG',
          'geo_lat': 30.0444,
          'geo_lng': 31.2357,
        },
        'clinic': {
          'id': clinicId,
          'legal_name': '$clinicName LLC',
          'brand_name': clinicName,
          'tax_id': null,
          'region_code': 'CAI',
          'status': 'VERIFIED',
        },
      },
    };
  });
}

// ─── Pharmacy Branch mocks ──────────────────────────────────────────────────
//
// A branch is the unit browsed/detailed end to end — there is no parent
// "pharmacy chain" mock/screen to keep in sync with this catalog.

// Ids match the real backend's fixed-UUID demo pharmacy branches
// (`db/seed.ts`'s `demoPharmacies[].branchId`) and pharmacy_booking's own
// `mockPharmacies` list — so a card tap resolves the same way whether the
// app is pointed at MockInterceptor or the real backend.
const _mockPharmacyBranchesCatalog = [
  {
    'id': '00000000-0000-0000-0000-000000000111',
    'pharmacy_id': '00000000-0000-0000-0000-000000000101',
    'phone': '+20221230001',
    'iana_timezone': 'Africa/Cairo',
    'delivery_capable': true,
    'status': 'VERIFIED',
    'pharmacy': {
      'id': '00000000-0000-0000-0000-000000000101',
      'legal_name': 'Nile Pharma LLC (Seed)',
      'brand_name': 'Nile Pharmacy',
      'status': 'VERIFIED',
    },
    'address': {
      'id': '00000000-0000-0000-0000-000000000121',
      'line1': '5 Zamalek Ave',
      'city': 'Cairo',
      'region_code': 'EG',
      'country_code': 'EG',
      'geo_lat': 30.044420,
      'geo_lng': 31.235712,
    },
  },
  {
    'id': '00000000-0000-0000-0000-000000000112',
    'pharmacy_id': '00000000-0000-0000-0000-000000000102',
    'phone': '+20221230002',
    'iana_timezone': 'Africa/Cairo',
    'delivery_capable': true,
    'status': 'VERIFIED',
    'pharmacy': {
      'id': '00000000-0000-0000-0000-000000000102',
      'legal_name': 'Al Ezaby Pharmaceuticals Co. (Seed)',
      'brand_name': 'Al Ezaby Pharmacy',
      'status': 'VERIFIED',
    },
    'address': {
      'id': '00000000-0000-0000-0000-000000000122',
      'line1': '18 King Fahd Rd',
      'city': 'Cairo',
      'region_code': 'EG',
      'country_code': 'EG',
      'geo_lat': 30.05,
      'geo_lng': 31.23,
    },
  },
  {
    'id': '00000000-0000-0000-0000-000000000113',
    'pharmacy_id': '00000000-0000-0000-0000-000000000103',
    'phone': '+20221230003',
    'iana_timezone': 'Africa/Cairo',
    'delivery_capable': false,
    'status': 'VERIFIED',
    'pharmacy': {
      'id': '00000000-0000-0000-0000-000000000103',
      'legal_name': 'Community Pharma Group (Seed)',
      'brand_name': 'Community Pharmacy',
      'status': 'VERIFIED',
    },
    'address': {
      'id': '00000000-0000-0000-0000-000000000123',
      'line1': '40 Al Olaya St',
      'city': 'Cairo',
      'region_code': 'EG',
      'country_code': 'EG',
      'geo_lat': 30.06,
      'geo_lng': 31.22,
    },
  },
];

/// Registers `GET /v1/pharmacy-branches/search` (`clinic-reservations` File
/// 12 Part 37) — must be registered **before** [registerPharmacyBranchMocks]
/// (same ordering requirement `registerSearchMocks`/`registerAvailabilityMocks`
/// already document): `/v1/pharmacy-branches/search` is a substring match
/// under the detail handler's `/v1/pharmacy-branches/` pattern too, and
/// `MockInterceptor` is first-registered-wins.
///
/// Response shape is the dedicated camelCase `SearchPharmacyBranchItem`
/// contract (not the branch-detail endpoint's raw Prisma passthrough) —
/// built from the same `_mockPharmacyBranchesCatalog` rows so ids/names stay
/// in sync with the detail mock and the real seeded demo branches.
void registerPharmacyBranchSearchMocks(MockInterceptor interceptor) {
  interceptor.register('GET', '${ApiPaths.pharmacyBranches}/search', (options) {
    final q = (options.queryParameters['q'] as String?)?.toLowerCase();
    final hasLocation =
        options.queryParameters['lat'] != null &&
        options.queryParameters['lng'] != null;

    final items = _mockPharmacyBranchesCatalog
        .where((b) {
          if (q == null || q.isEmpty) return true;
          final brandName =
              (b['pharmacy'] as Map<String, dynamic>)['brand_name'] as String?;
          return brandName?.toLowerCase().contains(q) ?? false;
        })
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final b = entry.value;
          final pharmacy = b['pharmacy'] as Map<String, dynamic>;
          final address = b['address'] as Map<String, dynamic>;
          return {
            'branchId': b['id'],
            'pharmacyId': pharmacy['id'],
            'brandName': pharmacy['brand_name'],
            'legalName': pharmacy['legal_name'],
            'phone': b['phone'],
            'ianaTimezone': b['iana_timezone'],
            'deliveryCapable': b['delivery_capable'],
            'address': {
              'line1': address['line1'],
              'city': address['city'],
              'regionCode': address['region_code'],
              'countryCode': address['country_code'],
              'geoLat': address['geo_lat'],
              'geoLng': address['geo_lng'],
            },
            // Fixed mock increments, not a real geo calculation — only
            // meaningful to demonstrate nearest-first ordering in mock mode.
            'distanceKm': hasLocation ? (entry.key + 1) * 1.2 : null,
          };
        })
        .toList();

    return {
      'statusCode': 200,
      'data': {'items': items, 'nextCursor': null},
    };
  });
}

/// Registers the Pharmacy Branch detail mock — `GET /v1/pharmacy-branches/{branchId}`.
void registerPharmacyBranchMocks(MockInterceptor interceptor) {
  interceptor.register('GET', '${ApiPaths.pharmacyBranches}/', (options) {
    final segments = options.path.split('/');
    final id = segments.isNotEmpty ? segments.last.split('?').first : '';
    Map<String, dynamic>? branch;
    for (final b in _mockPharmacyBranchesCatalog) {
      if (b['id'] == id) {
        branch = b;
        break;
      }
    }
    if (branch == null) {
      return _error(404, 'NOT_FOUND', 'فرع الصيدلية غير موجود.');
    }
    return {'statusCode': 200, 'data': branch};
  });
}

// ─── Prescriptions mocks (Phase 6) ──────────────────────────────────────────

/// Registers `POST /v1/prescriptions/upload`, mirroring the real backend's
/// `UploadPrescriptionUseCase` response shape (`{prescriptionId, status}`) —
/// always reports `QUALITY_CHECK_PASSED` since the mock has no real
/// quality-checker to fail against.
void registerPrescriptionMocks(MockInterceptor interceptor) {
  interceptor.register('POST', '${ApiPaths.prescriptions}/upload', (options) {
    return {
      'statusCode': 200,
      'data': {
        'prescriptionId': '11111111-1111-4111-8111-111111111111',
        'status': 'QUALITY_CHECK_PASSED',
      },
    };
  });
}

// ─── Pharmacy Fulfillment mocks (Phase 7) ───────────────────────────────────

/// Registers `POST /v1/pharmacy-orders`, mirroring the real backend's
/// `CreatePharmacyOrderResult` response shape. Broadcasts to the chosen
/// branch alone when `pharmacyBranchId` is sent, matching File 12 Part 44.
const _mockPharmacyOrderId = '22222222-2222-4222-8222-222222222222';

/// Mirrors `PharmacyOrderDetail` (`clinic-reservations`
/// `pharmacy-order-detail.mapper.ts`) — quoted/`ACCEPTED` so the detail
/// screen can show pharmacy pricing and fulfillment status in mock mode.
const _mockPharmacyOrderDetailJson = {
  'id': _mockPharmacyOrderId,
  'status': 'ACCEPTED',
  'fulfillmentType': 'DELIVERY',
  'createdAt': '2026-08-31T10:00:00.000Z',
  'updatedAt': '2026-08-31T10:05:00.000Z',
  'patient': {
    'id': '11111111-1111-4111-8111-111111111111',
    'firstName': 'Sara',
    'lastName': 'Ali',
    'phoneMasked': '***1234',
  },
  'prescription': {
    'id': '11111111-1111-4111-8111-111111111111',
    'source': 'PATIENT_UPLOADED',
    'status': 'QUALITY_CHECK_PASSED',
    'expiresAt': null,
    'doctorName': null,
    'images': [],
  },
  'quote': {
    'totalPrice': '225.00',
    'currency': 'EGP',
    'estimatedReadyMinutes': null,
    'note': 'All items available',
    'quotedAt': '2026-08-31T10:05:00.000Z',
  },
  'patientNote': 'Take with food',
  'staffNote': 'All items available',
  'rejection': null,
};

void registerPharmacyOrderMocks(MockInterceptor interceptor) {
  // Receipt confirmation is more specific than the bare create route below.
  interceptor.register('POST', '/confirm-receipt', (options) {
    return {
      'statusCode': 200,
      'data': {
        'pharmacyOrderId': _mockPharmacyOrderId,
        'status': 'FULFILLED',
      },
    };
  });

  interceptor.register('POST', ApiPaths.pharmacyOrders, (options) {
    final body = _body(options) ?? const {};
    final branchId = body['pharmacyBranchId'] as String?;
    return {
      'statusCode': 200,
      'data': {
        'pharmacyOrderId': _mockPharmacyOrderId,
        'status': 'RECEIVED',
        'broadcastedBranchIds': [?branchId],
      },
    };
  });

  // Detail — registered before the bare list pattern below.
  interceptor.register('GET', '${ApiPaths.pharmacyOrders}/', (options) {
    return {'statusCode': 200, 'data': _mockPharmacyOrderDetailJson};
  });

  interceptor.register('GET', ApiPaths.pharmacyOrders, (options) {
    return {
      'statusCode': 200,
      'data': {
        'orders': [_mockPharmacyOrderDetailJson],
        'nextCursor': null,
      },
    };
  });
}

// ─── Specialties mocks ──────────────────────────────────────────────────────

const _mockSpecialtiesJson = <Map<String, dynamic>>[
  {
    'code': 'CARDIOLOGY',
    'name_en': 'Cardiology',
    'name_ar': 'أمراض القلب',
    'parent_code': null,
    'version': 1,
  },
  {
    'code': 'PEDIATRICS',
    'name_en': 'Pediatrics',
    'name_ar': 'طب الأطفال',
    'parent_code': null,
    'version': 1,
  },
  {
    'code': 'DERMATOLOGY',
    'name_en': 'Dermatology',
    'name_ar': 'الأمراض الجلدية',
    'parent_code': null,
    'version': 1,
  },
  {
    'code': 'DENTAL',
    'name_en': 'Dental',
    'name_ar': 'طب الأسنان',
    'parent_code': null,
    'version': 1,
  },
  {
    'code': 'OPHTHALMOLOGY',
    'name_en': 'Ophthalmology',
    'name_ar': 'طب العيون',
    'parent_code': null,
    'version': 1,
  },
];

/// Registers `GET /v1/specialties`. MockInterceptor casts a handler's
/// `data` field to `Map<String, dynamic>` (mock_interceptor.dart:22), so a
/// raw JSON array can't be returned directly the way the real backend does
/// — it's wrapped under a `specialties` key instead.
/// `SpecialtiesRemoteDatasource` already accepts both shapes (raw array for
/// the real backend, `{specialties: [...]}` for this mock).
void registerSpecialtiesMocks(MockInterceptor interceptor) {
  interceptor.register('GET', ApiPaths.specialties, (options) {
    return {
      'statusCode': 200,
      'data': {'specialties': _mockSpecialtiesJson},
    };
  });
}

// ─── Lab Booking mocks ─────────────────────────────────────────────────────
//
// Rebuilt 2026-09-05 to mirror the real backend contract exactly (see
// `lab_booking/STATUS.md`): `GET /v1/lab-branches/search`
// (`SearchLabBranchItem`, new — nothing let a patient discover a branch
// before this pass) and `POST`/`GET /v1/lab-orders` (`LabOrderDetail`). The
// old `/v1/lab-partners`/`/v1/lab-bookings` invented endpoints and their
// rating/price/status fields are gone — none of that exists on the real
// backend.

const _mockLabBranchesCatalog = [
  {
    'id': 'aaaaaaaa-0000-4000-8000-000000000001',
    'brandName': 'مختبرات نايل',
    'homeCollectionCapable': true,
    'address': {
      'line1': '9 شارع قصر النيل',
      'city': 'القاهرة',
      'regionCode': 'EG',
      'countryCode': 'EG',
      'geoLat': 30.044420,
      'geoLng': 31.235712,
    },
  },
  {
    'id': 'aaaaaaaa-0000-4000-8000-000000000002',
    'brandName': 'مختبرات البرج',
    'homeCollectionCapable': true,
    'address': {
      'line1': 'كورنيش النيل، المعادي',
      'city': 'القاهرة',
      'regionCode': 'EG',
      'countryCode': 'EG',
      'geoLat': 29.9602,
      'geoLng': 31.2569,
    },
  },
  {
    'id': 'aaaaaaaa-0000-4000-8000-000000000003',
    'brandName': 'مختبرات ألفا',
    'homeCollectionCapable': false,
    'address': {
      'line1': 'شارع الميرغني، مصر الجديدة',
      'city': 'القاهرة',
      'regionCode': 'EG',
      'countryCode': 'EG',
      'geoLat': 30.0808,
      'geoLng': 31.3231,
    },
  },
];

const _mockLabOrderId = '44444444-4444-4444-8444-444444444444';

/// Mirrors `LabOrderDetail` (`clinic-reservations`
/// `lab-order-detail.mapper.ts`) — `QUOTED` with a real quote so the
/// tracking screen has something to show in mock mode.
const _mockLabOrderDetailJson = {
  'id': _mockLabOrderId,
  'status': 'QUOTED',
  'collectionType': 'VISIT',
  'createdAt': '2026-09-05T08:00:00.000Z',
  'updatedAt': '2026-09-05T09:30:00.000Z',
  'branchId': 'aaaaaaaa-0000-4000-8000-000000000001',
  'items': [
    {
      'id': '55555555-5555-4555-8555-555555555555',
      'catalogCode': 'CBC',
      'displayName': 'صورة دم كاملة',
      'unitPrice': '120.00',
      'resultState': 'PENDING',
    },
  ],
  'quote': {
    'totalPrice': '120.00',
    'currency': 'EGP',
    'appointmentAt': '2026-09-06T10:00:00.000Z',
    'prepInstructions': 'الصيام 8 ساعات قبل السحب',
    'quotedAt': '2026-09-05T09:30:00.000Z',
  },
  'bookingCode': null,
  'rejection': null,
  'recollectionRequired': false,
};

/// Registers Lab Booking mock responses.
void registerLabBookingMocks(MockInterceptor interceptor) {
  // Search — registered before the (nonexistent, in this mock) detail
  // pattern is ever added, same ordering discipline
  // `registerPharmacyBranchSearchMocks` documents.
  interceptor.register('GET', '${ApiPaths.labBranches}/search', (options) {
    final q = (options.queryParameters['q'] as String?)?.toLowerCase();
    final hasLocation =
        options.queryParameters['lat'] != null &&
        options.queryParameters['lng'] != null;

    final items = _mockLabBranchesCatalog
        .where((b) {
          if (q == null || q.isEmpty) return true;
          return (b['brandName'] as String).toLowerCase().contains(q);
        })
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final b = entry.value;
          final address = b['address'] as Map<String, dynamic>;
          return {
            'branchId': b['id'],
            'brandName': b['brandName'],
            'homeCollectionCapable': b['homeCollectionCapable'],
            'address': address,
            // Fixed mock increments, not a real geo calculation — only
            // meaningful to demonstrate nearest-first ordering in mock mode.
            'distanceKm': hasLocation ? (entry.key + 1) * 1.5 : null,
          };
        })
        .toList();

    return {
      'statusCode': 200,
      'data': {'items': items, 'nextCursor': null},
    };
  });

  // Create — registered before the bare list pattern below, same
  // first-registered-wins ordering `registerPharmacyOrderMocks` documents.
  interceptor.register('POST', ApiPaths.labOrders, (options) {
    return {
      'statusCode': 200,
      'data': {'labOrderId': _mockLabOrderId, 'status': 'REQUESTED'},
    };
  });

  interceptor.register('GET', '${ApiPaths.labOrders}/', (options) {
    return {'statusCode': 200, 'data': _mockLabOrderDetailJson};
  });

  interceptor.register('GET', ApiPaths.labOrders, (options) {
    return {
      'statusCode': 200,
      'data': {
        'orders': [_mockLabOrderDetailJson],
        'nextCursor': null,
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
      if (str('full_name') != null) 'displayName': str('full_name'),
      if (str('specialty_label') != null) 'specialty': str('specialty_label'),
      if (body['experience_years'] is int)
        'experienceYears': body['experience_years'],
      if (str('bio') != null) 'bio': str('bio'),
      if (str('photo_data_uri') != null) 'photoUrl': str('photo_data_uri'),
    };
    _mockProviderDashboardStore.persistDoctorAccount();

    // Self-registration creates the doctor's first clinic/branch, so the
    // dashboard's clinics list is seeded from what was actually submitted.
    // `email` is deliberately dropped: no clinic or branch table has an email
    // column, and the real `GET /v1/doctors/me/clinics` never returns one.
    if (_mockProviderDashboardStore.clinics.isNotEmpty) {
      final first = Map<String, dynamic>.from(
        _mockProviderDashboardStore.clinics.first,
      );
      final address = Map<String, dynamic>.from(
        first['address'] as Map<String, dynamic>,
      );
      if (str('clinic_name') != null) first['clinicName'] = str('clinic_name');
      if (str('phone') != null) first['phone'] = str('phone');
      if (str('clinic_address') != null) {
        address['line1'] = str('clinic_address');
      }
      if (str('city_label') != null) address['city'] = str('city_label');
      first['address'] = address;
      _mockProviderDashboardStore.clinics[0] = first;
      _mockProviderDashboardStore.persistClinics();
    }

    // `working_days` is already sent in the real `CreateScheduleTemplateDto`
    // shape (`{weekday, startTime, endTime, slotDurationMinutes,
    // bufferMinutes}`), and the backend persists it as real ScheduleTemplate
    // rows — so it materializes here as templates, not as a separate blob.
    final workingDays = body['working_days'];
    if (workingDays is List && workingDays.isNotEmpty) {
      final clinic = _mockProviderDashboardStore.clinics.isNotEmpty
          ? _mockProviderDashboardStore.clinics.first
          : const <String, dynamic>{};
      final now = DateTime.now().toUtc().toIso8601String();
      _mockProviderDashboardStore.scheduleTemplates = [
        for (var i = 0; i < workingDays.length; i++)
          if (workingDays[i] is Map<String, dynamic>)
            {
              'id': 'tmpl-reg-$i',
              'doctorClinicAffiliationId': clinic['affiliationId'] ?? 'aff-001',
              'clinicBranchId': clinic['clinicBranchId'] ?? 'branch-001',
              'clinicId': clinic['clinicId'] ?? 'clinic-001',
              'clinicName': clinic['clinicName'] ?? '',
              'ianaTimezone': clinic['ianaTimezone'] ?? 'Africa/Cairo',
              ...(workingDays[i] as Map<String, dynamic>),
              'version': 1,
              'createdAt': now,
              'updatedAt': now,
            },
      ];
      _mockProviderDashboardStore.persistScheduleTemplates();
    }

    return {
      'statusCode': 200,
      'data': {
        'doctorId': 'mock-doctor-id',
        'status': 'pending_review',
        'submitted_at': DateTime.now().toIso8601String(),
      },
    };
  });

  // Mirrors the real `POST /v1/provider-verification-documents` — accepts
  // the multipart upload without inspecting it (mock mode has no real
  // storage), returning just enough shape for the datasource to not throw.
  interceptor.register('POST', ApiPaths.providerVerificationDocuments, (
    options,
  ) {
    return {
      'statusCode': 201,
      'data': {
        'id': 'mock-verification-document-id',
        'status': 'PENDING_REVIEW',
      },
    };
  });
}

// ─── Provider Dashboard mocks ────────────────────────────────────────────────

// ─── Seed data helpers ────────────────────────────────────────────────────────

/// Doctor Dashboard mock state, in the **real** contract shapes
/// (`clinic-reservations` File 12 Part 49) — camelCase, `{items, nextCursor}`
/// envelopes, `CONFIRMED`/`CANCELLED`/`RESCHEDULED`/`COMPLETED` statuses.
///
/// The previous seeds modelled an invented `/v1/provider/*` API (snake_case,
/// `med_id`, `location_status`, a `pending` status that never existed) and so
/// could not catch a single real contract mismatch. These can.
const String _mockAffiliationId = 'aff-001';
const String _mockBranchId = 'branch-001';
const String _mockClinicId = 'clinic-001';
const String _mockAffiliationId2 = 'aff-002';
const String _mockBranchId2 = 'branch-002';
const String _mockClinicId2 = 'clinic-002';

Map<String, dynamic> _mockDoctorAppointment({
  required String id,
  required String patientName,
  required String patientId,
  required DateTime startUtc,
  required String status,
  String affiliationId = _mockAffiliationId,
  String branchId = _mockBranchId,
  String clinicId = _mockClinicId,
  String clinicName = 'عيادة النيل التخصصية',
  String? cancelledReason,
  String visitStatus = 'WAITING',
}) => {
  'appointmentId': id,
  'status': status,
  'visitStatus': visitStatus,
  'version': 1,
  'slotId': '$branchId-${startUtc.toIso8601String()}',
  'startAt': startUtc.toIso8601String(),
  'endAt': startUtc.add(const Duration(minutes: 30)).toIso8601String(),
  'doctorClinicAffiliationId': affiliationId,
  'clinicId': clinicId,
  'clinicName': clinicName,
  'clinicBranchId': branchId,
  'clinicBranchPhone': '+20221230000',
  'clinicAddressLine1': '12 شارع التحرير',
  'clinicCity': 'القاهرة',
  'ianaTimezone': 'Africa/Cairo',
  'patientId': patientId,
  'patientName': patientName,
  'patientPhone': '+201001112223',
  'cancelledReason': cancelledReason,
  'rescheduledFromAppointmentId': null,
  'createdAt': startUtc.subtract(const Duration(days: 3)).toIso8601String(),
};

List<Map<String, dynamic>> _seedDoctorAppointments() {
  // Anchored to the LOCAL calendar day, not UTC: the app queries "today" as
  // a local-midnight-to-local-midnight window (see `provider_home_screen.dart`
  // `dateOnly`), which is a different UTC instant whenever the device's UTC
  // offset means local midnight has already passed but the UTC date hasn't
  // rolled over yet (or vice versa). Anchoring the seed to `now.toUtc()`'s
  // calendar date caused apt-1/apt-2 to silently fall outside "today"'s query
  // window under exactly that condition.
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  return [
    _mockDoctorAppointment(
      id: 'apt-1',
      patientName: 'أحمد محمود',
      patientId: 'pat-1',
      startUtc: today.add(const Duration(hours: 7)),
      status: 'CONFIRMED',
    ),
    _mockDoctorAppointment(
      id: 'apt-2',
      patientName: 'سارة علي',
      patientId: 'pat-2',
      startUtc: today.add(const Duration(hours: 8, minutes: 30)),
      status: 'CONFIRMED',
    ),
    _mockDoctorAppointment(
      id: 'apt-3',
      patientName: 'منى حسن',
      patientId: 'pat-3',
      startUtc: today.add(const Duration(hours: 6)),
      status: 'COMPLETED',
      visitStatus: 'LEFT',
    ),
    _mockDoctorAppointment(
      id: 'apt-4',
      patientName: 'فاطمة الشهري',
      patientId: 'pat-4',
      startUtc: today.subtract(const Duration(hours: 2)),
      status: 'CANCELLED',
      cancelledReason: 'PATIENT_REQUEST',
    ),
    _mockDoctorAppointment(
      id: 'apt-5',
      patientName: 'نورة العمري',
      patientId: 'pat-5',
      startUtc: today.add(const Duration(days: 1, hours: 7)),
      status: 'CONFIRMED',
      affiliationId: _mockAffiliationId2,
      branchId: _mockBranchId2,
      clinicId: _mockClinicId2,
      clinicName: 'مركز الإسكندرية الطبي',
    ),
    _mockDoctorAppointment(
      id: 'apt-6',
      patientName: 'محمد الغامدي',
      patientId: 'pat-6',
      startUtc: today.add(const Duration(days: 2, hours: 7)),
      status: 'CONFIRMED',
    ),
  ];
}

List<Map<String, dynamic>> _seedDoctorClinics() => [
  {
    'affiliationId': _mockAffiliationId,
    'affiliationStatus': 'ACTIVE',
    'consultFee': '250.00',
    'currency': 'EGP',
    'clinicId': _mockClinicId,
    'clinicName': 'عيادة النيل التخصصية',
    'clinicStatus': 'VERIFIED',
    'clinicBranchId': _mockBranchId,
    'branchStatus': 'VERIFIED',
    'phone': '+20221230000',
    'ianaTimezone': 'Africa/Cairo',
    'address': {
      'line1': '12 شارع التحرير',
      'city': 'القاهرة',
      'regionCode': 'CAI',
      'countryCode': 'EG',
    },
  },
  {
    'affiliationId': _mockAffiliationId2,
    'affiliationStatus': 'ACTIVE',
    'consultFee': '300.00',
    'currency': 'EGP',
    'clinicId': _mockClinicId2,
    'clinicName': 'مركز الإسكندرية الطبي',
    'clinicStatus': 'VERIFIED',
    'clinicBranchId': _mockBranchId2,
    'branchStatus': 'PENDING',
    'phone': '+20321230000',
    'ianaTimezone': 'Africa/Cairo',
    'address': {
      'line1': '5 الكورنيش',
      'city': 'الإسكندرية',
      'regionCode': 'ALX',
      'countryCode': 'EG',
    },
  },
];

List<Map<String, dynamic>> _seedDoctorScheduleTemplates() {
  Map<String, dynamic> template({
    required String id,
    required int weekday,
    String start = '09:00',
    String end = '17:00',
    String affiliationId = _mockAffiliationId,
    String branchId = _mockBranchId,
    String clinicId = _mockClinicId,
    String clinicName = 'عيادة النيل التخصصية',
  }) => {
    'id': id,
    'doctorClinicAffiliationId': affiliationId,
    'clinicBranchId': branchId,
    'clinicId': clinicId,
    'clinicName': clinicName,
    'ianaTimezone': 'Africa/Cairo',
    'weekday': weekday,
    'startTime': start,
    'endTime': end,
    'slotDurationMinutes': 30,
    'bufferMinutes': 0,
    'version': 1,
    'createdAt': DateTime.utc(2026, 8, 1).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 8, 1).toIso8601String(),
  };

  return [
    template(id: 'tmpl-1', weekday: 6),
    template(id: 'tmpl-2', weekday: 7),
    template(id: 'tmpl-3', weekday: 1),
    template(
      id: 'tmpl-4',
      weekday: 3,
      start: '10:00',
      end: '14:00',
      affiliationId: _mockAffiliationId2,
      branchId: _mockBranchId2,
      clinicId: _mockClinicId2,
      clinicName: 'مركز الإسكندرية الطبي',
    ),
  ];
}

List<Map<String, dynamic>> _seedBackendNotifications() {
  String ts(Duration ago) =>
      DateTime.now().toUtc().subtract(ago).toIso8601String();

  Map<String, dynamic> row({
    required String id,
    required String templateCode,
    required String title,
    required String body,
    required Duration ago,
    Map<String, dynamic>? data,
    String? readAt,
  }) {
    final created = ts(ago);
    return {
      'id': id,
      'user_id': 'user-001',
      'tier': 'TRANSACTIONAL',
      'channel': 'PUSH',
      'template_code': templateCode,
      'title': title,
      'body': body,
      'data': data,
      'status': 'SENT',
      'attempts': 0,
      'sent_at': created,
      'read_at': readAt,
      'created_at': created,
      'updated_at': created,
      'version': 1,
    };
  }

  return [
    row(
      id: 'notif-1',
      templateCode: 'AppointmentConfirmed',
      title: 'تم تأكيد الموعد',
      body: 'تم تأكيد موعدك بنجاح. يمكنك مراجعة التفاصيل داخل التطبيق.',
      ago: const Duration(minutes: 45),
      data: {'appointmentId': 'apt-mock-1'},
    ),
    row(
      id: 'notif-2',
      templateCode: 'PrescriptionUploaded',
      title: 'تم استلام الروشتة',
      body: 'تم استلام روشتتك وهي الآن قيد المراجعة.',
      ago: const Duration(hours: 2),
      data: {'prescriptionId': 'rx-mock-1'},
    ),
    row(
      id: 'notif-3',
      templateCode: 'LabResultReady',
      title: 'النتيجة جاهزة',
      body: 'نتيجة التحليل جاهزة. يمكنك الاطلاع عليها الآن داخل التطبيق.',
      ago: const Duration(hours: 5),
      data: {'labOrderId': 'lab-order-mock-1'},
      readAt: ts(const Duration(hours: 4)),
    ),
    row(
      id: 'notif-4',
      templateCode: 'AppointmentCancelled',
      title: 'تم إلغاء الموعد',
      body: 'تم إلغاء موعدك. راجع التطبيق لإعادة الحجز إذا رغبت.',
      ago: const Duration(days: 1),
      data: {'appointmentId': 'apt-mock-2'},
      readAt: ts(const Duration(hours: 20)),
    ),
  ];
}

class _MockNotificationStore {
  _MockNotificationStore() {
    rows = _loadOrSeed('backend_notifications', _seedBackendNotifications);
  }

  late List<Map<String, dynamic>> rows;

  void persist() => _persist('backend_notifications', rows);
}

final _mockNotificationStore = _MockNotificationStore();

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
    appointments = _loadOrSeed('doctor_appointments', _seedDoctorAppointments);
    doctorAccount = _loadOrSeedSingle('doctor_account', _seedDoctorAccount);
    clinics = _loadOrSeed('doctor_clinics', _seedDoctorClinics);
    scheduleTemplates = _loadOrSeed(
      'doctor_schedule_templates',
      _seedDoctorScheduleTemplates,
    );
  }

  /// Doctor-facing appointment rows, in the real `DoctorAppointmentSummary`
  /// shape. The Hive key is new (`doctor_appointments`) on purpose: the old
  /// `appointments` key holds rows in the abandoned invented shape, and
  /// reusing it would deserialize those into the new parser on first launch.
  late List<Map<String, dynamic>> appointments;
  late Map<String, dynamic> doctorAccount;
  late List<Map<String, dynamic>> clinics;
  late List<Map<String, dynamic>> scheduleTemplates;

  /// Mirrors `GET /v1/doctors/me`'s real shape (`MyDoctorProfile`,
  /// camelCase) — `hospital_name` was dropped 2026-08-31 along with the
  /// entity field it backed, since the real endpoint has no clinic-branch
  /// join to source it from.
  static Map<String, dynamic> _seedDoctorAccount() => {
    'id': 'doc-001',
    'displayName': 'د. أحمد علي',
    'email': 'dr.ahmed@example.com',
    'phone': '+201001234567',
    'specialty': 'استشاري الطب الباطني',
    'licenseNumber': 'LIC-2026-001',
    'photoUrl': null,
    'degree': 'MBBCh, MD',
    'experienceYears': 12,
    'bio': 'استشاري خبرة أكثر من 12 عاماً في الطب الباطني والأمراض المزمنة.',
    'isVerified': true,
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

  void persistAppointments() => _persist('doctor_appointments', appointments);
  void persistDoctorAccount() =>
      _cacheBox?.put('doctor_account', jsonEncode(doctorAccount));
  void persistClinics() => _persist('doctor_clinics', clinics);
  void persistScheduleTemplates() =>
      _persist('doctor_schedule_templates', scheduleTemplates);
}

final _mockProviderDashboardStore = _MockProviderDashboardStore();

/// Doctor Dashboard mocks, on the **real** doctor-scoped routes
/// (`clinic-reservations` File 12 Part 49).
///
/// MUST be registered before `registerDoctorMeMocks` (see `dio_client.dart`):
/// `MockInterceptor` matches by first-registered-wins substring containment,
/// and `/v1/doctors/me` is a prefix of every path here. Within this function
/// the same rule applies — `.../clinics/branches` and `.../clinics/affiliations`
/// are registered before `.../clinics`, and the appointment sub-actions before
/// the list.
///
void registerProviderDashboardMocks(MockInterceptor interceptor) {
  // --- Clinics and branches -------------------------------------------------

  interceptor.register('PATCH', ApiPaths.doctorMeClinicBranches, (options) {
    final branchId = options.path.split('/').last;
    final index = _mockProviderDashboardStore.clinics.indexWhere(
      (c) => c['clinicBranchId'] == branchId,
    );
    // The real backend answers 404 (never 403) for a branch the caller is not
    // affiliated with — existence hiding. The mock does the same, so the
    // client's own error handling is exercised against the right status.
    if (index == -1) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'فرع العيادة غير موجود.');
    }

    final body = _body(options) ?? {};
    final updated = Map<String, dynamic>.from(
      _mockProviderDashboardStore.clinics[index],
    );
    if (body.containsKey('phone')) updated['phone'] = body['phone'];
    if (body.containsKey('ianaTimezone')) {
      updated['ianaTimezone'] = body['ianaTimezone'];
    }
    if (body['address'] is Map) {
      final address = Map<String, dynamic>.from(
        updated['address'] as Map<String, dynamic>,
      );
      final patch = body['address'] as Map<String, dynamic>;
      if (patch.containsKey('line1')) address['line1'] = patch['line1'];
      if (patch.containsKey('city')) address['city'] = patch['city'];
      updated['address'] = address;
    }
    _mockProviderDashboardStore.clinics[index] = updated;
    _mockProviderDashboardStore.persistClinics();
    return {'statusCode': 200, 'data': updated};
  });

  interceptor.register('PATCH', ApiPaths.doctorMeAffiliations, (options) {
    final affiliationId = options.path.split('/').last;
    final index = _mockProviderDashboardStore.clinics.indexWhere(
      (c) => c['affiliationId'] == affiliationId,
    );
    if (index == -1) {
      return _error(
        404,
        'RESOURCE_NOT_FOUND',
        'ارتباط الطبيب بالفرع غير موجود.',
      );
    }

    final body = _body(options) ?? {};
    final status = body['status'] as String?;
    if (status != 'ACTIVE' && status != 'PAUSED') {
      return _error(
        400,
        'VALIDATION_ERROR',
        'الحالة يجب أن تكون «نشِط» أو «موقوف».',
      );
    }

    final updated = Map<String, dynamic>.from(
      _mockProviderDashboardStore.clinics[index],
    )..['affiliationStatus'] = status;
    // The doctor owns the commercial consult fee; the Admin only verifies
    // license/documents (File 12 Part 49.4) — mirrors the real endpoint.
    if (body['consultFee'] != null) {
      final fee = body['consultFee'];
      updated['consultFee'] = fee is num
          ? fee.toStringAsFixed(2)
          : fee.toString();
    }
    _mockProviderDashboardStore.clinics[index] = updated;
    _mockProviderDashboardStore.persistClinics();
    return {'statusCode': 200, 'data': updated};
  });

  interceptor.register('DELETE', ApiPaths.doctorMeClinicBranches, (options) {
    final branchId = options.path.split('/').last;
    final index = _mockProviderDashboardStore.clinics.indexWhere(
      (c) => c['clinicBranchId'] == branchId,
    );
    if (index == -1) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'فرع العيادة غير موجود.');
    }

    final affiliationId =
        _mockProviderDashboardStore.clinics[index]['affiliationId'];
    final hasBookings = _mockProviderDashboardStore.appointments.any(
      (a) =>
          a['doctorClinicAffiliationId'] == affiliationId &&
          (a['status'] == 'HELD' || a['status'] == 'CONFIRMED'),
    );
    if (hasBookings) {
      return _error(
        409,
        'BRANCH_HAS_BOOKINGS',
        'لا يمكن حذف الفرع لأنه يحتوي على مواعيد محجوزة.',
      );
    }

    _mockProviderDashboardStore.clinics.removeAt(index);
    _mockProviderDashboardStore.persistClinics();
    return {'statusCode': 204, 'data': null};
  });

  interceptor.register('POST', '${ApiPaths.doctorMeClinics}/', (options) {
    // Path shape: /v1/doctors/me/clinics/{clinicId}/branches — only matches
    // POST requests here since GET .../clinics (no trailing segment) is
    // registered separately below with an exact, non-prefixed path.
    final segments = options.path.split('/');
    final clinicId = segments[segments.length - 2];
    final owned = _mockProviderDashboardStore.clinics.firstWhere(
      (c) => c['clinicId'] == clinicId,
      orElse: () => const {},
    );
    if (owned.isEmpty) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'العيادة غير موجودة.');
    }

    final body = _body(options) ?? {};
    final address = (body['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final now = DateTime.now().millisecondsSinceEpoch;
    final created = {
      'affiliationId': 'aff-mock-$now',
      'affiliationStatus': 'ACTIVE',
      'consultFee': (body['consultFee'] is num)
          ? (body['consultFee'] as num).toStringAsFixed(2)
          : '0.00',
      'currency': body['currency'] ?? 'EGP',
      'clinicId': clinicId,
      'clinicName': owned['clinicName'],
      'clinicStatus': owned['clinicStatus'],
      'clinicBranchId': 'branch-mock-$now',
      'branchStatus': 'PENDING',
      'phone': body['phone'] ?? '',
      'ianaTimezone': body['ianaTimezone'] ?? 'Africa/Cairo',
      'address': {
        'line1': address['line1'] ?? '',
        'city': address['city'] ?? '',
        'regionCode': address['regionCode'] ?? owned['address']['regionCode'],
        'countryCode':
            address['countryCode'] ?? owned['address']['countryCode'],
      },
    };
    _mockProviderDashboardStore.clinics.add(created);
    _mockProviderDashboardStore.persistClinics();
    return {'statusCode': 201, 'data': created};
  });

  interceptor.register('GET', ApiPaths.doctorMeClinics, (options) {
    return {
      'statusCode': 200,
      'data': {'items': _mockProviderDashboardStore.clinics},
    };
  });

  // --- Schedule templates ---------------------------------------------------

  interceptor.register('POST', ApiPaths.doctorMeScheduleTemplates, (options) {
    final body = _body(options) ?? {};
    final affiliationId = body['doctorClinicAffiliationId'] as String?;
    final clinic = _mockProviderDashboardStore.clinics.firstWhere(
      (c) => c['affiliationId'] == affiliationId,
      orElse: () => const {},
    );
    if (clinic.isEmpty) {
      return _error(
        404,
        'RESOURCE_NOT_FOUND',
        'ارتباط الطبيب بالفرع غير موجود.',
      );
    }

    final start = body['startTime'] as String? ?? '09:00';
    final end = body['endTime'] as String? ?? '17:00';
    if (end.compareTo(start) <= 0) {
      return _error(
        422,
        'INVALID_SCHEDULE_WINDOW',
        'وقت النهاية يجب أن يكون بعد وقت البداية.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final created = {
      'id':
          'tmpl-${_mockProviderDashboardStore.scheduleTemplates.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
      'doctorClinicAffiliationId': affiliationId,
      'clinicBranchId': clinic['clinicBranchId'],
      'clinicId': clinic['clinicId'],
      'clinicName': clinic['clinicName'],
      'ianaTimezone': clinic['ianaTimezone'],
      'weekday': body['weekday'] ?? 1,
      'startTime': start,
      'endTime': end,
      'slotDurationMinutes': body['slotDurationMinutes'] ?? 30,
      'bufferMinutes': body['bufferMinutes'] ?? 0,
      'version': 1,
      'createdAt': now,
      'updatedAt': now,
    };
    _mockProviderDashboardStore.scheduleTemplates.add(created);
    _mockProviderDashboardStore.persistScheduleTemplates();
    return {'statusCode': 201, 'data': created};
  });

  interceptor.register('PATCH', ApiPaths.doctorMeScheduleTemplates, (options) {
    final templateId = options.path.split('/').last;
    final index = _mockProviderDashboardStore.scheduleTemplates.indexWhere(
      (t) => t['id'] == templateId,
    );
    if (index == -1) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'قالب المواعيد غير موجود.');
    }

    final current = Map<String, dynamic>.from(
      _mockProviderDashboardStore.scheduleTemplates[index],
    );
    final body = _body(options) ?? {};

    // Real optimistic locking: a stale `version` loses with a 409 rather than
    // silently overwriting whatever landed first (File 12 Part 49.6).
    final expectedVersion = body['version'];
    if (expectedVersion is int && expectedVersion != current['version']) {
      return _error(
        409,
        'OPTIMISTIC_LOCK_CONFLICT',
        'تم تعديل جدول المواعيد بعد فتحك للصفحة. حدّث الصفحة ثم أعد المحاولة.',
      );
    }

    final start =
        (body['startTime'] as String?) ?? current['startTime'] as String;
    final end = (body['endTime'] as String?) ?? current['endTime'] as String;
    if (end.compareTo(start) <= 0) {
      return _error(
        422,
        'INVALID_SCHEDULE_WINDOW',
        'وقت النهاية يجب أن يكون بعد وقت البداية.',
      );
    }

    for (final key in [
      'weekday',
      'startTime',
      'endTime',
      'slotDurationMinutes',
      'bufferMinutes',
    ]) {
      if (body.containsKey(key)) current[key] = body[key];
    }
    current['version'] = (current['version'] as int) + 1;
    current['updatedAt'] = DateTime.now().toUtc().toIso8601String();

    _mockProviderDashboardStore.scheduleTemplates[index] = current;
    _mockProviderDashboardStore.persistScheduleTemplates();
    return {'statusCode': 200, 'data': current};
  });

  interceptor.register('DELETE', ApiPaths.doctorMeScheduleTemplates, (options) {
    final templateId = options.path.split('/').last;
    final index = _mockProviderDashboardStore.scheduleTemplates.indexWhere(
      (t) => t['id'] == templateId,
    );
    if (index == -1) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'قالب المواعيد غير موجود.');
    }

    final version = options.queryParameters['version'];
    final expected = version is int ? version : int.tryParse('$version');
    final current = _mockProviderDashboardStore.scheduleTemplates[index];
    if (expected != null && expected != current['version']) {
      return _error(
        409,
        'OPTIMISTIC_LOCK_CONFLICT',
        'تم تعديل جدول المواعيد بعد فتحك للصفحة. حدّث الصفحة ثم أعد المحاولة.',
      );
    }

    _mockProviderDashboardStore.scheduleTemplates.removeAt(index);
    _mockProviderDashboardStore.persistScheduleTemplates();
    // Deliberately does NOT touch any generated slot — mirrors Part 33.8.
    return {'statusCode': 204, 'data': null};
  });

  interceptor.register('GET', ApiPaths.doctorMeScheduleTemplates, (options) {
    final affiliationId = options.queryParameters['affiliationId'] as String?;
    var items = List<Map<String, dynamic>>.from(
      _mockProviderDashboardStore.scheduleTemplates,
    );
    if (affiliationId != null) {
      final owned = _mockProviderDashboardStore.clinics.any(
        (c) => c['affiliationId'] == affiliationId,
      );
      if (!owned) {
        return _error(
          404,
          'RESOURCE_NOT_FOUND',
          'ارتباط الطبيب بالفرع غير موجود.',
        );
      }
      items = items
          .where((t) => t['doctorClinicAffiliationId'] == affiliationId)
          .toList();
    }
    return {
      'statusCode': 200,
      'data': {'items': items},
    };
  });

  // --- Appointments ---------------------------------------------------------

  interceptor.register('POST', ApiPaths.doctorMeAppointments, (options) {
    final path = options.path;
    final parts = path.split('/');

    // Walk-in booking: POST .../appointments/branch/{clinicBranchId}/create.
    final branchIndex = parts.indexWhere((p) => p == 'branch');
    if (branchIndex >= 0 &&
        branchIndex + 2 < parts.length &&
        parts[branchIndex + 2] == 'create') {
      final clinicBranchId = parts[branchIndex + 1];
      final body = _body(options) ?? {};
      final slotId = body['slotId'] as String?;
      final patientId = body['patientId'] as String?;
      final patientPhone = body['patientPhone'] as String?;
      final patientName = body['patientName'] as String?;

      if (slotId == null || slotId.isEmpty) {
        return _error(400, 'VALIDATION_ERROR', 'اختر الموعد.');
      }
      if ((patientId == null) == (patientPhone == null)) {
        return _error(
          400,
          'VALIDATION_ERROR',
          'حدِّد المريض برقم المريض أو برقم الهاتف، وليس كلاهما أو لا شيء منهما.',
        );
      }
      if (!slotId.startsWith('$clinicBranchId-')) {
        return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد المتاح غير موجود.');
      }

      final start =
          DateTime.tryParse(
            slotId.substring(clinicBranchId.length + 1),
          )?.toUtc() ??
          DateTime.now().toUtc();
      final resolvedPatientId = patientId ?? 'pat-${patientPhone ?? ''}';
      final appointmentId = 'apt-${DateTime.now().millisecondsSinceEpoch}';

      final appointment = <String, dynamic>{
        'appointmentId': appointmentId,
        'status': 'CONFIRMED',
        'visitStatus': 'WAITING',
        'version': 1,
        'slotId': slotId,
        'startAt': start.toIso8601String(),
        'endAt': start.add(const Duration(minutes: 30)).toIso8601String(),
        'doctorClinicAffiliationId': 'aff-mock',
        'clinicId': 'clinic-mock',
        'clinicName': 'عيادة تجريبية',
        'clinicBranchId': clinicBranchId,
        'clinicBranchPhone': '+201000000000',
        'clinicAddressLine1': 'شارع تجريبي',
        'clinicCity': 'القاهرة',
        'ianaTimezone': 'Africa/Cairo',
        'patientId': resolvedPatientId,
        'patientName': patientName ?? 'مريض جديد',
        'patientPhone': patientPhone ?? '',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'cancelledReason': null,
        'rescheduledFromAppointmentId': null,
      };
      _mockProviderDashboardStore.appointments.add(appointment);
      _mockProviderDashboardStore.persistAppointments();

      return {
        'statusCode': 201,
        'data': {'appointmentId': appointmentId, 'status': 'CONFIRMED'},
      };
    }

    final actionIndex = parts.indexWhere(
      (p) => p == 'cancel' || p == 'reschedule',
    );
    if (actionIndex <= 0) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'إجراء غير معروف.');
    }
    final action = parts[actionIndex];
    final appointmentId = parts[actionIndex - 1];

    final index = _mockProviderDashboardStore.appointments.indexWhere(
      (a) => a['appointmentId'] == appointmentId,
    );
    if (index == -1) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد غير موجود.');
    }

    final appointment = Map<String, dynamic>.from(
      _mockProviderDashboardStore.appointments[index],
    );
    if (appointment['status'] != 'CONFIRMED') {
      return _error(
        422,
        action == 'cancel'
            ? 'APPOINTMENT_NOT_CANCELLABLE'
            : 'APPOINTMENT_NOT_RESCHEDULABLE',
        'Only a confirmed appointment can be ${action == 'cancel' ? 'cancelled' : 'rescheduled'}.',
      );
    }
    if ((appointment['visitStatus'] as String? ?? 'WAITING') != 'WAITING') {
      return _error(
        422,
        'APPOINTMENT_VISIT_IN_PROGRESS',
        'لا يمكن إلغاء الموعد أو تغييره بعد دخول المريض إلى غرفة الطبيب.',
      );
    }

    final body = _body(options) ?? {};

    if (action == 'cancel') {
      final reason = body['reason'] as String?;
      // The real route accepts PROVIDER_REQUEST only — anything else is a 400
      // at the DTO boundary, which is what waives the cancellation fee.
      if (reason != 'PROVIDER_REQUEST') {
        return _error(
          400,
          'VALIDATION_ERROR',
          'سبب الإلغاء غير مسموح به في هذا الإجراء.',
        );
      }
      final note = body['note'] as String?;
      appointment['status'] = 'CANCELLED';
      appointment['version'] = ((appointment['version'] as num?)?.toInt() ?? 1) + 1;
      appointment['cancelledReason'] = note == null || note.isEmpty
          ? 'PROVIDER_REQUEST'
          : 'PROVIDER_REQUEST: $note';
      _mockProviderDashboardStore.appointments[index] = appointment;
      _mockProviderDashboardStore.persistAppointments();
      return {
        'statusCode': 201,
        'data': {'status': 'CANCELLED', 'refundAmount': 250.0, 'feeApplied': 0},
      };
    }

    final newSlotId = body['newSlotId'] as String?;
    if (newSlotId == null || newSlotId.isEmpty) {
      return _error(400, 'VALIDATION_ERROR', 'اختر الموعد الجديد.');
    }
    // The slot must belong to the same branch — mirrors the backend's
    // same-affiliation 404 (Part 35.11), using the mock slot-id convention
    // `<branchId>-<startAtIso>` that `registerAvailabilityMocks` produces.
    final branchId = appointment['clinicBranchId'] as String;
    if (!newSlotId.startsWith('$branchId-')) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد المتاح غير موجود.');
    }

    final newStart =
        DateTime.tryParse(newSlotId.substring(branchId.length + 1))?.toUtc() ??
        DateTime.now().toUtc();

    appointment['status'] = 'RESCHEDULED';
    _mockProviderDashboardStore.appointments[index] = appointment;

    final replacementId = 'apt-${DateTime.now().millisecondsSinceEpoch}';
    final replacement = Map<String, dynamic>.from(appointment)
      ..['appointmentId'] = replacementId
      ..['status'] = 'CONFIRMED'
      ..['visitStatus'] = 'WAITING'
      ..['version'] = 1
      ..['slotId'] = newSlotId
      ..['startAt'] = newStart.toIso8601String()
      ..['endAt'] = newStart.add(const Duration(minutes: 30)).toIso8601String()
      ..['rescheduledFromAppointmentId'] = appointmentId
      ..['cancelledReason'] = null;
    _mockProviderDashboardStore.appointments.add(replacement);
    _mockProviderDashboardStore.persistAppointments();

    return {
      'statusCode': 200,
      'data': {
        'status': 'CONFIRMED',
        'appointmentId': replacementId,
        'slotId': newSlotId,
        'previousAppointmentId': appointmentId,
      },
    };
  });

  interceptor.register('PATCH', ApiPaths.doctorMeAppointments, (options) {
    final parts = options.path.split('/');
    if (parts.isEmpty || parts.last != 'visit-status' || parts.length < 2) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'إجراء غير معروف.');
    }

    final appointmentId = parts[parts.length - 2];
    final index = _mockProviderDashboardStore.appointments.indexWhere(
      (a) => a['appointmentId'] == appointmentId,
    );
    if (index == -1) {
      return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد غير موجود.');
    }

    final appointment = Map<String, dynamic>.from(
      _mockProviderDashboardStore.appointments[index],
    );
    final body = _body(options) ?? {};
    final requested = body['status'] as String?;
    final requestedVersion = (body['version'] as num?)?.toInt();
    final currentVersion = (appointment['version'] as num?)?.toInt() ?? 1;
    final current = appointment['visitStatus'] as String? ?? 'WAITING';
    const next = <String, String?>{
      'WAITING': 'IN_DOCTOR_ROOM',
      'IN_DOCTOR_ROOM': 'LEFT',
      'LEFT': null,
    };

    if (requestedVersion != currentVersion) {
      return _error(
        409,
        'OPTIMISTIC_LOCK_CONFLICT',
        'تم تحديث الموعد من جهاز آخر. حدّث القائمة ثم أعد المحاولة.',
      );
    }
    if (appointment['status'] != 'CONFIRMED') {
      return _error(
        422,
        'APPOINTMENT_VISIT_STATUS_NOT_UPDATABLE',
        'يمكن تحديث حالة الزيارة للمواعيد المؤكدة فقط.',
      );
    }
    if (requested == null || next[current] != requested) {
      return _error(
        422,
        'INVALID_VISIT_STATUS_TRANSITION',
        'يجب تحديث حالة الزيارة بالترتيب.',
      );
    }

    appointment['visitStatus'] = requested;
    appointment['version'] = currentVersion + 1;
    _mockProviderDashboardStore.appointments[index] = appointment;
    _mockProviderDashboardStore.persistAppointments();
    return {'statusCode': 200, 'data': appointment};
  });

  interceptor.register('GET', ApiPaths.doctorMeAppointments, (options) {
    if (_mockProviderDashboardStore.appointments.isEmpty) {
      _mockProviderDashboardStore.appointments = _seedDoctorAppointments();
      _mockProviderDashboardStore.persistAppointments();
    }

    // Detail: `/v1/doctors/me/appointments/{id}` — the path carries one more
    // segment than the list route.
    final tail = options.path.split('/').last;
    if (tail != 'appointments') {
      final match = _mockProviderDashboardStore.appointments.firstWhere(
        (a) => a['appointmentId'] == tail,
        orElse: () => const {},
      );
      if (match.isEmpty) {
        return _error(404, 'RESOURCE_NOT_FOUND', 'الموعد غير موجود.');
      }
      return {'statusCode': 200, 'data': match};
    }

    var items = List<Map<String, dynamic>>.from(
      _mockProviderDashboardStore.appointments,
    );

    final status = options.queryParameters['status'] as String?;
    if (status != null && status.isNotEmpty) {
      items = items.where((a) => a['status'] == status).toList();
    }

    final branchId = options.queryParameters['clinicBranchId'] as String?;
    if (branchId != null && branchId.isNotEmpty) {
      final owned = _mockProviderDashboardStore.clinics.any(
        (c) => c['clinicBranchId'] == branchId,
      );
      if (!owned) {
        return _error(404, 'RESOURCE_NOT_FOUND', 'فرع العيادة غير موجود.');
      }
      items = items.where((a) => a['clinicBranchId'] == branchId).toList();
    }

    // Both bounds are applied — the backend's own half-open `[from, to)`
    // range. Applying only one here would hide the exact class of bug the
    // real repository had before File 12 Part 49.7 fixed it.
    final from = DateTime.tryParse(
      options.queryParameters['from'] as String? ?? '',
    );
    final to = DateTime.tryParse(
      options.queryParameters['to'] as String? ?? '',
    );
    if (from != null || to != null) {
      items = items.where((a) {
        final startAt = DateTime.parse(a['startAt'] as String).toUtc();
        if (from != null && startAt.isBefore(from.toUtc())) return false;
        if (to != null && !startAt.isBefore(to.toUtc())) return false;
        return true;
      }).toList();
    }

    items.sort(
      (a, b) => (a['startAt'] as String).compareTo(b['startAt'] as String),
    );

    return {
      'statusCode': 200,
      'data': {'items': items, 'nextCursor': null},
    };
  });

}

/// Phase 8 notifications — mirrors `GET/PATCH /v1/notifications`.
void registerNotificationMocks(MockInterceptor interceptor) {
  // More specific `/read` paths must register before the list route — both
  // contain `/v1/notifications` and MockInterceptor is first-registered-wins.
  interceptor.register('PATCH', '${ApiPaths.notifications}/', (options) {
    final path = options.path;
    if (!path.contains('/read')) {
      return _error(404, 'NOT_FOUND', 'المسار غير موجود.');
    }

    final parts = path.split('/');
    final readIndex = parts.indexWhere((p) => p == 'read');
    final id = readIndex > 0 ? parts[readIndex - 1] : '';

    final index = _mockNotificationStore.rows.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(_mockNotificationStore.rows[index]);
      updated['read_at'] = DateTime.now().toUtc().toIso8601String();
      _mockNotificationStore.rows[index] = updated;
      _mockNotificationStore.persist();
    }

    return {
      'statusCode': 200,
      'data': {'id': id, 'status': 'READ'},
    };
  });

  interceptor.register('GET', ApiPaths.notifications, (options) {
    if (_mockNotificationStore.rows.isEmpty) {
      _mockNotificationStore.rows = _seedBackendNotifications();
      _mockNotificationStore.persist();
    }

    final unreadOnly =
        options.uri.queryParameters['unreadOnly'] == 'true' ||
        options.uri.queryParameters['unreadOnly'] == '1';
    var items = _mockNotificationStore.rows;
    if (unreadOnly) {
      items = items.where((row) => row['read_at'] == null).toList();
    }

    final limit = int.tryParse(options.uri.queryParameters['limit'] ?? '') ?? 20;
    final page = items.take(limit).toList();

    return {
      'statusCode': 200,
      'data': {
        'notifications': page,
        'nextCursor': items.length > limit ? 'mock-cursor-2' : null,
      },
    };
  });
}

/// Mirrors the real payments-module wallet shapes (File 12 Part 50.3):
/// camelCase keys, money as fixed 2-decimal strings, SCREAMING_SNAKE enums.
/// `WITHDRAWAL` is the one invented type — it belongs to the mock-only
/// transfer-out flow, which has no backend counterpart.
class _MockWalletStore {
  double availableBalance = 2450.0;
  String currency = 'EGP';
  final String walletId = 'wal-0001';

  final List<Map<String, dynamic>> transactions = [
    {
      'id': 'tx-101',
      'type': 'APPOINTMENT_PAYMENT',
      'status': 'COMPLETED',
      'amount': '350.00',
      'resultingBalance': '2450.00',
      'paymentIntentId': 'pi-101',
      'appointmentId': 'apt-101',
      'createdAt': '2026-08-18T14:30:00Z',
    },
    {
      'id': 'tx-102',
      'type': 'TOP_UP',
      'status': 'COMPLETED',
      'amount': '1000.00',
      'resultingBalance': '2800.00',
      'paymentIntentId': 'pi-102',
      'appointmentId': null,
      'createdAt': '2026-08-15T10:15:00Z',
    },
    {
      'id': 'tx-103',
      'type': 'APPOINTMENT_PAYMENT',
      'status': 'COMPLETED',
      'amount': '600.00',
      'resultingBalance': '1800.00',
      'paymentIntentId': 'pi-103',
      'appointmentId': 'apt-103',
      'createdAt': '2026-08-10T09:00:00Z',
    },
    {
      'id': 'tx-104',
      'type': 'REFUND',
      'status': 'COMPLETED',
      'amount': '250.00',
      'resultingBalance': '2400.00',
      'paymentIntentId': 'pi-104',
      'appointmentId': 'apt-104',
      'createdAt': '2026-08-05T16:45:00Z',
    },
  ];

  final Map<String, Map<String, dynamic>> refunds = {};

  /// The `INTERNAL_WALLET` confirm branch, as far as the mock models it:
  /// balance down, a `COMPLETED` `APPOINTMENT_PAYMENT` row appended.
  void debitForAppointment(double amount) {
    availableBalance -= amount;
    transactions.insert(0, {
      'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'APPOINTMENT_PAYMENT',
      'status': 'COMPLETED',
      'amount': amount.toStringAsFixed(2),
      'resultingBalance': availableBalance.toStringAsFixed(2),
      'paymentIntentId': 'pi-${DateTime.now().millisecondsSinceEpoch}',
      'appointmentId': 'mock-appointment',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

/// The mock confirm endpoint receives no fee (the real backend reads it off
/// the affiliation), so wallet debits use one representative consult fee.
const _kMockConsultFee = 350.0;

final _mockWalletStore = _MockWalletStore();

void registerWalletMocks(MockInterceptor interceptor) {
  // Ordering matters: MockInterceptor matches first-registered-wins by
  // substring containment, and `/v1/wallet` is a prefix of every path below
  // it — so the balance handler must be registered LAST of the wallet GETs.
  interceptor.register('GET', '/v1/wallet/transactions', (options) {
    final limit =
        int.tryParse(options.uri.queryParameters['limit'] ?? '') ?? 20;
    final page = _mockWalletStore.transactions.take(limit).toList();
    return {
      'statusCode': 200,
      'data': {
        'transactions': page,
        'nextCursor': _mockWalletStore.transactions.length > limit
            ? 'mock-wallet-cursor-2'
            : null,
      },
    };
  });

  // `POST /v1/wallet/top-up` (File 12 Part 50.3). Deliberately does NOT
  // credit the balance: the real endpoint only opens a Paymob checkout and
  // writes a PENDING row, and the balance moves on the capture webhook.
  // Faking an instant credit here would make the mock the only place the
  // top-up flow ever appears to work.
  interceptor.register('POST', '/v1/wallet/top-up', (options) {
    final body = _body(options) ?? {};
    final amount = double.tryParse('${body['amount']}') ?? 0.0;
    if (amount <= 0) {
      return _error(400, 'INVALID_AMOUNT', 'قيمة الشحن يجب أن تكون أكبر من صفر.');
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final walletTransactionId = 'tx-$stamp';
    _mockWalletStore.transactions.insert(0, {
      'id': walletTransactionId,
      'type': 'TOP_UP',
      'status': 'PENDING',
      'amount': amount.toStringAsFixed(2),
      'resultingBalance': null,
      'paymentIntentId': 'pi-$stamp',
      'appointmentId': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return {
      'statusCode': 200,
      'data': {
        'walletTransactionId': walletTransactionId,
        'paymentIntentId': 'pi-$stamp',
        'redirectUrl':
            'https://accept.paymob.com/api/acceptance/iframes/mock?payment_token=mock-$stamp',
      },
    };
  });

  interceptor.register('POST', '/v1/wallet/transfers', (options) {
    final body = _body(options) ?? {};
    final amount = (body['amount'] as num?)?.toDouble() ?? 0.0;
    _mockWalletStore.availableBalance -= amount;
    final newTx = {
      'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'WITHDRAWAL',
      'status': 'COMPLETED',
      'amount': amount.toStringAsFixed(2),
      'resultingBalance': _mockWalletStore.availableBalance.toStringAsFixed(2),
      'paymentIntentId': null,
      'appointmentId': null,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _mockWalletStore.transactions.insert(0, newTx);
    return {'statusCode': 200, 'data': newTx};
  });

  interceptor.register('GET', '/v1/wallet/refunds/', (options) {
    final pathParts = options.path.split('/');
    final id = pathParts.isNotEmpty ? pathParts.last : 'ref-201';
    final refundObj =
        _mockWalletStore.refunds[id] ??
        {
          'id': id.isEmpty ? 'ref-201' : id,
          'transaction_id': 'tx-101',
          'reason': 'إلغاء الموعد قبل 24 ساعة',
          'details': 'تم إلغاء الجلسة بسبب عدم تناسب الموعد',
          'status': 'under_review',
          'created_at': '2026-08-19T10:00:00Z',
          'amount': 450.0,
        };

    return {'statusCode': 200, 'data': refundObj};
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

    return {'statusCode': 200, 'data': refundObj};
  });

  // Registered last on purpose — see the ordering note at the top of this
  // function.
  interceptor.register('GET', '/v1/wallet', (_) {
    return {
      'statusCode': 200,
      'data': {
        'walletId': _mockWalletStore.walletId,
        'balance': _mockWalletStore.availableBalance.toStringAsFixed(2),
        'currency': _mockWalletStore.currency,
      },
    };
  });
}

// ─── Clinic Assistant mocks ──────────────────────────────────────────────────
//
// Pre-seeded assistant demo account so the phone+password login screen works
// standalone without first running the full Doctor create-assistant flow.
// Phone: 01100000001 — role: CLINIC_STAFF.
const kMockAssistantPhone = '01100000001';
const kMockAssistantPhoneNormalized = '+201100000001';
const kMockAssistantPassword = 'Assist1234';
const kMockAssistantDisplayName = 'سارة المساعدة';

/// In-memory store for assistant records keyed by id.
final Map<String, Map<String, dynamic>> _mockAssistants = {
  'asst-001': {
    'id': 'asst-001',
    'phone': '+201100000001',
    'display_name': 'سارة المساعدة',
    'status': 'ACTIVE',
    'created_at': '2026-08-01T09:00:00.000Z',
  },
  'asst-002': {
    'id': 'asst-002',
    'phone': '+201200000002',
    'display_name': 'محمد المساعد',
    'status': 'ACTIVE',
    'created_at': '2026-08-10T11:30:00.000Z',
  },
};

/// Registers all assistant-related mock endpoints on [interceptor].
/// Must be called AFTER [registerFoundationMocks] so the demo assistant
/// phone+password are already present in [_passwordsByPhone].
void registerAssistantMocks(MockInterceptor interceptor) {
  // Seed demo assistant account into the shared password store so the
  // /account-login screen can authenticate with it.
  _passwordsByPhone[kMockAssistantPhoneNormalized] = kMockAssistantPassword;

  // GET /v1/provider/assistants — list
  interceptor.register('GET', '/v1/provider/assistants', (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(
        401,
        'UNAUTHENTICATED',
        'يلزم تسجيل الدخول لإتمام هذا الإجراء.',
      );
    }
    return {
      'statusCode': 200,
      'data': {'items': _mockAssistants.values.toList()},
    };
  });

  // POST /v1/provider/assistants — create
  interceptor.register('POST', '/v1/provider/assistants', (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(
        401,
        'UNAUTHENTICATED',
        'يلزم تسجيل الدخول لإتمام هذا الإجراء.',
      );
    }
    final body = _body(options);
    final phone = body?['phone'] as String?;
    final displayName =
        (body?['display_name'] ?? body?['displayName']) as String?;

    if (phone == null || phone.isEmpty) {
      return _error(422, 'VALIDATION_ERROR', 'رقم الهاتف مطلوب.');
    }
    if (displayName == null || displayName.isEmpty) {
      return _error(422, 'VALIDATION_ERROR', 'الاسم المعروض مطلوب.');
    }

    final id = 'asst-${DateTime.now().millisecondsSinceEpoch}';
    // Normalise phone to E.164 using the same logic the real backend applies.
    final normalized = phone.startsWith('+') ? phone : '+2$phone';
    // Generate a deterministic mock password for this new assistant.
    const generatedPassword = 'MedS@2026!';
    _passwordsByPhone[normalized] = generatedPassword;

    final record = {
      'id': id,
      'phone': normalized,
      'display_name': displayName,
      'status': 'ACTIVE',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _mockAssistants[id] = record;

    return {
      'statusCode': 200,
      'data': {...record, 'generated_password': generatedPassword},
    };
  });

  // PATCH /v1/provider/assistants/:id — update display_name and/or status.
  // MockInterceptor matches by substring containment — the more-specific
  // POST handler above is registered first so it takes precedence for exact
  // '/v1/provider/assistants' (no trailing slash), while this pattern
  // '/v1/provider/assistants/' matches paths with an ID segment appended.
  interceptor.register('PATCH', '/v1/provider/assistants/', (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(
        401,
        'UNAUTHENTICATED',
        'يلزم تسجيل الدخول لإتمام هذا الإجراء.',
      );
    }
    final segments = options.path.split('/');
    final id = segments.isNotEmpty ? segments.last.split('?').first : '';
    final record = _mockAssistants[id];
    if (record == null) {
      return _error(404, 'NOT_FOUND', 'المساعد غير موجود.');
    }

    final body = _body(options);
    if (body?['display_name'] != null) {
      record['display_name'] = body!['display_name'];
    }
    if (body?['status'] != null) {
      record['status'] = (body!['status'] as String).toUpperCase();
    }
    if (body?['password'] != null) {
      _passwordsByPhone[record['phone'] as String] =
          body!['password'] as String;
    }
    record['updated_at'] = DateTime.now().toUtc().toIso8601String();
    _mockAssistants[id] = record;

    return {
      'statusCode': 200,
      'data': {
        ...record,
        if (body?['password'] != null) 'generated_password': body!['password'],
      },
    };
  });

  // DELETE /v1/provider/assistants/:id — soft-deactivate
  interceptor.register('DELETE', '/v1/provider/assistants/', (options) {
    final token = _bearer(options);
    if (token == null) {
      return _error(
        401,
        'UNAUTHENTICATED',
        'يلزم تسجيل الدخول لإتمام هذا الإجراء.',
      );
    }
    final segments = options.path.split('/');
    final id = segments.isNotEmpty ? segments.last.split('?').first : '';
    if (!_mockAssistants.containsKey(id)) {
      return _error(404, 'NOT_FOUND', 'المساعد غير موجود.');
    }
    _mockAssistants.remove(id);
    return {'statusCode': 200, 'data': <String, dynamic>{}};
  });
}
