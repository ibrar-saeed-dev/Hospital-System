import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/referral_request_item.dart';
import '../../services/staff_service.dart';

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

        // Urgency priority
        int aUrgency = _urgencyPriority(a.urgency);
        int bUrgency = _urgencyPriority(b.urgency);
        if (aUrgency != bUrgency) return bUrgency.compareTo(aUrgency);

        // Created at newest first
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'patient_transferred':
        return Colors.teal;
      case 'admitted':
        return Colors.blue.shade900;
      case 'rejected':
      case 'expired':
      case 'no_capacity':
        return Colors.red;
      case 'request_sent':
      case 'hospital_reviewing':
        return Colors.orange;
      default:
        return Colors.grey;
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
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load referral requests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _fetchRequests(showLoading: true), child: const Text('Retry')),
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
            child: const Text('No incoming referral requests.'),
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
          final isProcessing = _processingIds.contains(req.id);
          final urgencyColor = _getUrgencyColor(req.urgency);
          final statusColor = _getStatusColor(req.status);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin_circle_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            req.patientReference,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(req.urgency.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        backgroundColor: urgencyColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Required Resources:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: req.requiredResources.map((res) {
                      return Chip(
                        label: Text(res.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.teal.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          req.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      if (req.isPending && req.minutesLeft > 0) ...[
                        Icon(Icons.timer_outlined, size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Text(
                          '${req.minutesLeft.toStringAsFixed(1)}m left',
                          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Actions
                  if (req.isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isProcessing ? null : () => _handleAccept(req.id),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isProcessing ? null : () => _handleReject(req.id),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (req.status == 'accepted') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : () => _handleStatusUpdate(req.id, 'patient_transferred'),
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        label: const Text('Mark Patient Transferred'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else if (req.status == 'patient_transferred') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : () => _handleStatusUpdate(req.id, 'admitted'),
                        icon: const Icon(Icons.hotel_rounded, size: 18),
                        label: const Text('Mark Patient Admitted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
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
