import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:solar_icons/solar_icons.dart';

/// Real interactive map (OpenStreetMap tiles via flutter_map — free, no API
/// key) showing every candidate lab branch. Mirrors `pharmacy_booking`'s
/// `PharmacyMapView`. Reuses [ClinicLocationService] (already built for
/// provider registration) for the "locate me" button rather than duplicating
/// the geolocator wrapper.
class LabBranchesMapView extends StatefulWidget {
  const LabBranchesMapView({
    required this.branches,
    required this.selectedId,
    required this.onSelect,
    this.tileProvider,
    super.key,
  });

  final List<LabBranch> branches;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Overridable for tests, so `flutter test` never issues a real network
  /// request to the OSM tile servers.
  final TileProvider? tileProvider;

  @override
  State<LabBranchesMapView> createState() => _LabBranchesMapViewState();
}

class _LabBranchesMapViewState extends State<LabBranchesMapView> {
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
    final mappedBranches = widget.branches
        .where((branch) => branch.latitude != null && branch.longitude != null)
        .toList();
    final center = mappedBranches.isEmpty
        ? const LatLng(30.0444, 31.2357)
        : LatLng(mappedBranches.first.latitude!, mappedBranches.first.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.raised,
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
                  markers: mappedBranches
                      .map(
                        (branch) => Marker(
                          point: LatLng(branch.latitude!, branch.longitude!),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => widget.onSelect(branch.id),
                            child: Icon(
                              SolarIconsBold.mapPoint,
                              color: branch.id == widget.selectedId
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
