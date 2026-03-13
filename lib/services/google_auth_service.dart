import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Singleton GoogleSignIn instance shared across the app
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  String? _webAccessToken;
  String? _webAccessTokenUid;
  
  factory GoogleAuthService() {
    return _instance;
  }
  
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '192014714672-f1a48avqo0bd5e5ll2jl6vh4ojdo3256.apps.googleusercontent.com'
        : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.course-work.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    ],
  );

  GoogleSignIn get instance => _googleSignIn;

  String? get webAccessToken => _webAccessToken;

  String? getValidWebAccessToken(String? currentUid) {
    if (currentUid == null || _webAccessTokenUid != currentUid) {
      return null;
    }
    return _webAccessToken;
  }

  void setWebAccessToken(String? token, {String? uid}) {
    _webAccessToken = token;
    _webAccessTokenUid = uid;
  }

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
    _webAccessToken = null;
    _webAccessTokenUid = null;
    await _googleSignIn.signOut();
  }
}
