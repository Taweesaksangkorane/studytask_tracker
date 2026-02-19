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
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool isLoading = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top decorative space
                      SizedBox(height: constraints.maxHeight * 0.1),

                      // Logo and title section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)],
                              ),
                              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1A1C2E), size: 64),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'StudyTask',
                              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your intelligent academic command center',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      // Sign in section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(blurRadius: 30, color: Colors.black26)],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Get Started',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1C2E)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sign in with Google to sync your Classroom',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: isLoading ? null : signInWithGoogle,
                                      icon: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1C2E)),
                                              ),
                                            )
                                          : const Icon(Icons.g_mobiledata, size: 26),
                                      label: const Text(
                                        'Continue with Google',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '🔒 Your data is secure with Google Sign-In authentication',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Color(0xFF1A1C2E)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom space
                      SizedBox(height: constraints.maxHeight * 0.05),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
