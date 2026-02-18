import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'home_page.dart';
import '../services/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);
      
      // Sign out first to allow account selection
      await _googleAuthService.signOut();
      
      final GoogleSignInAccount? googleAccount = await _googleAuthService.signIn();
      if (googleAccount == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google login cancelled')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${googleAccount.displayName ?? googleAccount.email}')),
      );
      // Navigate to home page after successful login
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Google login failed';
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = 'Account already exists with different credentials';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid Google credentials';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Google Sign-In is not enabled';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      print('Firebase Auth Error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Google Sign-In Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signInWithEmail() async {
    // Redirect to Google Sign-In instead of email login
    await signInWithGoogle();
  }

  Future<void> openGoogleSignUp() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WebViewPage(url: 'https://accounts.google.com/SignUp', title: 'Create Account'),
      ),
    );
  }

  Future<void> openGooglePasswordRecovery() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WebViewPage(url: 'https://accounts.google.com/signin/recovery', title: 'Recover Password'),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.08),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 56),
                        ),

                        const SizedBox(height: 20),
                        const Text('StudyTask', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF1A1C2E))),
                        const SizedBox(height: 8),
                        const Text('Your intelligent academic command center.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),

                        const SizedBox(height: 30),

                        // Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration('you@example.com'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your email';
                            if (!value.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration('Password').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (value.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : openGooglePasswordRecovery,
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Sign In
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : signInWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Text('All Google accounts can sync Classroom.', style: TextStyle(fontSize: 11, color: Colors.grey)),

                        const SizedBox(height: 24),

                        // OR divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Google login button at bottom
                        GestureDetector(
                          onTap: isLoading ? null : signInWithGoogle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha((0.05 * 255).round()), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                    ),
                                  )
                                else
                                  const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text('Fastest way to get started', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, color: Colors.blueAccent),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('New here? ', style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: isLoading ? null : openGoogleSignUp,
                              child: const Text('Create Account', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        SizedBox(height: constraints.maxHeight * 0.05),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (isLoading)
            Container(color: Colors.black.withAlpha((0.1 * 255).round()), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({required this.url, required this.title, super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
