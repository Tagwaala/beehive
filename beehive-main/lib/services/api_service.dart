import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String ipKey = 'esp32_ip_address';

  Future<void> saveIpAddress(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ipKey, ip);
  }

  Future<String?> getIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ipKey);
  }

  /// Quick ping to check if ESP32 is reachable
  Future<bool> pingDevice() async {
    try {
      final ip = await getIpAddress();
      if (ip == null || ip.isEmpty) return false;

      final url = Uri.parse('http://$ip/ping');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Ping failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchSensorData() async {
    try {
      final ip = await getIpAddress();
      if (ip == null || ip.isEmpty) return null;

      final url = Uri.parse('http://$ip/data');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
    return null;
  }
}
