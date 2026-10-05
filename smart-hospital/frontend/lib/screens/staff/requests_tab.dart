import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/referral_request_item.dart';
import '../../services/map_service.dart';
import '../../services/staff_service.dart';
import '../../widgets/widgets.dart';

class RequestsTab extends StatefulWidget {
  final StaffService staffService;

  const RequestsTab({super.key, required this.staffService});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  List<ReferralRequestItem> _requests = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests(showLoading: true);
    // Auto-refresh every 4 seconds
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
      final items = await widget.staffService.getHospitalRequests();

      // Sort: Pending requests first, critical urgency on top
      items.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;

        int aUrgency = _urgencyPriority(a.urgency);
        int bUrgency = _urgencyPriority(b.urgency);
        if (aUrgency != bUrgency) return bUrgency.compareTo(aUrgency);

        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      });

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

  int _urgencyPriority(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
      default:
        return 1;
    }
  }

  Future<void> _handleAccept(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await widget.staffService.acceptRequest(id);
      _fetchRequests(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept referral request: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _handleReject(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await widget.staffService.rejectRequest(id);
      _fetchRequests(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject referral request: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _handleStatusUpdate(String id, String newStatus) async {
    setState(() => _processingIds.add(id));
    try {
      await widget.staffService.updateRequestStatus(id, newStatus);
      _fetchRequests(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
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
                text: 'Retry',
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
            icon: Icons.move_to_inbox_rounded,
            title: 'No Inbound Requests',
            message: 'There are currently no inbound patient referral requests for your hospital facility.',
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
          final isProcessing = _processingIds.contains(req.id);
          final patLat = req.latitude ?? 25.3960;
          final patLng = req.longitude ?? 68.3578;

          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Patient Reference + Urgency + Status
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
                    Row(
                      children: [
                        StatusChip(status: req.urgency),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(status: req.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Required Clinical Resources
                Text(
                  'REQUESTED RESOURCES',
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
                const SizedBox(height: AppSpacing.md),

                // Location info & Expiry
                Row(
                  children: [
                    // Small "Patient Location" button to open Google Maps
                    AppButton(
                      text: 'Patient Location',
                      icon: Icons.pin_drop_rounded,
                      variant: AppButtonVariant.secondary,
                      isFullWidth: false,
                      height: 34,
                      fontSize: 11,
                      onPressed: () {
                        MapService.openLocationInGoogleMaps(patLat, patLng);
                      },
                    ),
                    const Spacer(),
                    if (req.isPending && req.minutesLeft > 0) ...[
                      const Icon(Icons.timer_outlined, size: 15, color: AppColors.amberDark),
                      const SizedBox(width: 4),
                      Text(
                        '${req.minutesLeft.toStringAsFixed(1)} mins left',
                        style: AppTypography.label(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberDark,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Workflow Action Buttons
                if (req.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Accept Referral',
                          icon: Icons.check_rounded,
                          isLoading: isProcessing,
                          height: 44,
                          fontSize: 13,
                          onPressed: () => _handleAccept(req.id),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          text: 'Reject Referral',
                          icon: Icons.close_rounded,
                          variant: AppButtonVariant.danger,
                          isLoading: isProcessing,
                          height: 44,
                          fontSize: 13,
                          onPressed: () => _handleReject(req.id),
                        ),
                      ),
                    ],
                  ),
                ] else if (req.status == 'accepted') ...[
                  AppButton(
                    text: 'Mark Patient In-Transit / Dispatched',
                    icon: Icons.local_shipping_rounded,
                    isLoading: isProcessing,
                    height: 44,
                    fontSize: 13,
                    onPressed: () => _handleStatusUpdate(req.id, 'patient_transferred'),
                  ),
                ] else if (req.status == 'patient_transferred') ...[
                  AppButton(
                    text: 'Confirm Patient Admitted',
                    icon: Icons.hotel_rounded,
                    isLoading: isProcessing,
                    height: 44,
                    fontSize: 13,
                    onPressed: () => _handleStatusUpdate(req.id, 'admitted'),
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
