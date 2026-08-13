import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';

/// Real interactive map (OpenStreetMap tiles via flutter_map — free, no API
/// key) showing every candidate lab, matching the Figma "Map View" card.
/// Reuses [ClinicLocationService] (already built for provider registration)
/// for the "locate me" button rather than duplicating the geolocator wrapper.
class LabPartnersMapView extends StatefulWidget {
  const LabPartnersMapView({
    required this.partners,
    required this.selectedId,
    required this.onSelect,
    this.tileProvider,
    super.key,
  });

  final List<LabPartner> partners;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Overridable for tests, so `flutter test` never issues a real network
  /// request to the OSM tile servers (which is slow, flaky, and — under
  /// `pumpAndSettle` — can hang the test on retry). Defaults to `null`,
  /// which lets [TileLayer] fall back to its own real [NetworkTileProvider].
  final TileProvider? tileProvider;

  @override
  State<LabPartnersMapView> createState() => _LabPartnersMapViewState();
}

class _LabPartnersMapViewState extends State<LabPartnersMapView> {
  late final _mapController = MapController();
  late final _locationService = const ClinicLocationService();
  bool _locating = false;

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final position = await _locationService.getCurrentPosition();
    if (position != null) _mapController.move(position, 13);
    if (mounted) setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.partners.isEmpty
        ? const LatLng(24.7136, 46.6753)
        : LatLng(
            widget.partners.first.latitude,
            widget.partners.first.longitude,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.patientPrimary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 12),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.medsuper.med_super',
                  tileProvider: widget.tileProvider,
                ),
                MarkerLayer(
                  markers: widget.partners
                      .map(
                        (partner) => Marker(
                          point: LatLng(partner.latitude, partner.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => widget.onSelect(partner.id),
                            child: Icon(
                              Icons.location_pin,
                              color: partner.id == widget.selectedId
                                  ? AppColors.patientPrimary
                                  : AppColors.mutedText2,
                              size: 36,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _locating ? null : _locateMe,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColors.patientPrimary,
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
