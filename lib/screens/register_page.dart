import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack("กรอกข้อมูลให้ครบทุกช่อง");
      return;
    }

    if (!email.contains("@")) {
      _showSnack("รูปแบบ Email ไม่ถูกต้อง");
      return;
    }

    if (password.length < 6) {
      _showSnack("รหัสผ่านต้อง ≥ 6 ตัว");
      return;
    }

    try {
      setState(() => isLoading = true);

      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firebaseAuth.currentUser?.updateDisplayName(name);

      if (!mounted) return;
      _showSnack("สร้างบัญชีสำเร็จ! กรุณาเข้าสู่ระบบ");
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed";

      if (e.code == 'email-already-in-use') {
        errorMessage = "Email นี้ถูกใช้แล้ว";
      } else if (e.code == 'invalid-email') {
        errorMessage = "รูปแบบ Email ไม่ถูกต้อง";
      } else if (e.code == 'weak-password') {
        errorMessage = "รหัสผ่านอ่อนเกินไป (ต้องมีตัวพิมพ์ใหญ่ ตัวเลข สัญลักษณ์)";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Email/Password authentication ยังไม่เปิดใช้งาน";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "ข้อมูลไม่ถูกต้อง";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "พยายามซ้ำเกินไป กรุณารอสักครู่";
      } else {
        errorMessage = "เกิดข้อผิดพลาด: ${e.code} - ${e.message}";
      }

      _showSnack(errorMessage);
      print('Firebase Error: ${e.code} - ${e.message}');
    } catch (e) {
      _showSnack("เกิดข้อผิดพลาด กรุณาลองใหม่");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

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
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 8),

                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C2E),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Join the elite community of\nsuccessful students.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),

                const SizedBox(height: 22),

                _buildInputLabel("FULL NAME"),
                _buildTextField(
                  "Your Name",
                  controller: nameController,
                ),

                const SizedBox(height: 12),

                _buildInputLabel("EMAIL ADDRESS"),
                _buildTextField(
                  "you@example.com",
                  controller: emailController,
                ),

                const SizedBox(height: 12),

                _buildInputLabel("SECURITY PASSWORD"),
                _buildTextField(
                  "Create Password",
                  isPassword: true,
                  controller: passwordController,
                  obscure: obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : signUp,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline,
                            color: Colors.white),
                    label: const Text(
                      "Sign Up Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
            ),
        ],
      ),
    );
  }

  // ---------------- Widgets ----------------

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    bool isPassword = false,
    bool obscure = false,
    Widget? suffix,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: suffix,
      ),
    );
  }
}
