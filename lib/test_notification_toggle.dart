import 'package:flutter/material.dart';
import 'package:real/services/fcm_service.dart';
import 'package:real/services/notification_preferences.dart';

/// Simple test screen to debug notification toggle
/// Navigate to this screen to test if notifications are working
class TestNotificationToggleScreen extends StatefulWidget {
  const TestNotificationToggleScreen({Key? key}) : super(key: key);

  @override
  State<TestNotificationToggleScreen> createState() => _TestNotificationToggleScreenState();
}

class _TestNotificationToggleScreenState extends State<TestNotificationToggleScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String _statusMessage = 'Loading...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 20) _logs.removeLast();
    });
    print(message);
  }

  Future<void> _loadCurrentStatus() async {
    _addLog('📖 Loading notification status...');
    try {
      final enabled = await NotificationPreferences.getNotificationsEnabled();
      setState(() {
        _notificationsEnabled = enabled;
        _isLoading = false;
        _statusMessage = enabled ? '✅ Notifications are ENABLED' : '🔕 Notifications are DISABLED';
      });
      _addLog('✅ Status loaded: ${enabled ? "ENABLED" : "DISABLED"}');
    } catch (e) {
      _addLog('❌ Error loading status: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    _addLog('🔄 Toggling notifications to: ${value ? "ON" : "OFF"}');

    setState(() => _isLoading = true);

    try {
      _addLog('💾 Saving preference to SharedPreferences...');
      await NotificationPreferences.setNotificationsEnabled(value);
      _addLog('✅ Preference saved');

      _addLog('🔥 Calling FCMService.toggleNotifications()...');
      await FCMService().toggleNotifications(value);
      _addLog('✅ FCM service updated');

      // Verify it was saved
      final saved = await NotificationPreferences.getNotificationsEnabled();
      _addLog('🔍 Verification: Saved value is $saved');

      setState(() {
        _notificationsEnabled = value;
        _isLoading = false;
        _statusMessage = value ? '✅ Notifications are ENABLED' : '🔕 Notifications are DISABLED';
      });

      _addLog('✅ Toggle completed successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '✅ Notifications Enabled' : '🔕 Notifications Disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e, stackTrace) {
      _addLog('❌ ERROR: $e');
      _addLog('❌ Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notification Toggle'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _notificationsEnabled ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                          size: 32,
                          color: _notificationsEnabled ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Toggle Switch
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Enable Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _notificationsEnabled
                      ? 'You will receive push notifications'
                      : 'Notifications are blocked',
                ),
                value: _notificationsEnabled,
                onChanged: _isLoading ? null : _toggleNotifications,
                secondary: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _notificationsEnabled ? Icons.check_circle : Icons.cancel,
                        color: _notificationsEnabled ? Colors.green : Colors.red,
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How to Test',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Open browser DevTools (F12)'),
                    const Text('2. Go to Console tab'),
                    const Text('3. Toggle the switch above'),
                    const Text('4. Watch the logs below and in console'),
                    const Text('5. Send a test notification'),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ If OFF, you should NOT receive notifications',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logs
            const Text(
              'Activity Logs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _logs.isEmpty
                  ? const Center(child: Text('No logs yet...'))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: log.contains('❌') ? Colors.red : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Reload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadCurrentStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
