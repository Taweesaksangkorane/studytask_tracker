import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isSending = false;

  Future<void> _sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnack('กรุณากรอก Email');
      return;
    }

    if (!email.contains('@')) {
      _showSnack('รูปแบบ Email ไม่ถูกต้อง');
      return;
    }

    try {
      setState(() => isSending = true);

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showSnack('ส่งลิงก์รีเซ็ตรหัสผ่านแล้ว');

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {

      String errorMessage = 'เกิดข้อผิดพลาด';

      if (e.code == 'user-not-found') {
        errorMessage = 'ไม่พบบัญชีนี้';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'รูปแบบ Email ไม่ถูกต้อง';
      }

      _showSnack(errorMessage);

    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.lock_open,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C2E),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter your account email and we will send a password reset link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 28),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'EMAIL ADDRESS',
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSending ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Remembered your password? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          if (isSending)
            Container(
              color: Colors.black.withOpacity(0.05),
            ),
        ],
      ),
    );
  }
}
