import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final NotificationService _notificationService = NotificationService();
  late Duration _selectedReminderOffset;

  @override
  void initState() {
    super.initState();
    _selectedReminderOffset = _notificationService.reminderOffset;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionTitle('Account'),
            _buildAccountCard(user),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionTitle('Notifications'),
            _buildNotificationSettings(),
            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle('About'),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'About StudyTask Tracker',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAboutDialog(),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionTitle('Danger Zone', isRed: true),
            _buildSettingTile(
              icon: Icons.logout_outlined,
              title: 'Sign Out',
              subtitle: 'Log out from your account',
              titleColor: Colors.red,
              onTap: () => _showSignOutDialog(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isRed ? Colors.red.shade600 : Colors.blue.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.account_circle, size: 64)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No Email',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (titleColor ?? Colors.blue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: titleColor ?? Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor ?? const Color(0xFF1E293B),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Reminders',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Get notified before task deadline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
                tooltip: 'Test notification',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Remind me',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...[const Duration(hours: 1), const Duration(hours: 6), const Duration(hours: 12), const Duration(hours: 24), const Duration(hours: 48)]
                  .map((offset) {
              final isSelected = _selectedReminderOffset == offset;
              return GestureDetector(
                onTap: () async {
                  await _applyReminderOffset(offset);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _getDurationLabel(offset),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
              GestureDetector(
                onTap: _showCustomReminderDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${_getDurationLabel(_selectedReminderOffset)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _getDurationLabel(Duration offset) {
    if (offset.inDays >= 1 && offset.inHours % 24 == 0) {
      final days = offset.inDays;
      return days == 1 ? '1 day' : '$days days';
    }
    if (offset.inHours >= 1 && offset.inMinutes % 60 == 0) {
      final hours = offset.inHours;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    final minutes = offset.inMinutes;
    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }

  Future<void> _showCustomReminderDialog() async {
    final valueController = TextEditingController(text: '30');
    var unit = 'minutes';

    final result = await showDialog<Duration>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom reminder time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                      DropdownMenuItem(value: 'hours', child: Text('Hours')),
                      DropdownMenuItem(value: 'days', child: Text('Days')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => unit = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = int.tryParse(valueController.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a number greater than 0')),
                      );
                      return;
                    }

                    final duration = switch (unit) {
                      'days' => Duration(days: amount),
                      'hours' => Duration(hours: amount),
                      _ => Duration(minutes: amount),
                    };
                    Navigator.pop(dialogContext, duration);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    await _applyReminderOffset(result);
  }

  Future<void> _applyReminderOffset(Duration offset) async {
    final granted = await _notificationService.ensureNotificationPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is not granted. Please enable notifications first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _selectedReminderOffset = offset);
    await _notificationService.setReminderOffset(offset);
    await _reschedulePendingTasks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set to ${_getDurationLabel(offset)} before due time'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reschedulePendingTasks() async {
    final tasks = await TaskService().getTasks().first;
    await _notificationService.scheduleAllReminders(tasks);
  }

  Future<void> _sendTestNotification() async {
    final granted = await _notificationService.ensureNotificationPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send test notification because notification permission is not granted'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    await _notificationService.showImmediateNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🔔 Notification test',
      body: 'Notifications are working correctly',
      payload: 'test',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About StudyTask Tracker'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'StudyTask Tracker',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Version 1.0.0'),
              SizedBox(height: 16),
              Text(
                'A smart task management app designed for students to track and manage their academic assignments and deadlines.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('📚 Sync Google Classroom tasks'),
              Text('📅 Smart deadline tracking'),
              Text('✅ Task status management'),
              Text('📤 Evidence submission'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              await _googleAuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
