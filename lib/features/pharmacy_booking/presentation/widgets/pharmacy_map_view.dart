import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:solar_icons/solar_icons.dart';

/// Real interactive map (OpenStreetMap tiles via flutter_map — free, no API
/// key) showing every candidate pharmacy, mirroring `LabPartnersMapView`'s
/// structure for the pharmacy booking flow's own step 2. Reuses
/// [ClinicLocationService] (already built for provider registration) for
/// the "locate me" button rather than duplicating the geolocator wrapper.
class PharmacyMapView extends StatefulWidget {
  const PharmacyMapView({
    required this.pharmacies,
    required this.selectedId,
    required this.onSelect,
    this.tileProvider,
    super.key,
  });

  final List<Pharmacy> pharmacies;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Overridable for tests, so `flutter test` never issues a real network
  /// request to the OSM tile servers. Defaults to `null`, which lets
  /// [TileLayer] fall back to its own real [NetworkTileProvider].
  final TileProvider? tileProvider;

  @override
  State<PharmacyMapView> createState() => _PharmacyMapViewState();
}

class _PharmacyMapViewState extends State<PharmacyMapView> {
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
    final mappedPharmacies = widget.pharmacies
        .where(
          (pharmacy) => pharmacy.latitude != null && pharmacy.longitude != null,
        )
        .toList();
    final center = mappedPharmacies.isEmpty
        ? const LatLng(24.7136, 46.6753)
        : LatLng(
            mappedPharmacies.first.latitude!,
            mappedPharmacies.first.longitude!,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 220,
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
                  markers: mappedPharmacies
                      .map(
                        (pharmacy) => Marker(
                          point: LatLng(
                            pharmacy.latitude!,
                            pharmacy.longitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => widget.onSelect(pharmacy.id),
                            child: Icon(
                              SolarIconsBold.mapPoint,
                              color: pharmacy.id == widget.selectedId
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
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'pharmacy_booking.select_pharmacy.edit_location'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.patientPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      // Real result count from `GET /v1/pharmacy-branches/search`
                      // (`widget.pharmacies`), which the backend already
                      // scopes to `radiusKm` when the device location is
                      // known (File 12 Part 37) — no longer a fabricated
                      // placeholder.
                      'pharmacy_booking.select_pharmacy.nearby_count'.tr(
                        args: ['${widget.pharmacies.length}'],
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink700,
                      ),
                    ),
                  ),
                ],
              ),
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
                          SolarIconsBold.gps,
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
