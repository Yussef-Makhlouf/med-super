import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// A 1x1 transparent PNG, reused as a stand-in tile image.
final Uint8List _onePixelPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, //
  0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, //
  13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130, //
]);

/// A [TileProvider] that never touches the network — every tile resolves
/// instantly to the same local, decodable image. `flutter test` has no
/// business making real HTTP requests to the OSM tile servers: it's slow,
/// flaky, and a failed/retried request can keep `pumpAndSettle` from ever
/// settling. Pass this to [LabPartnersMapView]/any [TileLayer] under test.
class FakeTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(_onePixelPng);
}
