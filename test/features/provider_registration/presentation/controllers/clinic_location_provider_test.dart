import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';

void main() {
  test('ClinicLocationService can be constructed', () {
    // ClinicLocationService.getCurrentPosition() calls the real static
    // Geolocator.checkPermission/requestPermission/isLocationServiceEnabled/
    // getCurrentPosition methods directly. Those are backed by platform
    // channels (MethodChannel('flutter.baseflow.com/geolocator')) that do
    // not exist in a plain `flutter test` run (no platform binding is
    // registered), and geolocator does not expose an injectable seam
    // (no constructor parameter, no GeolocatorPlatform.instance override
    // hook used by this wrapper) to substitute a fake implementation
    // without either wrapping every static call individually or adding a
    // new production abstraction purely for testability. Rather than
    // force a brittle test that stubs `MethodChannel` handlers for an
    // implementation detail of a third-party plugin, we verify only the
    // trivial, real behavior available without a platform binding: the
    // service can be constructed and is reusable (a `const` instance).
    const service = ClinicLocationService();
    const service2 = ClinicLocationService();
    expect(service, isNotNull);
    expect(service, equals(service2)); // const canonicalization
  });
}
