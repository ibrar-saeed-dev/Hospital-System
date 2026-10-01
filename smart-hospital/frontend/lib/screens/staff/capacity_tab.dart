import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/capacity_item.dart';
import '../../services/staff_service.dart';

class CapacityTab extends StatefulWidget {
  final StaffService staffService;

  const CapacityTab({super.key, required this.staffService});

  @override
  State<CapacityTab> createState() => _CapacityTabState();
}

class _CapacityTabState extends State<CapacityTab> {
  List<CapacityItem> _capacities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCapacity();
  }

  Future<void> _fetchCapacity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.staffService.getMyHospitalCapacity();
      setState(() {
        _capacities = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatResourceName(String type) {
    switch (type.toLowerCase()) {
      case 'icu_bed':
        return 'ICU Beds';
      case 'ventilator':
        return 'Ventilators';
      case 'emergency_bed':
        return 'Emergency Beds';
      case 'general_bed':
        return 'General Beds';
      case 'nicu_bed':
        return 'NICU Beds';
      case 'operation_theatre':
        return 'Operation Theatres';
      case 'isolation_bed':
        return 'Isolation Beds';
      case 'dialysis':
        return 'Dialysis Units';
      case 'trauma':
        return 'Trauma Care';
      case 'ambulance':
        return 'Ambulances';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'icu_bed':
        return Icons.hotel_class_rounded;
      case 'ventilator':
        return Icons.air_rounded;
      case 'emergency_bed':
        return Icons.emergency_rounded;
      case 'general_bed':
        return Icons.bed_rounded;
      case 'nicu_bed':
        return Icons.child_care_rounded;
      case 'operation_theatre':
        return Icons.medical_services_rounded;
      case 'isolation_bed':
        return Icons.single_bed_rounded;
      case 'dialysis':
        return Icons.water_drop_rounded;
      case 'trauma':
        return Icons.local_hospital_rounded;
      case 'ambulance':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getOccupancyColor(double percent) {
    if (percent > 90.0) return Colors.red;
    if (percent >= 70.0) return Colors.orange;
    return Colors.green;
  }

  void _openEditDialog(CapacityItem item) {
    final totalController = TextEditingController(text: item.total.toString());
    final occupiedController = TextEditingController(text: item.occupied.toString());
    final tempController = TextEditingController(text: item.temporarilyUnavailable.toString());
    final formKey = GlobalKey<FormState>();

    bool isUpdating = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(_getResourceIcon(item.resourceType), color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Edit ${_formatResourceName(item.resourceType)}')),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      TextFormField(
                        controller: totalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Capacity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null) {
                            return 'Enter valid integer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: occupiedController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Occupied',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null) {
                            return 'Enter valid integer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tempController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Temporarily Unavailable',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null) {
                            return 'Enter valid integer';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isUpdating = true;
                              dialogError = null;
                            });

                            try {
                              await widget.staffService.updateCapacity(
                                item.resourceType,
                                total: int.parse(totalController.text),
                                occupied: int.parse(occupiedController.text),
                                temporarilyUnavailable: int.parse(tempController.text),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                _fetchCapacity();
                              }
                            } on DioException catch (err) {
                              setDialogState(() {
                                isUpdating = false;
                                dialogError = err.error?.toString() ?? "Validation failed";
                              });
                            } catch (err) {
                              setDialogState(() {
                                isUpdating = false;
                                dialogError = err.toString();
                              });
                            }
                          }
                        },
                  child: isUpdating
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
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
            Text('Failed to load capacity data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchCapacity, child: const Text('Retry')),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1);

    return RefreshIndicator(
      onRefresh: _fetchCapacity,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hospital Capacity Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchCapacity,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _capacities.length,
              itemBuilder: (context, index) {
                final item = _capacities[index];
                final occPct = item.occupancyPercent;
                final occColor = _getOccupancyColor(occPct);

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(_getResourceIcon(item.resourceType), size: 20, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatResourceName(item.resourceType),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openEditDialog(item),
                              tooltip: 'Edit Capacity',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: item.total > 0 ? (item.occupied / item.total).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: Colors.grey[200],
                          color: occColor,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${occPct.toStringAsFixed(1)}% Occupied', style: TextStyle(color: occColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Available: ${item.available}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _buildStatText('Total', item.total),
                            _buildStatText('Occupied', item.occupied),
                            _buildStatText('Reserved', item.reserved),
                            _buildStatText('Unavail', item.temporarilyUnavailable),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (item.stale || item.minutesSinceUpdate > 30.0) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Capacity information may be outdated',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ] else ...[
                          Text(
                            'Updated ${item.minutesSinceUpdate.toStringAsFixed(0)} mins ago',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatText(String label, int val) {
    return Text(
      '$label: $val',
      style: const TextStyle(fontSize: 11, color: Colors.black87),
    );
  }
}
