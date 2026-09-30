import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/config/app_config.dart';

const mockBaseUrl = 'https://mock.medsuper.local';

void main() {
  group('AppConfig.validateBuildConfiguration', () {
    test('allows debug builds to use mock mode', () {
      expect(
        () => AppConfig.validateBuildConfiguration(
          isReleaseBuild: false,
          env: 'dev',
          baseUrl: mockBaseUrl,
          mockBaseUrl: mockBaseUrl,
        ),
        returnsNormally,
      );
    });

    test('rejects release builds that use the mock API', () {
      expect(
        () => AppConfig.validateBuildConfiguration(
          isReleaseBuild: true,
          env: 'production',
          baseUrl: mockBaseUrl,
          mockBaseUrl: mockBaseUrl,
        ),
        throwsStateError,
      );
    });

    test('rejects release builds with a non-HTTPS API URL', () {
      expect(
        () => AppConfig.validateBuildConfiguration(
          isReleaseBuild: true,
          env: 'staging',
          baseUrl: 'http://api.example.test',
          mockBaseUrl: mockBaseUrl,
        ),
        throwsStateError,
      );
    });

    test('accepts release builds with staging or production HTTPS APIs', () {
      for (final env in ['staging', 'production']) {
        expect(
          () => AppConfig.validateBuildConfiguration(
            isReleaseBuild: true,
            env: env,
            baseUrl: 'https://api.example.test',
            mockBaseUrl: mockBaseUrl,
          ),
          returnsNormally,
        );
      }
    });

    test('rejects release builds that still have ENV=dev', () {
      expect(
        () => AppConfig.validateBuildConfiguration(
          isReleaseBuild: true,
          env: 'dev',
          baseUrl: 'https://api.example.test',
          mockBaseUrl: mockBaseUrl,
        ),
        throwsStateError,
      );
    });
  });
}
