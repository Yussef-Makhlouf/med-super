import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// Real interactive map (OpenStreetMap tiles via flutter_map — free, no API
/// key) matching the Figma "Clinic location" card exactly.
class ClinicLocationMapView extends StatefulWidget {
  const ClinicLocationMapView({
    required this.initialPosition,
    required this.onPositionChanged,
    required this.onLocateMe,
    super.key,
  });

  final LatLng initialPosition;
  final ValueChanged<LatLng> onPositionChanged;
  final Future<LatLng?> Function() onLocateMe;

  @override
  State<ClinicLocationMapView> createState() => _ClinicLocationMapViewState();
}

class _ClinicLocationMapViewState extends State<ClinicLocationMapView> {
  late final _mapController = MapController();
  bool _locating = false;

  /// Moves the map camera and reports the new center — used by both the
  /// "locate me" button and tapping anywhere on the map to jump there.
  /// Dragging the map itself is reported via [MapOptions.onPositionChanged]
  /// below, so the clinic location is never limited to the device's GPS
  /// position — any point can be chosen by panning or tapping the map.
  void _moveTo(LatLng point) {
    _mapController.move(point, _mapController.camera.zoom);
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final result = await widget.onLocateMe();
    if (result != null) _moveTo(result);
    if (mounted) setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 256,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderMedium),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialPosition,
                initialZoom: 14,
                // Only report the settled position once a drag/fling/zoom
                // gesture actually finishes — `onPositionChanged` fires on
                // every intermediate frame of a drag, and each call here
                // used to trigger a full Hive disk write + Riverpod state
                // update up in `DoctorRegistrationClinicScheduleScreen`,
                // causing visible lag while panning the map.
                onMapEvent: (event) {
                  final isSettledGesture =
                      event is MapEventMoveEnd ||
                      event is MapEventFlingAnimationEnd ||
                      event is MapEventDoubleTapZoomEnd;
                  // A programmatic `_mapController.move()` call (tap-to-move,
                  // "locate me") is a single discrete jump reported as one
                  // `MapEventMove`, not a per-frame drag update — safe to
                  // report immediately, unlike a drag's `MapEventMove`s.
                  final isProgrammaticMove =
                      event is MapEventMove &&
                      event.source == MapEventSource.mapController;
                  if (isSettledGesture || isProgrammaticMove) {
                    widget.onPositionChanged(event.camera.center);
                  }
                },
                onTap: (_, point) => _moveTo(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.medsuper.med_super',
                ),
              ],
            ),
            // Fixed pin at the exact center of the viewport — the user pans
            // the map underneath it to choose any location, rather than the
            // pin following a marker tied to a single stored point.
            const IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.location_pin,
                  color: AppColors.providerPrimary,
                  size: 40,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              left: 16,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: InkWell(
                    onTap: _locating ? null : _locateMe,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _locating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: AppColors.providerPrimary,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            'provider_registration.locate_me'.tr(),
                            style: const TextStyle(
                              color: AppColors.providerPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
