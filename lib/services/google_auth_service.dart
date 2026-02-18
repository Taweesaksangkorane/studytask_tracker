import 'package:google_sign_in/google_sign_in.dart';

/// Singleton GoogleSignIn instance shared across the app
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  
  factory GoogleAuthService() {
    return _instance;
  }
  
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.course-work.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    ],
  );

  GoogleSignIn get instance => _googleSignIn;

  /// Get current GoogleSignIn account
  GoogleSignInAccount? get currentAccount => _googleSignIn.currentUser;

  /// Sign in with account picker
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign in silently (no UI) - returns null if user not previously signed in
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('Silent Sign-In Error: $e');
      return null;
    }
  }

  /// Get authentication credentials
  Future<GoogleSignInAuthentication?> getAuthentication() async {
    final account = currentAccount ?? await signInSilently();
    if (account == null) {
      throw Exception('No Google account signed in. Please sign in first.');
    }
    return account.authentication;
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
