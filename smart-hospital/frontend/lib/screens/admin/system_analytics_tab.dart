import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/analytics_models.dart';
import '../../services/analytics_service.dart';

class SystemAnalyticsTab extends StatefulWidget {
  final AnalyticsService analyticsService;

  const SystemAnalyticsTab({super.key, required this.analyticsService});

  @override
  State<SystemAnalyticsTab> createState() => _SystemAnalyticsTabState();
}

class _SystemAnalyticsTabState extends State<SystemAnalyticsTab> {
  SystemAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.analyticsService.getSystemAnalytics();
      if (mounted) {
        setState(() {
          _analytics = data;
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
            Text('Loading System Analytics...', style: TextStyle(color: Colors.teal)),
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
            Text('Failed to load system analytics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchData,
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
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat cards: total requests, average response time, stale hospitals count
            _buildStatCardsRow(data),
            const SizedBox(height: 20),

            // Top 5 Hospitals & Most Requested Resources
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTopHospitalsChart(data)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMostRequestedResourcesChart(data)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDailyRequestsLineChart(data)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStaleHospitalsList(data)),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTopHospitalsChart(data),
                      const SizedBox(height: 20),
                      _buildMostRequestedResourcesChart(data),
                      const SizedBox(height: 20),
                      _buildDailyRequestsLineChart(data),
                      const SizedBox(height: 20),
                      _buildStaleHospitalsList(data),
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

  Widget _buildStatCardsRow(SystemAnalytics data) {
    final cards = [
      _buildStatCard('Total Requests', '${data.totalRequests}', Icons.assignment_turned_in_outlined, Colors.teal),
      _buildStatCard('Avg Resp Time', '${data.avgResponseTimeMinutes.toStringAsFixed(1)} min', Icons.timer_outlined, Colors.blue),
      _buildStatCard('Stale Data Hospitals', '${data.staleHospitals.length}', Icons.warning_amber_rounded, data.staleHospitals.isEmpty ? Colors.green : Colors.red),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 700 ? 2.5 : 3.5,
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
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal Bar Chart: Top 5 Hospitals by Occupancy
  Widget _buildTopHospitalsChart(SystemAnalytics data) {
    final topList = data.topHospitalsByOccupancy;

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
                const Icon(Icons.domain_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Hospitals by Occupancy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (topList.isEmpty)
              Container(height: 200, alignment: Alignment.center, child: const Text('No hospital occupancy data'))
            else
              Column(
                children: topList.asMap().entries.map((entry) {
                  final item = entry.value;
                  final pct = item.occupancyPercent.clamp(0.0, 100.0);
                  Color barColor = Colors.teal;
                  if (pct > 80) {
                    barColor = Colors.red;
                  } else if (pct > 60) {
                    barColor = Colors.orange;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}% (${item.totalOccupied}/${item.totalCapacity})',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct / 100.0,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Bar Chart: Most Requested Resource Types
  Widget _buildMostRequestedResourcesChart(SystemAnalytics data) {
    final list = data.mostRequestedResources;
    final maxCount = list.fold(0, (max, item) => item.count > max ? item.count : max);
    final maxY = maxCount < 5 ? 5.0 : (maxCount + 2).toDouble();

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
                const Icon(Icons.analytics_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Most Requested Resource Types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (list.isEmpty)
              Container(height: 200, alignment: Alignment.center, child: const Text('No request resources recorded'))
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = list[groupIndex];
                          return BarTooltipItem(
                            '${item.resourceType.replaceAll('_', ' ').toUpperCase()}\n${rod.toY.toInt()} requests',
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
                          reservedSize: 28,
                          getTitlesWidget: (val, meta) {
                            if (val % (maxY > 10 ? 5 : 1) == 0) {
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
                      getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: list.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: item.count.toDouble(),
                            color: Colors.teal,
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

  // Line Chart: Requests per day for last 7 days across system
  Widget _buildDailyRequestsLineChart(SystemAnalytics data) {
    final daily = data.dailyRequests;
    final maxCount = daily.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    final maxY = maxCount < 5 ? 5.0 : (maxCount + 3).toDouble();

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
                const Icon(Icons.timeline_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'System-Wide Requests (Last 7 Days)',
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
                      color: Colors.blue.shade800,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.shade800.withValues(alpha: 0.15),
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

  // List: Hospitals with outdated data
  Widget _buildStaleHospitalsList(SystemAnalytics data) {
    final list = data.staleHospitals;

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
                const Icon(Icons.access_time_filled_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Hospitals with Outdated Data (${list.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: list.isEmpty ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'All hospitals have updated capacity within 30 minutes!',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final hosp = list[index];
                  final mins = hosp.minutesSinceUpdate != null
                      ? hosp.minutesSinceUpdate!.toStringAsFixed(0)
                      : 'Unknown';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hosp.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Text(
                          'Updated $mins min ago',
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
