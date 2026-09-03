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
  final raw = options.headers['Authorization'] ?? options.headers['authorization'];
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
  interceptor.register('GET', '/health', (_) => {
        'statusCode': 200,
        'data': {'status': 'ok', 'version': '0.0.1-mock'},
      });

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
      'data': {
        'request_id': 'otp-req-001',
        'expires_in': 60,
      },
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
      'data': {
        'access_token': access,
        'refresh_token': refresh,
      },
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
      'data': {
        'access_token': access,
        'refresh_token': refresh,
      },
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

    return {
      'statusCode': 200,
      'data': _userPayload(),
    };
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
    return {
      'statusCode': 200,
      'data': _userPayload(),
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
