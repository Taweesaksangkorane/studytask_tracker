import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      final account = await _googleSignIn.signIn();

      if (!mounted) return;

      if (account != null) {
        debugPrint("Google → ${account.email}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome ${account.displayName}")),
        );

        // 👉 TODO: ไปหน้า Home
      }
    } catch (e) {
      debugPrint("Google Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google login failed")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- USERNAME LOGIN ----------------
  void signInWithUsername() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรอก Username และ Password")),
      );
      return;
    }

    debugPrint("Username → $username");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logged in as $username")),
    );

    // 👉 TODO: ตรวจสอบ backend / ไป Home
  }

  // ---------------- FORGOT PASSWORD ----------------
  void forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ไปหน้า Reset Password")),
    );

    // Navigator.push(...)
  }

  // ---------------- SIGN UP ----------------
  void signUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ไปหน้า Sign Up")),
    );

    // Navigator.push(...)
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // --- LOGO ---
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Study',
                          style: TextStyle(color: Color(0xFF1A1C2E)),
                        ),
                        TextSpan(
                          text: 'Task',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),

                  const Text(
                    "The AI-powered command center for\nyour academic success.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  // --- GOOGLE BUTTON ---
                  GestureDetector(
                    onTap: signInWithGoogle,
                    child: _buildGoogleButton(),
                  ),

                  const SizedBox(height: 15),

                  // --- AI INFO BOX ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withAlpha((0.05 * 255).round()),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.school_outlined, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "เชื่อมโยงงานจาก Google Classroom ให้คุณโดยอัตโนมัติ พร้อมวิเคราะห์ความสำคัญด้วย AI",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "OR EXPLORE MORE",
                    style: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- INPUTS ---
                  _buildTextField(
                    "Username",
                    controller: usernameController,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Password",
                    isPassword: true,
                    controller: passwordController,
                  ),

                  const SizedBox(height: 10),

                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

                            // -------- FORGOT --------
                            TextButton(
                            onPressed: () {
                                Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                );
                            },
                            child: const Text(
                                "Forgot Access?",
                                style: TextStyle(color: Colors.grey),
                            ),
                            ),

                            // -------- REGISTER --------
                            TextButton(
                            onPressed: () {
                                Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterPage()),
                                );
                            },
                            child: const Text(
                                "New Member",
                                style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),


                  const SizedBox(height: 10),

                  // --- SIGN IN BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: signInWithUsername,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildSecurityFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- LOADING ---
          if (isLoading)
            Container(
              color: Colors.black.withAlpha((0.2 * 255).round()),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ---------------- DISPOSE ----------------
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- WIDGETS ----------------

  Widget _buildGoogleButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withAlpha((0.2 * 255).round())),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: const [
          Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Continue with Google",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "SYNC WITH CLASSROOM",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_forward, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withAlpha((0.1 * 255).round())),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 16, color: Colors.teal),
              SizedBox(width: 5),
              Text(
                "END-TO-END ENCRYPTED LOGIN",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            "INTEGRATED WITH GOOGLE CLOUD IDENTITY & CLASSROOM PLATFORM",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
