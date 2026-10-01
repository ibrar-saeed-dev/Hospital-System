import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/referral_request_item.dart';
import '../../services/patient_service.dart';

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
    // Auto refresh every 4 seconds
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
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this referral request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
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
            content: Text('Request cancelled successfully.'),
            backgroundColor: Colors.grey,
          ),
        );
        _fetchRequests(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cancellingIds.remove(requestId));
      }
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange.shade800;
      case 'medium':
        return Colors.blue;
      case 'low':
      default:
        return Colors.grey;
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

    // Terminal/Error statuses
    if (activeIndex == -1) {
      Color color = Colors.grey;
      String text = currentStatus.replaceAll('_', ' ').toUpperCase();

      if (currentStatus == 'rejected' || currentStatus == 'expired' || currentStatus == 'no_capacity') {
        color = Colors.red;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentStatus == 'cancelled' ? Icons.cancel_outlined : Icons.error_outline_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // 4-step timeline: Request Sent -> Accepted -> Patient Transferred -> Admitted
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
                          ? (isCurrent ? Colors.teal : Colors.green)
                          : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < activeIndex ? Colors.green : Colors.grey.shade300,
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.teal : Colors.grey.shade700,
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00796B)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load your requests',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _fetchRequests(showLoading: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchRequests(showLoading: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No referral requests submitted yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchRequests(showLoading: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          final isCancelling = _cancellingIds.contains(req.id);
          final urgencyColor = _getUrgencyColor(req.urgency);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Ref & Urgency Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin_circle_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            req.patientReference,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(
                          req.urgency.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: urgencyColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Hospital Name
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_outlined, size: 18, color: Colors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          req.hospitalName ?? 'Hospital ID: ${req.selectedHospitalId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Required Resources Chips
                  const Text('Required Resources:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: req.requiredResources.map((res) {
                      return Chip(
                        label: Text(
                          res.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.teal.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Countdown timer if pending
                  if (req.isPending && req.minutesLeft > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: Colors.orange.shade800),
                          const SizedBox(width: 6),
                          Text(
                            'Reservation expires in: ${req.minutesLeft.toStringAsFixed(1)} min',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Status Stepper / Timeline
                  const Text('Request Timeline:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildStatusStepper(req.status),
                  const SizedBox(height: 14),

                  // Cancel Button for Pending Requests
                  if (req.isPending) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isCancelling ? null : () => _handleCancelRequest(req.id),
                        icon: isCancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                              )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(isCancelling ? 'Cancelling...' : 'Cancel Request'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
