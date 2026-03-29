import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Mock states for UI
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = false;
  bool _updatesEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text("Communication Channels", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildToggleTile(
            title: "Push Notifications",
            subtitle: "Receive alerts on your device for immediate action items.",
            value: _pushEnabled,
            onChanged: (val) => setState(() => _pushEnabled = val),
          ),
          _buildToggleTile(
            title: "Email Notifications",
            subtitle: "Receive daily summaries and important documents via email.",
            value: _emailEnabled,
            onChanged: (val) => setState(() => _emailEnabled = val),
          ),
          _buildToggleTile(
            title: "SMS Alerts",
            subtitle: "Get critical alerts directly to your registered phone number.",
            value: _smsEnabled,
            onChanged: (val) => setState(() => _smsEnabled = val),
          ),
          
          const SizedBox(height: 32),
          const Text("Alert Preferences", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildToggleTile(
            title: "System Updates",
            subtitle: "Notify me about app maintenance and new features.",
            value: _updatesEnabled,
            onChanged: (val) => setState(() => _updatesEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
