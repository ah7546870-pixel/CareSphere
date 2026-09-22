import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/smartwatch_repository.dart';
import '../../../data/repositories/telemetry_database_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/smartwatch_data_model.dart';
import '../../../core/constants/app_constants.dart';

class TelemetryHistoryScreen extends ConsumerStatefulWidget {
  const TelemetryHistoryScreen({super.key});

  @override
  ConsumerState<TelemetryHistoryScreen> createState() => _TelemetryHistoryScreenState();
}

class _TelemetryHistoryScreenState extends ConsumerState<TelemetryHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchRepo = ref.watch(smartwatchRepoProvider);
    final dbRepo = ref.watch(telemetryDbRepoProvider);
    final supabase = ref.watch(supabaseServiceProvider);
    // Filter to display ONLY the selected full day's history
    ref.watch(telemetryLogsStreamProvider);
    final dayRecords = dbRepo.getDayRecords(_selectedDate);

    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Compute Day Summary Statistics
    final totalIntervals = dayRecords.length;
    final avgHr = dayRecords.isNotEmpty
        ? (dayRecords.map((e) => e.heartRate).reduce((a, b) => a + b) / totalIntervals).round()
        : 0;
    final avgSpO2 = dayRecords.isNotEmpty
        ? (dayRecords.map((e) => e.spO2).reduce((a, b) => a + b) / totalIntervals).toStringAsFixed(1)
        : '0';
    final maxSteps = dayRecords.isNotEmpty
        ? dayRecords.map((e) => e.steps).reduce((a, b) => a > b ? a : b)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text(
          '10-Min Telemetry Database',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_rounded),
            tooltip: 'Supabase SQL Setup',
            onPressed: () => _showSupabaseConfigDialog(context, supabase),
          ),
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            tooltip: 'Sample & Record Now',
            onPressed: () {
              final newRecord = watchRepo.sampleAndRecordNow();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Recorded 10-min sample to Database at ${DateFormat("hh:mm:ss a").format(newRecord.timestamp)}!',
                  ),
                  backgroundColor: const Color(0xFF0D9488),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Selector Navigation Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F172A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 28),
                          tooltip: 'Previous Day',
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                            });
                          },
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: theme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'TODAY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isToday
                                  ? 'Active Live Day (Auto-rolls over at midnight)'
                                  : 'Archived Historical Day Record',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.event_available_rounded, size: 22),
                              tooltip: 'Pick Calendar Date',
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 28),
                              tooltip: 'Next Day',
                              onPressed: isToday
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                                      });
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Supabase SQL Integration Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x141E3A5F),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3ECF8E).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storage_rounded, color: Color(0xFF3ECF8E), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Supabase SQL Database Sync',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '● Table: smartwatch_telemetry_10min',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF3ECF8E)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                supabase.isConfigured
                                    ? 'Connected to Supabase Cloud • Live streaming 10-min records'
                                    : 'Local SQL Engine Active • Ready for Supabase Credentials',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF3ECF8E)),
                          label: const Text('Configure SQL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _showSupabaseConfigDialog(context, supabase),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Full Day Telemetry Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildDayStatCard(
                          title: '10-Min Intervals',
                          value: dayRecords.isEmpty ? 'Not Connected' : '$totalIntervals / 144',
                          subtitle: isToday ? 'Logged so far today' : 'Complete 24h cycle',
                          icon: Icons.timelapse_rounded,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDayStatCard(
                          title: 'Mean Heart Rate',
                          value: (dayRecords.isEmpty || avgHr <= 0) ? 'Not Connected' : '$avgHr BPM',
                          subtitle: 'Daily telemetry avg',
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFFF43F5E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDayStatCard(
                          title: 'Mean SpO2',
                          value: dayRecords.isEmpty ? 'Not Connected' : '$avgSpO2%',
                          subtitle: 'Blood oxygen saturation',
                          icon: Icons.water_drop_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDayStatCard(
                          title: 'Day Steps',
                          value: (dayRecords.isEmpty || maxSteps <= 0) ? 'Not Connected' : '$maxSteps',
                          subtitle: 'Cumulative steps',
                          icon: Icons.directions_walk_rounded,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section Header: One Full Day's 10-Minute Stream
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'One Full Day Telemetry (${DateFormat("d MMM yyyy").format(_selectedDate)})',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Displaying exactly this day’s 10-minute records. Next day starts fresh at 00:00.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ActionChip(
                            avatar: Icon(
                              watchRepo.isFastDemoMode ? Icons.fast_forward_rounded : Icons.schedule_rounded,
                              size: 14,
                              color: theme.primaryColor,
                            ),
                            label: Text(
                              watchRepo.isFastDemoMode ? 'Demo 10s Active' : 'Cadence: 10 Min',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                            ),
                            onPressed: () {
                              setState(() {
                                watchRepo.toggleIntervalMode(fastDemo: !watchRepo.isFastDemoMode);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                            label: const Text('Sample Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final rec = watchRepo.sampleAndRecordNow();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Committed to DB at ${DateFormat("hh:mm:ss a").format(rec.timestamp)}'),
                                  backgroundColor: const Color(0xFF0D9488),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Telemetry Records List for Selected Day
                  if (dayRecords.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sensors_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 10),
                          Text(
                            'Hardware Not Connected: No Telemetry Logged (${DateFormat("d MMM yyyy").format(_selectedDate)})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connect ESP32 / Smartwatch to log real-time telemetry, or tap "Sample Now" to test logging.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayRecords.length,
                      itemBuilder: (context, index) {
                        final record = dayRecords[index];
                        return _buildTelemetryRecordCard(record, index, dayRecords.length);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRecordCard(SmartwatchDataModel record, int index, int totalForDay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Exact Time + SQL Sync Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, size: 13, color: Color(0xFF0D9488)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.formattedDateTime,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_rounded, size: 10, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Interval #${totalForDay - index} • SQL Stored',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 6 Metrics Chips
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: 'Heart Rate',
                value: '${record.heartRate} BPM',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFF43F5E),
              ),
              _buildMetricChip(
                label: 'SpO2',
                value: '${record.spO2}%',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF0284C7),
              ),
              _buildMetricChip(
                label: 'Sleep Duration',
                value: '${record.sleepHours} hrs',
                icon: Icons.bedtime_rounded,
                color: const Color(0xFF4F46E5),
              ),
              _buildMetricChip(
                label: 'Daily Steps',
                value: '${record.steps}',
                icon: Icons.directions_walk_rounded,
                color: const Color(0xFF0D9488),
              ),
              _buildMetricChip(
                label: 'Stress Index',
                value: '${record.stressLevel}/100',
                icon: Icons.psychology_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _buildMetricChip(
                label: 'Active Calories',
                value: '${record.caloriesBurned} kcal',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEA580C),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Activity: ${record.activityState}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'SQL Table: smartwatch_telemetry_10min',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSupabaseConfigDialog(BuildContext context, SupabaseService supabase) {
    final urlController = TextEditingController(
      text: supabase.currentUrl == AppConstants.defaultSupabaseUrl ? '' : supabase.currentUrl,
    );
    final keyController = TextEditingController(
      text: supabase.currentKey == AppConstants.defaultSupabaseAnonKey ? '' : supabase.currentKey,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, color: Color(0xFF3ECF8E)),
            SizedBox(width: 10),
            Text('Supabase SQL Setup', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CareSphere stores every 10-minute snapshot in Supabase SQL table:\n'
                '• Table Name: smartwatch_telemetry_10min\n'
                '• SQL Schema file: supabase_schema.sql (included in project root)',
                style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Supabase Project URL',
                  hintText: 'https://xyzcompany.supabase.co',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Supabase Anon Public API Key',
                  hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💡 The complete PostgreSQL table definition, daily rollup views, and RLS policies are located in `supabase_schema.sql` at the root of the project.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3ECF8E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await supabase.updateCredentials(
                url: urlController.text,
                anonKey: keyController.text,
              );
              navigator.pop();
              if (mounted) {
                setState(() {});
              }
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Supabase credentials saved! Live SQL syncing enabled.'),
                  backgroundColor: Color(0xFF0D9488),
                ),
              );
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }
}
