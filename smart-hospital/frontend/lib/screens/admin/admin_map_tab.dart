import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/admin_hospital_item.dart';
import '../../services/admin_service.dart';
import '../../widgets/widgets.dart';

class AdminMapTab extends StatefulWidget {
  final AdminService adminService;

  const AdminMapTab({super.key, required this.adminService});

  @override
  State<AdminMapTab> createState() => _AdminMapTabState();
}

class _AdminMapTabState extends State<AdminMapTab> {
  List<AdminHospitalItem> _hospitals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.adminService.getAllHospitals();
      if (mounted) {
        setState(() {
          _hospitals = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
              Text('Failed to load hospital facilities', style: AppTypography.headingSmall()),
              const SizedBox(height: AppSpacing.xs),
              Text(_error!, style: AppTypography.bodySmall(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Retry Loading',
                isFullWidth: false,
                height: 44,
                onPressed: _fetchHospitals,
              ),
            ],
          ),
        ),
      );
    }

    int criticalCount = 0;
    int warningCount = 0;
    int normalCount = 0;

    for (final h in _hospitals) {
      if (h.overallOccupancyPercent >= 90) {
        criticalCount++;
      } else if (h.overallOccupancyPercent >= 70) {
        warningCount++;
      } else {
        normalCount++;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Quick Occupancy Telemetry Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildStatusStat('TOTAL FACILITIES', '${_hospitals.length}', AppColors.ink),
                        const SizedBox(width: AppSpacing.xl),
                        _buildStatusStat('CRITICAL (>90%)', '$criticalCount', AppColors.primaryRed),
                        const SizedBox(width: AppSpacing.xl),
                        _buildStatusStat('HIGH (70-90%)', '$warningCount', AppColors.amber),
                        const SizedBox(width: AppSpacing.xl),
                        _buildStatusStat('NORMAL (<70%)', '$normalCount', AppColors.greenDark),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh Telemetry',
                    onPressed: _fetchHospitals,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Interactive Full Map
            Expanded(
              child: HospitalMap(
                adminHospitals: _hospitals,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label(fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.statNumber(fontSize: 18, color: color),
        ),
      ],
    );
  }
}
