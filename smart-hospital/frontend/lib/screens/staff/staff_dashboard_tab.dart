import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/analytics_models.dart';
import '../../services/analytics_service.dart';

class StaffDashboardTab extends StatefulWidget {
  final AnalyticsService analyticsService;

  const StaffDashboardTab({super.key, required this.analyticsService});

  @override
  State<StaffDashboardTab> createState() => _StaffDashboardTabState();
}

class _StaffDashboardTabState extends State<StaffDashboardTab> {
  HospitalAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData(showLoading: true);
    // Auto refresh every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({required bool showLoading}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final data = await widget.analyticsService.getHospitalAnalytics();
      if (mounted) {
        setState(() {
          _analytics = data;
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

  String _formatResourceLabel(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'icu_bed':
        return 'ICU';
      case 'ventilator':
        return 'Vent';
      case 'emergency_bed':
        return 'Emerg';
      case 'general_bed':
        return 'General';
      case 'nicu_bed':
        return 'NICU';
      case 'isolation_bed':
        return 'Isol';
      case 'dialysis':
        return 'Dialysis';
      case 'trauma':
        return 'Trauma';
      case 'operation_theatre':
        return 'OT';
      case 'ambulance':
        return 'Amb';
      default:
        return resourceType.replaceAll('_', ' ');
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
            Text('Loading Hospital Dashboard...', style: TextStyle(color: Colors.teal)),
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
            Text('Failed to load dashboard metrics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _fetchData(showLoading: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_analytics == null) {
      return const Center(child: Text('No analytics data available.'));
    }

    final data = _analytics!;

    return RefreshIndicator(
      onRefresh: () => _fetchData(showLoading: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row of Stat Cards
            _buildStatCardsRow(data),
            const SizedBox(height: 20),

            // Responsive Layout for Charts
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildResourceOccupancyBarChart(data)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildRequestStatusPieChart(data)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDailyRequestsLineChart(data),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildResourceOccupancyBarChart(data),
                      const SizedBox(height: 20),
                      _buildRequestStatusPieChart(data),
                      const SizedBox(height: 20),
                      _buildDailyRequestsLineChart(data),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsRow(HospitalAnalytics data) {
    final cards = [
      _buildStatCard('Total Beds', '${data.totalBeds}', Icons.king_bed_outlined, Colors.blue),
      _buildStatCard('Occupied', '${data.occupiedBeds}', Icons.airline_seat_flat, Colors.orange),
      _buildStatCard('Available', '${data.availableBeds}', Icons.check_circle_outline, Colors.green),
      _buildStatCard('ICU Occ %', '${data.icuOccupancyPercent.toStringAsFixed(1)}%', Icons.local_hospital, Colors.red),
      _buildStatCard('Avg Resp Time', '${data.avgResponseTimeMinutes.toStringAsFixed(1)} min', Icons.timer_outlined, Colors.teal),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: cards,
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Bar Chart: Occupancy % per resource type
  Widget _buildResourceOccupancyBarChart(HospitalAnalytics data) {
    final list = data.resourceOccupancy;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Occupancy % per Resource',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (list.isEmpty)
              Container(height: 200, alignment: Alignment.center, child: const Text('No capacity data available'))
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = list[groupIndex];
                          return BarTooltipItem(
                            '${item.resourceType.replaceAll('_', ' ').toUpperCase()}\n${rod.toY.toStringAsFixed(1)}%',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (val, meta) {
                            if (val % 25 == 0) {
                              return Text('${val.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < list.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _formatResourceLabel(list[idx].resourceType),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: list.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final pct = item.occupancyPercent.clamp(0.0, 100.0);
                      Color barColor = Colors.teal;
                      if (pct > 85) {
                        barColor = Colors.red;
                      } else if (pct > 65) {
                        barColor = Colors.orange;
                      }

                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: pct,
                            color: barColor,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 2. Pie Chart: Requests by Status
  Widget _buildRequestStatusPieChart(HospitalAnalytics data) {
    final statusMap = data.requestCountsByStatus;
    final totalRequests = statusMap.values.fold(0, (a, b) => a + b);

    final statusColors = <String, Color>{
      'accepted': Colors.green,
      'rejected': Colors.red,
      'expired': Colors.orange.shade800,
      'cancelled': Colors.grey,
      'pending': Colors.blue,
      'admitted': Colors.teal.shade900,
      'patient_transferred': Colors.teal,
      'no_capacity': Colors.deepOrange,
    };

    final sections = <PieChartSectionData>[];
    statusMap.forEach((status, count) {
      if (count > 0) {
        final color = statusColors[status] ?? Colors.indigo;
        final pct = totalRequests > 0 ? (count / totalRequests * 100).toStringAsFixed(0) : '0';

        sections.add(
          PieChartSectionData(
            color: color,
            value: count.toDouble(),
            title: '$pct%',
            radius: 45,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Requests by Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalRequests == 0)
              Container(height: 200, alignment: Alignment.center, child: const Text('No request data recorded yet'))
            else
              Row(
                children: [
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 35,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: statusMap.entries.where((e) => e.value > 0).map((entry) {
                        final color = statusColors[entry.key] ?? Colors.indigo;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.key.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${entry.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 3. Line Chart: Requests per day for last 7 days
  Widget _buildDailyRequestsLineChart(HospitalAnalytics data) {
    final daily = data.dailyRequests;
    final maxCount = daily.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    final maxY = maxCount < 5 ? 5.0 : (maxCount + 2).toDouble();

    final spots = <FlSpot>[];
    for (int i = 0; i < daily.length; i++) {
      spots.add(FlSpot(i.toDouble(), daily[i].count.toDouble()));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Requests Trend (Last 7 Days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) {
                          if (val % (maxY > 10 ? 5 : 2) == 0) {
                            return Text('${val.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < daily.length) {
                            final dateParts = daily[idx].date.split('-');
                            final label = dateParts.length >= 3 ? '${dateParts[1]}/${dateParts[2]}' : daily[idx].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
