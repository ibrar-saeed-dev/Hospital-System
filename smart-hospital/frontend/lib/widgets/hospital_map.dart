import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../config/app_theme.dart';
import '../models/admin_hospital_item.dart';
import '../models/hospital_search_result.dart';
import '../services/map_service.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'match_ring.dart';
import 'status_chip.dart';

class HospitalMap extends StatefulWidget {
  final LatLng? userLocation;
  final List<HospitalMatchItem> suitableHospitals;
  final List<HospitalExcludedItem> excludedHospitals;
  final List<AdminHospitalItem>? adminHospitals;
  final List<String> requiredResources;
  final void Function(HospitalMatchItem)? onRequestHospital;
  final void Function(HospitalMatchItem)? onSelectHospital;
  final LatLng? initialCenter;
  final double initialZoom;
  final bool isMiniMap;

  const HospitalMap({
    super.key,
    this.userLocation,
    this.suitableHospitals = const [],
    this.excludedHospitals = const [],
    this.adminHospitals,
    this.requiredResources = const [],
    this.onRequestHospital,
    this.onSelectHospital,
    this.initialCenter,
    this.initialZoom = 12.5,
    this.isMiniMap = false,
  });

  @override
  State<HospitalMap> createState() => _HospitalMapState();
}

class _HospitalMapState extends State<HospitalMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  HospitalMatchItem? _selectedSuitable;
  HospitalExcludedItem? _selectedExcluded;
  AdminHospitalItem? _selectedAdmin;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  @override
  void didUpdateWidget(covariant HospitalMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suitableHospitals != oldWidget.suitableHospitals ||
        widget.userLocation != oldWidget.userLocation ||
        widget.adminHospitals != oldWidget.adminHospitals) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _fitBounds() {
    final points = <LatLng>[];

    if (widget.userLocation != null) {
      points.add(widget.userLocation!);
    }

    for (final h in widget.suitableHospitals) {
      if (h.latitude != null && h.longitude != null) {
        points.add(LatLng(h.latitude!, h.longitude!));
      }
    }

    for (final h in widget.excludedHospitals) {
      if (h.latitude != null && h.longitude != null) {
        points.add(LatLng(h.latitude!, h.longitude!));
      }
    }

    if (widget.adminHospitals != null) {
      for (final h in widget.adminHospitals!) {
        if (h.latitude != null && h.longitude != null) {
          points.add(LatLng(h.latitude!, h.longitude!));
        }
      }
    }

    if (points.isNotEmpty) {
      if (points.length == 1) {
        _mapController.move(points.first, widget.initialZoom);
      } else {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } else if (widget.initialCenter != null) {
      _mapController.move(widget.initialCenter!, widget.initialZoom);
    }
  }

  LatLng _getEffectiveCenter() {
    if (widget.userLocation != null) return widget.userLocation!;
    if (widget.suitableHospitals.isNotEmpty) {
      final first = widget.suitableHospitals.first;
      if (first.latitude != null && first.longitude != null) {
        return LatLng(first.latitude!, first.longitude!);
      }
    }
    if (widget.adminHospitals != null && widget.adminHospitals!.isNotEmpty) {
      final first = widget.adminHospitals!.first;
      if (first.latitude != null && first.longitude != null) {
        return LatLng(first.latitude!, first.longitude!);
      }
    }
    return widget.initialCenter ?? const LatLng(17.3850, 78.4867); // Hyderabad fallback
  }

  @override
  Widget build(BuildContext context) {
    final center = _getEffectiveCenter();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return ClipRRect(
      borderRadius: widget.isMiniMap ? AppRadius.radiusMd : BorderRadius.zero,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.initialZoom,
              minZoom: 4,
              maxZoom: 18,
              interactionOptions: InteractionOptions(
                flags: widget.isMiniMap
                    ? InteractiveFlag.none
                    : InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedSuitable = null;
                  _selectedExcluded = null;
                  _selectedAdmin = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.smarthospital.app',
                maxZoom: 19,
              ),
              MarkerLayer(markers: _buildMarkers(context)),
            ],
          ),

          // Map Controls (Zoom / Recenter)
          if (!widget.isMiniMap) ...[
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapControlButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom In',
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildMapControlButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom Out',
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildMapControlButton(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'Fit all markers',
                    onPressed: _fitBounds,
                  ),
                ],
              ),
            ),

            // Top-Left Map Legend
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: _buildMapLegend(),
            ),
          ],

          // Desktop Floating Detail Card
          if (isDesktop && !widget.isMiniMap) ...[
            if (_selectedSuitable != null)
              Positioned(
                left: AppSpacing.lg,
                bottom: AppSpacing.lg,
                width: 380,
                child: _buildSuitablePopupCard(context, _selectedSuitable!),
              )
            else if (_selectedExcluded != null)
              Positioned(
                left: AppSpacing.lg,
                bottom: AppSpacing.lg,
                width: 380,
                child: _buildExcludedPopupCard(context, _selectedExcluded!),
              )
            else if (_selectedAdmin != null)
              Positioned(
                left: AppSpacing.lg,
                bottom: AppSpacing.lg,
                width: 380,
                child: _buildAdminPopupCard(context, _selectedAdmin!),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapLegend() {
    if (widget.adminHospitals != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.95),
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendDot(AppColors.black, '< 70%'),
            const SizedBox(width: 10),
            _buildLegendDot(AppColors.amber, '70–90%'),
            const SizedBox(width: 10),
            _buildLegendDot(AppColors.primaryRed, '> 90% Occupancy'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendDot(AppColors.blue, 'You'),
          const SizedBox(width: 10),
          _buildLegendDot(AppColors.primaryRed, 'Suitable'),
          const SizedBox(width: 10),
          _buildLegendDot(AppColors.textSecondary, 'Excluded'),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.label(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: AppColors.ink),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>[];
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    // 1. User Location (Blue Pulsing Marker)
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          point: widget.userLocation!,
          width: 46,
          height: 46,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42 * _pulseAnimation.value,
                    height: 42 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(
                        alpha: (1.0 - _pulseAnimation.value).clamp(0.1, 0.5),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // 2. Admin Hospitals Mode
    if (widget.adminHospitals != null) {
      for (final h in widget.adminHospitals!) {
        if (h.latitude != null && h.longitude != null) {
          final occ = h.overallOccupancyPercent;
          Color pinColor;
          if (occ >= 90) {
            pinColor = AppColors.primaryRed;
          } else if (occ >= 70) {
            pinColor = AppColors.amber;
          } else {
            pinColor = AppColors.black;
          }

          markers.add(
            Marker(
              point: LatLng(h.latitude!, h.longitude!),
              width: 40,
              height: 46,
              child: GestureDetector(
                onTap: () {
                  if (isDesktop) {
                    setState(() {
                      _selectedAdmin = h;
                      _selectedSuitable = null;
                      _selectedExcluded = null;
                    });
                  } else {
                    _showAdminBottomSheet(context, h);
                  }
                },
                child: _buildHospitalPin(
                  color: pinColor,
                  label: '${occ.round()}%',
                  isLarge: false,
                ),
              ),
            ),
          );
        }
      }
      return markers;
    }

    // 3. Excluded Hospitals (Grey Pins)
    for (final h in widget.excludedHospitals) {
      if (h.latitude != null && h.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(h.latitude!, h.longitude!),
            width: 34,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (isDesktop) {
                  setState(() {
                    _selectedExcluded = h;
                    _selectedSuitable = null;
                    _selectedAdmin = null;
                  });
                } else {
                  _showExcludedBottomSheet(context, h);
                }
              },
              child: _buildHospitalPin(
                color: AppColors.textSecondary,
                icon: Icons.block_rounded,
                isLarge: false,
              ),
            ),
          ),
        );
      }
    }

    // 4. Suitable Hospitals (Red Pins, #1 is larger with #1 badge)
    for (int i = 0; i < widget.suitableHospitals.length; i++) {
      final h = widget.suitableHospitals[i];
      if (h.latitude != null && h.longitude != null) {
        final isBest = i == 0;
        final rankLabel = '#${i + 1}';

        markers.add(
          Marker(
            point: LatLng(h.latitude!, h.longitude!),
            width: isBest ? 48 : 38,
            height: isBest ? 54 : 44,
            child: GestureDetector(
              onTap: () {
                widget.onSelectHospital?.call(h);
                if (isDesktop) {
                  setState(() {
                    _selectedSuitable = h;
                    _selectedExcluded = null;
                    _selectedAdmin = null;
                  });
                } else {
                  _showSuitableBottomSheet(context, h);
                }
              },
              child: _buildHospitalPin(
                color: AppColors.primaryRed,
                label: rankLabel,
                isLarge: isBest,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildHospitalPin({
    required Color color,
    String? label,
    IconData? icon,
    bool isLarge = false,
  }) {
    final size = isLarge ? 44.0 : 34.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: isLarge ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: label != null
                ? Text(
                    label,
                    style: AppTypography.display(
                      fontSize: isLarge ? 13 : 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  )
                : Icon(
                    icon ?? Icons.local_hospital_rounded,
                    size: isLarge ? 22 : 16,
                    color: AppColors.white,
                  ),
          ),
        ),
        // Pin pointer tip
        CustomPaint(
          size: const Size(10, 6),
          painter: _PinTipPainter(color: color),
        ),
      ],
    );
  }

  // --- Popup Cards & Bottom Sheets ---

  Widget _buildSuitablePopupCard(BuildContext context, HospitalMatchItem h) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h.name,
                  style: AppTypography.headingSmall(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedSuitable = null),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            h.address,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              MatchRing(score: h.matchPercent, size: 48, strokeWidth: 4),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.near_me_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${h.distanceKm.toStringAsFixed(1)} km',
                          style: AppTypography.bodySmall(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${h.estimatedTravelMinutes.round()} mins',
                          style: AppTypography.bodySmall(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildResourceAvailabilityPills(h.capacities),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Navigate',
                  icon: Icons.directions_rounded,
                  variant: AppButtonVariant.secondary,
                  height: 42,
                  fontSize: 13,
                  onPressed: () {
                    if (h.latitude != null && h.longitude != null) {
                      MapService.openInGoogleMaps(h.latitude!, h.longitude!, h.name);
                    }
                  },
                ),
              ),
              if (widget.onRequestHospital != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: 'Send Request',
                    icon: Icons.send_rounded,
                    height: 42,
                    fontSize: 13,
                    onPressed: () => widget.onRequestHospital!(h),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcludedPopupCard(BuildContext context, HospitalExcludedItem h) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h.name,
                  style: AppTypography.headingSmall(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedExcluded = null),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            h.address,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.redTint,
              borderRadius: AppRadius.radiusSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    h.exclusionReason,
                    style: AppTypography.bodySmall(color: AppColors.redDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Navigate to Hospital',
            icon: Icons.directions_rounded,
            variant: AppButtonVariant.secondary,
            height: 40,
            fontSize: 13,
            onPressed: () {
              if (h.latitude != null && h.longitude != null) {
                MapService.openInGoogleMaps(h.latitude!, h.longitude!, h.name);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPopupCard(BuildContext context, AdminHospitalItem h) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h.name,
                  style: AppTypography.headingSmall(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedAdmin = null),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            h.address,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL OCCUPANCY',
                      style: AppTypography.label(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${h.overallOccupancyPercent.toStringAsFixed(1)}%',
                      style: AppTypography.statNumber(fontSize: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ICU OCCUPANCY',
                      style: AppTypography.label(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${h.icuOccupancyPercent.toStringAsFixed(1)}%',
                      style: AppTypography.statNumber(
                        fontSize: 22,
                        color: h.icuOccupancyPercent > 80 ? AppColors.primaryRed : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Navigate to Facility',
            icon: Icons.directions_rounded,
            variant: AppButtonVariant.secondary,
            height: 40,
            fontSize: 13,
            onPressed: () {
              if (h.latitude != null && h.longitude != null) {
                MapService.openInGoogleMaps(h.latitude!, h.longitude!, h.name);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSuitableBottomSheet(BuildContext context, HospitalMatchItem h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.name,
                          style: AppTypography.headingMedium(color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h.address,
                          style: AppTypography.bodySmall(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  MatchRing(score: h.matchPercent, size: 52),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.near_me_rounded, size: 16, color: AppColors.primaryRed),
                  const SizedBox(width: 6),
                  Text(
                    '${h.distanceKm.toStringAsFixed(1)} km away',
                    style: AppTypography.bodyMedium(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primaryRed),
                  const SizedBox(width: 6),
                  Text(
                    '~${h.estimatedTravelMinutes.round()} mins driving',
                    style: AppTypography.bodyMedium(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildResourceAvailabilityPills(h.capacities),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Navigate',
                      icon: Icons.directions_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        Navigator.pop(context);
                        if (h.latitude != null && h.longitude != null) {
                          MapService.openInGoogleMaps(h.latitude!, h.longitude!, h.name);
                        }
                      },
                    ),
                  ),
                  if (widget.onRequestHospital != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        text: 'Send Request',
                        icon: Icons.send_rounded,
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onRequestHospital!(h);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExcludedBottomSheet(BuildContext context, HospitalExcludedItem h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.name,
                style: AppTypography.headingMedium(color: AppColors.ink),
              ),
              Text(
                h.address,
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              StatusChip(status: h.exclusionReason),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Navigate to Hospital',
                icon: Icons.directions_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.pop(context);
                  if (h.latitude != null && h.longitude != null) {
                    MapService.openInGoogleMaps(h.latitude!, h.longitude!, h.name);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminBottomSheet(BuildContext context, AdminHospitalItem h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.name,
                style: AppTypography.headingMedium(color: AppColors.ink),
              ),
              Text(
                h.address,
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OVERALL OCCUPANCY', style: AppTypography.label(fontSize: 10)),
                        Text('${h.overallOccupancyPercent.toStringAsFixed(1)}%', style: AppTypography.statNumber(fontSize: 24)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ICU OCCUPANCY', style: AppTypography.label(fontSize: 10)),
                        Text('${h.icuOccupancyPercent.toStringAsFixed(1)}%', style: AppTypography.statNumber(fontSize: 24)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Navigate in Google Maps',
                icon: Icons.directions_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.pop(context);
                  if (h.latitude != null && h.longitude != null) {
                    MapService.openInGoogleMaps(h.latitude!, h.longitude!, h.name);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceAvailabilityPills(Map<String, CapacityDetail> capacities) {
    final pills = <Widget>[];

    capacities.forEach((type, cap) {
      final label = type.replaceAll('_', ' ').toUpperCase();
      pills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cap.available > 0 ? AppColors.greenTint : AppColors.redTint,
            borderRadius: AppRadius.radiusPill,
            border: Border.all(
              color: cap.available > 0 ? AppColors.green.withValues(alpha: 0.3) : AppColors.primaryRed.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$label: ${cap.available} avail',
            style: AppTypography.label(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cap.available > 0 ? AppColors.greenDark : AppColors.redDark,
            ),
          ),
        ),
      );
    });

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: pills,
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;

  _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
