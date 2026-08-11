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
  late LatLng _position = widget.initialPosition;
  bool _locating = false;

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final result = await widget.onLocateMe();
    if (result != null) {
      setState(() => _position = result);
      _mapController.move(result, 15);
      widget.onPositionChanged(result);
    }
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
                initialCenter: _position,
                initialZoom: 14,
                onTap: (_, point) {
                  setState(() => _position = point);
                  widget.onPositionChanged(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.medsuper.med_super',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.providerPrimary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
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
