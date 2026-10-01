import 'package:flutter/material.dart';
import '../../models/admin_hospital_item.dart';
import '../../services/admin_service.dart';

class AdminHospitalsTab extends StatefulWidget {
  final AdminService adminService;

  const AdminHospitalsTab({super.key, required this.adminService});

  @override
  State<AdminHospitalsTab> createState() => _AdminHospitalsTabState();
}

class _AdminHospitalsTabState extends State<AdminHospitalsTab> {
  List<AdminHospitalItem> _hospitals = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchHospitals(showLoading: true);
  }

  Future<void> _fetchHospitals({required bool showLoading}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final items = await widget.adminService.getAllHospitals();
      if (mounted) {
        setState(() {
          _hospitals = items;
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

  Future<void> _handleUpdateVerification(String hospitalId, String newStatus) async {
    setState(() => _processingIds.add(hospitalId));
    try {
      await widget.adminService.verifyHospital(hospitalId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hospital verification status updated to $newStatus.'),
            backgroundColor: newStatus == 'verified' ? Colors.green : Colors.orange,
          ),
        );
        _fetchHospitals(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update hospital status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(hospitalId));
      }
    }
  }

  Color _getVerificationColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatLastUpdated(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'No updates recorded';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} mins ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00796B)),
            SizedBox(height: 16),
            Text('Loading Hospitals List...', style: TextStyle(color: Colors.teal)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load hospitals list', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _fetchHospitals(showLoading: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hospitals.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchHospitals(showLoading: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: const Text('No registered hospitals found in system.'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchHospitals(showLoading: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _hospitals.length,
        itemBuilder: (context, index) {
          final hosp = _hospitals[index];
          final isProcessing = _processingIds.contains(hosp.id);
          final verColor = _getVerificationColor(hosp.verificationStatus);

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
                      Expanded(
                        child: Text(
                          hosp.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          hosp.verificationStatus.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        backgroundColor: verColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address & Contact
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hosp.address,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        hosp.contact,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Account Status & Last Capacity Update
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Account: ${hosp.accountStatus.toUpperCase()}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.history, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Last update: ${_formatLastUpdated(hosp.lastCapacityUpdate)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action buttons: Verify / Reject
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (isProcessing || hosp.verificationStatus == 'verified')
                              ? null
                              : () => _handleUpdateVerification(hosp.id, 'verified'),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Verify Hospital'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (isProcessing || hosp.verificationStatus == 'rejected')
                              ? null
                              : () => _handleUpdateVerification(hosp.id, 'rejected'),
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text('Reject Hospital'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
