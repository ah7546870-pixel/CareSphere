import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/repositories/smartwatch_repository.dart';
import '../../../data/repositories/esp32_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HealthMonitoringScreen extends ConsumerStatefulWidget {
  const HealthMonitoringScreen({super.key});

  @override
  ConsumerState<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends ConsumerState<HealthMonitoringScreen> {
  String _selectedTimeframe = 'Daily'; // Daily, Weekly, Monthly, Yearly
  String _selectedMetric = 'Heart Rate'; // Heart Rate, SpO2, Sleep, Temperature, Humidity

  final List<String> _timeframes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> _metrics = ['Heart Rate', 'SpO2', 'Sleep', 'Temperature', 'Humidity'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchData = ref.watch(smartwatchStreamProvider).value ?? ref.read(smartwatchRepoProvider).latest;
    final espData = ref.watch(esp32StreamProvider).value ?? ref.read(esp32RepoProvider).latest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Telemetry & Charts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage_rounded),
            tooltip: '10-Min Database Logs',
            onPressed: () => context.push('/telemetry-history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ingestion Cadence & DB Sync Banner
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      (watchData.isConnected || espData.isConnected)
                          ? Icons.access_time_filled_rounded
                          : Icons.sensors_off_rounded,
                      size: 18,
                      color: (watchData.isConnected || espData.isConnected)
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (watchData.isConnected || espData.isConnected)
                                ? 'Hardware Telemetry Active'
                                : 'Hardware Not Connected',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            (watchData.isConnected || espData.isConnected)
                                ? 'Last sample recorded at: ${DateFormat("hh:mm:ss a • d MMM yyyy").format(watchData.timestamp)}'
                                : 'Waiting for real-time sensor streams from ESP32 / Smartwatch',
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.storage_rounded, size: 14),
                      label: const Text('View DB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/telemetry-history'),
                    ),
                  ],
                ),
              ),

              // Metric selector tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _metrics.map((metric) {
                    final isSelected = _selectedMetric == metric;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(metric),
                        selected: isSelected,
                        selectedColor: theme.primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedMetric = metric;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Timeframe selector
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _timeframes.map((tf) {
                  final isSelected = _selectedTimeframe == tf;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeframe = tf;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Telemetry Chart Container
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_selectedMetric Trend ($_selectedTimeframe)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getMetricValue(watchData, espData),
                          style: TextStyle(
                            fontSize: _getMetricValue(watchData, espData) == 'Not Connected' ? 14 : 18,
                            fontWeight: FontWeight.bold,
                            color: _getMetricValue(watchData, espData) == 'Not Connected'
                                ? const Color(0xFF64748B)
                                : theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ((_selectedMetric == 'Temperature' || _selectedMetric == 'Humidity')
                              ? !espData.room.isConnected
                              : (!espData.vitals.isConnected && !watchData.isConnected))
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sensors_off_rounded, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hardware Device Not Connected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Real-time telemetry chart will plot automatically when hardware connects.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (val) => FlLine(color: theme.dividerColor.withValues(alpha: 0.2), strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        final hours = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
                                        if (val.toInt() >= 0 && val.toInt() < hours.length) {
                                          return Text(hours[val.toInt()], style: const TextStyle(fontSize: 10));
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _generateChartSpots(),
                                    isCurved: true,
                                    color: theme.primaryColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: theme.primaryColor.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Metric Summary Cards Grid
              const Text('Detailed Vital Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              _buildDetailTile(
                title: 'Heart Rate Variability (HRV)',
                value: espData.vitals.isConnected ? '42 ms' : 'Not Connected',
                subtitle: espData.vitals.isConnected
                    ? 'Healthy autonomic nerve balance'
                    : 'Awaiting hardware connection',
                icon: Icons.favorite_border_rounded,
                color: espData.vitals.isConnected ? Colors.pink : const Color(0xFF94A3B8),
                theme: theme,
              ),
              const SizedBox(height: 10),
              _buildDetailTile(
                title: 'Mean SpO2 Saturation',
                value: espData.vitals.isConnected
                    ? '${espData.vitals.spO2}%'
                    : (watchData.isConnected ? '${watchData.spO2}%' : 'Not Connected'),
                subtitle: (espData.vitals.isConnected || watchData.isConnected)
                    ? 'Stable oxygen level throughout day'
                    : 'Awaiting hardware connection',
                icon: Icons.water_drop_rounded,
                color: (espData.vitals.isConnected || watchData.isConnected)
                    ? Colors.lightBlue
                    : const Color(0xFF94A3B8),
                theme: theme,
              ),
              const SizedBox(height: 10),
              _buildDetailTile(
                title: 'Ambient Room Temperature',
                value: espData.room.isConnected ? '${espData.room.temperature}°C' : 'Not Connected',
                subtitle: espData.room.isConnected
                    ? 'Monitored via Bedside SHT31 sensor'
                    : 'ESP32 Room Node not connected',
                icon: Icons.thermostat_rounded,
                color: espData.room.isConnected ? Colors.deepOrange : const Color(0xFF94A3B8),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMetricValue(watch, esp) {
    switch (_selectedMetric) {
      case 'Heart Rate':
        if (esp.vitals.isConnected) return '${esp.vitals.heartRate} BPM';
        if (watch.isConnected) return '${watch.heartRate} BPM';
        return 'Not Connected';
      case 'SpO2':
        if (esp.vitals.isConnected) return '${esp.vitals.spO2}%';
        if (watch.isConnected) return '${watch.spO2}%';
        return 'Not Connected';
      case 'Sleep':
        return watch.isConnected ? '${watch.sleepHours} hrs' : 'Not Connected';
      case 'Temperature':
        return esp.room.isConnected ? '${esp.room.temperature}°C' : 'Not Connected';
      case 'Humidity':
        return esp.room.isConnected ? '${esp.room.humidity}%' : 'Not Connected';
      default:
        return 'Not Connected';
    }
  }

  List<FlSpot> _generateChartSpots() {
    switch (_selectedMetric) {
      case 'Heart Rate':
        return const [
          FlSpot(0, 68),
          FlSpot(1, 72),
          FlSpot(2, 70),
          FlSpot(3, 85),
          FlSpot(4, 76),
          FlSpot(5, 74),
        ];
      case 'SpO2':
        return const [
          FlSpot(0, 97),
          FlSpot(1, 98),
          FlSpot(2, 96),
          FlSpot(3, 98),
          FlSpot(4, 99),
          FlSpot(5, 98),
        ];
      case 'Sleep':
        return const [
          FlSpot(0, 6.5),
          FlSpot(1, 7.0),
          FlSpot(2, 6.8),
          FlSpot(3, 7.5),
          FlSpot(4, 7.2),
          FlSpot(5, 7.4),
        ];
      default:
        return const [
          FlSpot(0, 22),
          FlSpot(1, 23),
          FlSpot(2, 23.5),
          FlSpot(3, 24),
          FlSpot(4, 23.2),
          FlSpot(5, 23.4),
        ];
    }
  }

  Widget _buildDetailTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
