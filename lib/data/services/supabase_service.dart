import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/smartwatch_data_model.dart';

enum SupabaseSyncStatus {
  notConfigured,
  synced,
  error,
  syncing,
}

class SupabaseService {
  static const String _keyUrl = 'caresphere_supabase_url';
  static const String _keyKey = 'caresphere_supabase_anon_key';

  String _url = AppConstants.defaultSupabaseUrl;
  String _anonKey = AppConstants.defaultSupabaseAnonKey;
  SupabaseSyncStatus _status = SupabaseSyncStatus.notConfigured;
  String? _lastError;
  DateTime? _lastSyncTime;

  SupabaseService() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_keyUrl);
      final savedKey = prefs.getString(_keyKey);
      if (savedUrl != null && savedUrl.isNotEmpty) _url = savedUrl;
      if (savedKey != null && savedKey.isNotEmpty) _anonKey = savedKey;

      if (_url.contains('your-project') || _url.isEmpty) {
        _status = SupabaseSyncStatus.notConfigured;
      } else {
        _status = SupabaseSyncStatus.synced;
      }
    } catch (_) {}
  }

  bool get isConfigured =>
      _url.isNotEmpty &&
      _anonKey.isNotEmpty &&
      !_url.contains('your-project') &&
      !_anonKey.contains('your-anon-key');

  String get currentUrl => _url;
  String get currentKey => _anonKey;
  SupabaseSyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> updateCredentials({required String url, required String anonKey}) async {
    _url = url.trim();
    _anonKey = anonKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, _url);
    await prefs.setString(_keyKey, _anonKey);
    _loadConfig();
  }

  /// Commits a single 10-minute snapshot into the Supabase `smartwatch_telemetry_10min` table
  Future<bool> insert10MinTelemetry(SmartwatchDataModel record) async {
    if (!isConfigured) {
      _status = SupabaseSyncStatus.notConfigured;
      return false;
    }

    _status = SupabaseSyncStatus.syncing;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final endpoint = Uri.parse('$cleanUrl/rest/v1/${AppConstants.supabaseTelemetryTable}');

      final response = await http.post(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation,resolution=merge-duplicates',
        },
        body: jsonEncode(record.toSupabaseMap()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _status = SupabaseSyncStatus.synced;
        _lastSyncTime = DateTime.now();
        _lastError = null;
        return true;
      } else {
        _status = SupabaseSyncStatus.error;
        _lastError = 'HTTP ${response.statusCode}: ${response.body}';
        return false;
      }
    } catch (e) {
      _status = SupabaseSyncStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  /// Fetch full day's data from Supabase for a given date (yyyy-MM-dd)
  Future<List<SmartwatchDataModel>?> fetchDayFromSupabase(String dateString) async {
    if (!isConfigured) return null;

    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final endpoint = Uri.parse(
        '$cleanUrl/rest/v1/${AppConstants.supabaseTelemetryTable}?reading_date=eq.$dateString&order=recorded_at.desc',
      );

      final response = await http.get(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => SmartwatchDataModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  /// Insert ESP32 Vitals telemetry into Supabase
  Future<bool> insertEsp32VitalsTelemetry(Map<String, dynamic> data) async {
    if (!isConfigured) return false;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final endpoint = Uri.parse('$cleanUrl/rest/v1/esp32_vitals_telemetry');

      final response = await http.post(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(data),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {}
    return false;
  }

  /// Insert ESP32 Room telemetry into Supabase
  Future<bool> insertEsp32RoomTelemetry(Map<String, dynamic> data) async {
    if (!isConfigured) return false;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final endpoint = Uri.parse('$cleanUrl/rest/v1/esp32_room_telemetry');

      final response = await http.post(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(data),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {}
    return false;
  }

  /// Fetch the most recent live ESP32 Vitals telemetry row from Supabase
  Future<Map<String, dynamic>?> fetchLatestEsp32Vitals() async {
    if (!isConfigured) return null;

    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final endpoint = Uri.parse(
        '$cleanUrl/rest/v1/esp32_vitals_telemetry?order=recorded_at.desc&limit=1',
      );

      final response = await http.get(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }
  /// Create a new user in caresphere_users table
  Future<Map<String, dynamic>?> createUser(Map<String, dynamic> userData) async {
    if (!isConfigured) return null;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final endpoint = Uri.parse('$cleanUrl/rest/v1/caresphere_users');

      final response = await http.post(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get user by email from caresphere_users table
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (!isConfigured) return null;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final cleanEmail = email.trim().toLowerCase();
      final endpoint = Uri.parse('$cleanUrl/rest/v1/caresphere_users?email=ilike.$cleanEmail');

      final response = await http.get(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get user by phone from caresphere_users table
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    if (!isConfigured) return null;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return null;
      final matchPhone = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
      final endpoint = Uri.parse('$cleanUrl/rest/v1/caresphere_users?phone=ilike.*$matchPhone*');

      final response = await http.get(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get user by elder code from caresphere_users table
  Future<Map<String, dynamic>?> getUserByElderCode(String elderCode) async {
    if (!isConfigured) return null;
    try {
      final cleanUrl = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
      final cleanCode = elderCode.trim();
      if (cleanCode.isEmpty) return null;
      final endpoint = Uri.parse('$cleanUrl/rest/v1/caresphere_users?elder_code=eq.$cleanCode');

      final response = await http.get(
        endpoint,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
