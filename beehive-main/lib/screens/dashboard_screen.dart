import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  Map<String, dynamic>? _sensorData;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _ipAddress;
  int _failCount = 0; // Track consecutive failures
  static const int _maxFailsBeforeDisconnect = 3; // Show disconnected after 3 fails

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initConnection() async {
    final ip = await _apiService.getIpAddress();
    setState(() {
      _ipAddress = ip;
      _isLoading = true;
      _failCount = 0;
    });

    if (ip != null && ip.isNotEmpty) {
      _startFetchingData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startFetchingData() {
    _timer?.cancel();
    _fetchData(); // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final data = await _apiService.fetchSensorData();
    if (mounted) {
      setState(() {
        if (data != null) {
          _sensorData = data;
          _isConnected = true;
          _failCount = 0; // Reset on success
        } else {
          _failCount++;
          // Only show disconnected after multiple consecutive failures
          // This prevents flickering on temporary network hiccups
          if (_failCount >= _maxFailsBeforeDisconnect) {
            _isConnected = false;
          }
          // Keep showing last known data if we have it
        }
        _isLoading = false;
      });
    }
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (result == true) {
      _initConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Beehive', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _ipAddress == null || _ipAddress!.isEmpty
              ? _buildSetupPrompt()
              : _buildDashboard(),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No IP Address Configured',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please configure your ESP32 IP address in settings to connect to your beehive.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    bool hasAlert = _sensorData != null && _sensorData!['alert'] != 'None';

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: Colors.amber,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isConnected ? Colors.green[200]! : Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green[100] : Colors.red[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      color: _isConnected ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected ? 'Connected to Hive' : 'Disconnected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                        Text(
                          _ipAddress ?? 'Unknown IP',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isConnected ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isConnected)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _failCount = 0;
                        });
                        _initConnection();
                      },
                      icon: Icon(Icons.refresh, color: Colors.red[700]),
                      tooltip: 'Retry Connection',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Alert Banner
            if (hasAlert)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ALERT DETECTED',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _sensorData!['alert'].toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Metrics Grid
            const Text(
              'Live Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Temperature',
                        value: _sensorData != null ? '${_sensorData!['temp']}°C' : '--°C',
                        icon: Icons.thermostat,
                        color: Colors.orange,
                        isWarning: _sensorData != null && (_sensorData!['temp'] > 38.0 || _sensorData!['temp'] < 10.0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Humidity',
                        value: _sensorData != null ? '${_sensorData!['humidity']}%' : '--%',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Sound Level',
                        value: _sensorData != null ? '${_sensorData!['sound']}' : '--',
                        icon: Icons.volume_up,
                        color: Colors.purple,
                        isWarning: _sensorData != null && _sensorData!['sound'] > 2500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Vibration',
                        value: _sensorData != null ? (_sensorData!['vibration'] == 1 ? 'Detected' : 'Normal') : '--',
                        icon: Icons.vibration,
                        color: Colors.red,
                        isWarning: _sensorData != null && _sensorData!['vibration'] == 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildMetricCard(
                    title: 'Light Level',
                    value: _sensorData != null ? '${_sensorData!['light']}' : '--',
                    icon: Icons.light_mode,
                    color: Colors.amber,
                    isWarning: _sensorData != null && _sensorData!['light'] < 2000,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tayyaba Anwar and Hina Tahir',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
    bool isWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isWarning ? Border.all(color: Colors.red, width: 2) : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: isWarning ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWarning ? Colors.red[50] : color[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isWarning ? Colors.red : color[600], size: 24),
                ),
                if (isWarning)
                  const Icon(Icons.warning, color: Colors.red, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isWarning ? Colors.red[700] : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
