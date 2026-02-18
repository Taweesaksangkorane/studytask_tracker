import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy & Data'),
            subtitle: const Text('Google Classroom data usage'),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('ข้อมูลความเป็นส่วนตัว'),
                content: const SingleChildScrollView(
                  child: Text(
                    'แอปนี้ใช้ Google Classroom API แบบ Read-only เท่านั้น\n\n'
                    '✓ ดึงเฉพาะ Classroom ที่คุณเป็นสมาชิก\n'
                    '✓ ดูเฉพาะงานและกำหนดส่งของคุณ\n'
                    '✓ ไม่สามารถแก้ไขหรือลบข้อมูลใน Classroom\n\n'
                    '✗ ไม่สามารถดึง Classroom ของผู้อื่น\n'
                    '✗ ไม่สามารถดูงานส่งของเพื่อน\n'
                    '✗ ไม่เก็บหรือแชร์ข้อมูลส่วนตัวของคุณ\n\n'
                    'ข้อมูลทั้งหมดเก็บในบัญชี Firebase ของคุณเท่านั้น',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิด'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () => showAboutDialog(context: context, applicationName: 'StudyTask'),
          )
        ],
      ),
    );
  }
}
