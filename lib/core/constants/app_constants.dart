import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'CareSphere';
  static const String appTagline = 'AI-Powered Elderly Healthcare Monitoring Platform';
  static const String apiBaseUrl = 'https://api.caresphere.ai/v1'; // or local FastAPI http://10.0.2.2:8000
  static const String esp32DefaultIp = '192.168.1.150';

  // Demo user data
  static const String demoPatientName = 'Eleanor Vance';
  static const String demoPatientAge = '78 yrs';
  static const String demoPatientBloodGroup = 'O+';
  static const String demoPatientLocation = 'Sector 4, Green Valley Home, Bengaluru';

  // Sensor Thresholds
  static const int normalHrMin = 60;
  static const int normalHrMax = 100;
  static const int normalSpO2Min = 95;
  static const double normalTempMin = 20.0;
  static const double normalTempMax = 26.0;

  // Supabase Database Configuration
  static const String defaultSupabaseUrl = 'https://ddkkcyepioyrksajcblu.supabase.co';
  static const String defaultSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRka2tjeWVwaW95cmtzYWpjYmx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk0NjM5ODQsImV4cCI6MjEwNTAzOTk4NH0.f7c6jE5xoPSKPxTBvSC100y17DJ-pF6r7pN4XijkXX0';
  static const String supabaseTelemetryTable = 'smartwatch_telemetry_10min';
}
