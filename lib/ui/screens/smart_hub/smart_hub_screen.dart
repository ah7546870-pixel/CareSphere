import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/esp32_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/iot_sensor_card.dart';
import '../../widgets/status_badge.dart';

class SmartHubScreen extends ConsumerStatefulWidget {
  const SmartHubScreen({super.key});

  @override
  ConsumerState<SmartHubScreen> createState() => _SmartHubScreenState();
}

class _SmartHubScreenState extends ConsumerState<SmartHubScreen> {
  late final TextEditingController _vitalsIpController;
  late final TextEditingController _roomIpController;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(esp32RepoProvider);
    _vitalsIpController = TextEditingController(text: repo.vitalsIp);
    _roomIpController = TextEditingController(text: repo.roomIp);
  }

  @override
  void dispose() {
    _vitalsIpController.dispose();
    _roomIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(esp32RepoProvider);
    final espData = ref.watch(esp32StreamProvider).value ?? repo.latest;

    final vitals = espData.vitals;
    final room = espData.room;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('ESP32 Dual-Controller Hub', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Controller #1 Banner: ESP32 Wearable Vitals & Motion
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2B608A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x141E3A5F), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05368).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFFFCA5A5), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESP32 #1: Vitals & Motion Hub',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sensors: MAX30102 (HR/SpO2) + MPU6050 (Accel/Gyro)',
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: vitals.deviceStatus.toUpperCase(),
                          color: vitals.deviceStatus == 'Connected' ? const Color(0xFF16A34A) : const Color(0xFFE05368),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHubStat('WiFi Signal', vitals.isConnected ? '${vitals.wifiStrength} dBm' : 'Not Connected', Icons.wifi_rounded),
                        _buildHubStat('Heart Rate', vitals.isConnected ? '${vitals.heartRate} BPM' : 'Not Connected', Icons.favorite_rounded),
                        _buildHubStat('SpO2', vitals.isConnected ? '${vitals.spO2}%' : 'Not Connected', Icons.water_drop_rounded),
                        _buildHubStat('Last Sync', vitals.isConnected ? DateFormat('hh:mm:ss a').format(vitals.lastSync) : 'Not Connected', Icons.sync_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Controller #2 Banner: ESP32 Room & Environment
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF155E75), Color(0xFF0E7490)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x140E7490), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESP32 #2: Room & Presence Hub',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sensors: BH1750 (Lux) + HLK-LD2410 (Radar) + DHT22',
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: room.deviceStatus.toUpperCase(),
                          color: room.deviceStatus == 'Connected' ? const Color(0xFF16A34A) : const Color(0xFFE05368),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHubStat('Temperature', room.isConnected ? '${room.temperature}°C' : 'Not Connected', Icons.thermostat_rounded),
                        _buildHubStat('Humidity', room.isConnected ? '${room.humidity}%' : 'Not Connected', Icons.water_rounded),
                        _buildHubStat('Light Lux', room.isConnected ? '${room.ambientLight}' : 'Not Connected', Icons.light_mode_rounded),
                        _buildHubStat('Last Sync', room.isConnected ? DateFormat('hh:mm:ss a').format(room.lastSync) : 'Not Connected', Icons.sync_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // IP Configuration Section
              const Text(
                'Device IP Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _vitalsIpController,
                      decoration: InputDecoration(
                        labelText: 'ESP32 #1 Vitals IP (e.g. 192.168.1.10)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.wifi_rounded),
                        suffixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (vitals.isConnected ? const Color(0xFF0D9488) : const Color(0xFF64748B)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vitals.isConnected ? 'CONNECTED' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: vitals.isConnected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      onChanged: (val) => repo.setVitalsIp(val.trim()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _roomIpController,
                      decoration: InputDecoration(
                        labelText: 'ESP32 #2 Room Node IP (e.g. 192.168.1.11)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.wifi_rounded),
                        suffixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (room.isConnected ? const Color(0xFF0D9488) : const Color(0xFF64748B)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room.isConnected ? 'CONNECTED' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: room.isConnected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      onChanged: (val) => repo.setRoomIp(val.trim()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('Save & Ping ESP32 Devices', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          repo.setVitalsIp(_vitalsIpController.text.trim());
                          repo.setRoomIp(_roomIpController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('IPs saved! CareSphere is polling ESP32 endpoints every 3 seconds.'),
                              backgroundColor: Color(0xFF0D9488),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Telemetry Data Streams Section
              const Text(
                'Live Telemetry Streams',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 12),

              // ESP32 #1 Vitals & Motion Cards
              IotSensorCard(
                title: 'Heart Rate Stream (ESP1 MAX30102)',
                value: vitals.isConnected ? '${vitals.heartRate}' : 'Not Connected',
                unit: vitals.isConnected ? 'BPM' : '',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFF43F5E),
                isOnline: vitals.isConnected,
              ),
              const SizedBox(height: 10),
              IotSensorCard(
                title: 'Blood Oxygen Saturation (ESP1 MAX30102)',
                value: vitals.isConnected ? '${vitals.spO2}' : 'Not Connected',
                unit: vitals.isConnected ? '%' : '',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF0284C7),
                isOnline: vitals.isConnected,
              ),
              const SizedBox(height: 10),
              IotSensorCard(
                title: 'Motion Accel Z Vector (ESP1 MPU6050)',
                value: vitals.isConnected ? vitals.accelZ.toStringAsFixed(2) : 'Not Connected',
                unit: vitals.isConnected ? 'm/s²' : '',
                icon: Icons.screen_rotation_rounded,
                color: const Color(0xFF8B5CF6),
                isOnline: vitals.isConnected,
              ),
              const SizedBox(height: 10),

              // ESP32 #2 Room & Environment Cards
              IotSensorCard(
                title: 'Ambient Light (ESP2 BH1750)',
                value: room.isConnected ? '${room.ambientLight}' : 'Not Connected',
                unit: room.isConnected ? 'Lux' : '',
                icon: Icons.light_mode_rounded,
                color: const Color(0xFFF59E0B),
                isOnline: room.isConnected,
              ),
              const SizedBox(height: 10),
              IotSensorCard(
                title: 'Human Presence Radar (ESP2 HLK-LD2410)',
                value: room.isConnected ? (room.presenceDetected ? 'DETECTED' : 'NOT PRESENT') : 'Not Connected',
                unit: room.isConnected ? 'Room Area' : '',
                icon: Icons.radar_rounded,
                color: room.isConnected
                    ? (room.presenceDetected ? const Color(0xFF0D9488) : Colors.grey)
                    : Colors.grey,
                isOnline: room.isConnected,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

