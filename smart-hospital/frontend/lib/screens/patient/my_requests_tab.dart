import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_theme.dart';
import '../../models/referral_request_item.dart';
import '../../models/hospital_search_result.dart';
import '../../services/map_service.dart';
import '../../services/patient_service.dart';
import '../../widgets/widgets.dart';

class MyRequestsTab extends StatefulWidget {
  final PatientService patientService;

  const MyRequestsTab({super.key, required this.patientService});

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  List<ReferralRequestItem> _requests = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  final Set<String> _cancellingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests(showLoading: true);
    // Auto-refresh every 4 seconds for live status updates
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchRequests(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRequests({required bool showLoading}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final items = await widget.patientService.getMyRequests();
      if (mounted) {
        setState(() {
          _requests = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCancelRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Text('Cancel Referral Request', style: AppTypography.headingSmall()),
        content: Text(
          'Are you sure you want to cancel this bed reservation request? Reserved clinical capacity will be released back to the network.',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep Request', style: AppTypography.bodyMedium(color: AppColors.textSecondary)),
          ),
          SizedBox(
            width: 140,
            child: AppButton(
              text: 'Yes, Cancel',
              variant: AppButtonVariant.danger,
              height: 42,
              fontSize: 13,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancellingIds.add(requestId));
    try {
      await widget.patientService.cancelRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral request cancelled successfully.'),
            backgroundColor: AppColors.ink,
          ),
        );
        _fetchRequests(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cancellingIds.remove(requestId));
      }
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'request_sent':
      case 'hospital_reviewing':
        return 0;
      case 'accepted':
        return 1;
      case 'patient_transferred':
        return 2;
      case 'admitted':
        return 3;
      default:
        return -1;
    }
  }

  Widget _buildStatusStepper(String currentStatus) {
    final activeIndex = _getStatusStepIndex(currentStatus);

    if (activeIndex == -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.redTint,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cancel_rounded,
              color: AppColors.primaryRed,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              currentStatus.replaceAll('_', ' ').toUpperCase(),
              style: AppTypography.label(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ],
        ),
      );
    }

    final steps = ['Request Sent', 'Accepted', 'Transferred', 'Admitted'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final isCompleted = index <= activeIndex;
            final isCurrent = index == activeIndex;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? (isCurrent ? AppColors.primaryRed : AppColors.green)
                          : AppColors.border,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white)
                          : Text(
                              '${index + 1}',
                              style: AppTypography.label(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < activeIndex ? AppColors.green : AppColors.border,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isCurrent = index == activeIndex;
            return Expanded(
              child: Text(
                steps[index],
                textAlign: TextAlign.center,
                style: AppTypography.label(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent ? AppColors.primaryRed : AppColors.textSecondary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: SkeletonListPlaceholder(count: 3, itemHeight: 180),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.primaryRed),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load referral requests', style: AppTypography.headingSmall()),
              const SizedBox(height: AppSpacing.xs),
              Text(_error!, style: AppTypography.bodySmall(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Retry Loading',
                isFullWidth: false,
                height: 44,
                onPressed: () => _fetchRequests(showLoading: true),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchRequests(showLoading: true),
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Active Requests',
            message:
                'You have not submitted any patient referral requests. Search hospitals to initiate a dispatch.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchRequests(showLoading: true),
      color: AppColors.primaryRed,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _requests.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final req = _requests[index];
          final isCancelling = _cancellingIds.contains(req.id);
          final isAcceptedOrActive = req.status == 'accepted' ||
              req.status == 'patient_transferred' ||
              req.status == 'admitted';

          final hospLat = req.hospitalLatitude ?? req.latitude ?? 25.3960;
          final hospLng = req.hospitalLongitude ?? req.longitude ?? 68.3578;
          final hospName = req.hospitalName ?? 'Assigned Medical Facility';

          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Reference & Urgency Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.12),
                            borderRadius: AppRadius.radiusSm,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: AppColors.primaryRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          req.patientReference,
                          style: AppTypography.headingSmall(),
                        ),
                      ],
                    ),
                    StatusChip(status: req.urgency),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Destination Hospital Name & Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_hospital_rounded,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospName,
                            style: AppTypography.bodyMedium(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          if (req.hospitalAddress != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              req.hospitalAddress!,
                              style: AppTypography.bodySmall(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Required Resource Badges
                Text(
                  'REQUIRED CLINICAL RESOURCES',
                  style: AppTypography.label(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: req.requiredResources.map((res) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppRadius.radiusPill,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        res.replaceAll('_', ' ').toUpperCase(),
                        style: AppTypography.label(fontSize: 10, color: AppColors.ink),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Countdown timer if pending
                if (req.isPending && req.minutesLeft > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.amberTint,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: AppColors.amberDark),
                        const SizedBox(width: 8),
                        Text(
                          'Temporary reservation active: ${req.minutesLeft.toStringAsFixed(1)} mins remaining',
                          style: AppTypography.label(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Request Timeline Stepper
                Text(
                  'DISPATCH LIFECYCLE',
                  style: AppTypography.label(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStatusStepper(req.status),

                // Mini Map & Big Red Navigation Button for Accepted/Active requests
                if (isAcceptedOrActive) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    children: [
                      const Icon(Icons.navigation_rounded, color: AppColors.primaryRed, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'FACILITY ROUTING & DIRECTIONS',
                        style: AppTypography.label(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Mini Map
                  SizedBox(
                    height: 180,
                    child: HospitalMap(
                      isMiniMap: true,
                      initialCenter: LatLng(hospLat, hospLng),
                      initialZoom: 14.5,
                      suitableHospitals: [
                        HospitalMatchItem(
                          hospitalId: req.selectedHospitalId,
                          name: hospName,
                          address: req.hospitalAddress ?? '',
                          contact: '',
                          latitude: hospLat,
                          longitude: hospLng,
                          distanceKm: 0,
                          estimatedTravelMinutes: 0,
                          matchPercent: 100,
                          capacities: {},
                          stale: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Big Red "Navigate to Hospital" Button
                  AppButton(
                    text: 'Navigate to $hospName',
                    icon: Icons.directions_car_rounded,
                    height: 52,
                    fontSize: 15,
                    onPressed: () {
                      MapService.openInGoogleMaps(hospLat, hospLng, hospName);
                    },
                  ),
                ],

                // Cancel Request Button for Pending
                if (req.isPending) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Cancel Reservation Request',
                    icon: Icons.cancel_outlined,
                    variant: AppButtonVariant.danger,
                    isLoading: isCancelling,
                    height: 46,
                    fontSize: 13,
                    onPressed: () => _handleCancelRequest(req.id),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
