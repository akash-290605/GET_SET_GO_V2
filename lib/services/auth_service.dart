import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';

class AuthUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String authProvider; // 'google', 'email', 'guest'
  final DateTime createdAt;

  AuthUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.authProvider = 'google',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'authProvider': authProvider,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AuthUser.fromMap(Map<String, dynamic> map) => AuthUser(
        uid: map['uid'] ?? 'guest_',
        displayName: map['displayName'] ?? 'Athlete',
        email: map['email'] ?? '',
        photoURL: map['photoURL'],
        authProvider: map['authProvider'] ?? 'google',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : DateTime.now(),
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String _userKey = 'gsg_auth_user_v5';
  static const String _webClientId = '159071674059-89c7hpmmarq633tr542splk3ijhmu5s7.apps.googleusercontent.com';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthUser? _currentUser;
  bool _isGuest = false;
  bool _googleSignInInitialized = false;

  AuthUser? get currentUser => _currentUser;
  bool get isGuest => _isGuest || _currentUser == null || _currentUser?.authProvider == 'guest';
  bool get isSignedIn => _currentUser != null && !_isGuest;
  String get uid => _currentUser?.uid ?? 'guest_uid';

  Future<void> init() async {
    try {
      // 1. Check if Firebase already has an active, authenticated user session
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        _syncFromFirebaseUser(fbUser);
        if (_currentUser?.displayName.isNotEmpty ?? false) {
          ProfileService.instance.userName = _currentUser!.displayName;
        }
        await ProfileService.instance.loadForUser(_currentUser!.uid);
        _isGuest = false;
        notifyListeners();
        return;
      }

      // 2. Otherwise check local preferences
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_userKey);
      if (str != null) {
        final map = json.decode(str);
        final user = AuthUser.fromMap(map);
        if (user.authProvider == 'guest') {
          _currentUser = user;
          _isGuest = true;
          await ProfileService.instance.loadForUser(user.uid);
        } else {
          // If not authenticated in Firebase, require fresh login
          _currentUser = null;
          _isGuest = true;
        }
      } else {
        _currentUser = null;
        _isGuest = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService init error: ');
    }
  }

  void _syncFromFirebaseUser(User user) {
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'Athlete');

    _currentUser = AuthUser(
      uid: user.uid,
      displayName: displayName,
      email: user.email ?? '',
      photoURL: user.photoURL,
      authProvider: isGoogle ? 'google' : 'email',
    );
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _webClientId,
      );
      _googleSignInInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize error: ');
    }
  }

  /// Sign In with Google - REAL Google Identity OAuth Verification
  Future<void> signInWithGoogle() async {
    try {
      User? user;

      if (kIsWeb) {
        // Web: Use official Firebase Auth popup with GoogleAuthProvider
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        final UserCredential userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
        user = userCredential.user;
      } else {
        // Android / iOS / Desktop: Use GoogleSignIn 7.x and exchange credentials with Firebase Auth
        await _ensureGoogleSignInInitialized();

        final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = account.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        user = userCredential.user;
      }

      if (user == null) {
        throw Exception('Unable to authenticate with Google. Please try again.');
      }

      _syncFromFirebaseUser(user);
      _isGuest = false;

      ProfileService.instance.userName = _currentUser!.displayName;
      await ProfileService.instance.loadForUser(user.uid);
      await ProfileService.instance.saveProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuthException:  - ');
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('Google Sign-In Error: ');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel') || errorStr.contains('aborted')) {
        throw Exception('Google Sign-In was cancelled.');
      }
      throw Exception('Google Sign-In failed: ');
    }
  }

  /// Sign Up with Email and Password - REAL Firebase Account Creation
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Please enter your full name.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    try {
      final UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(cleanName);
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser ?? user;
        _syncFromFirebaseUser(refreshedUser);
      } else {
        _currentUser = AuthUser(
          uid: 'user_',
          displayName: cleanName,
          email: cleanEmail,
          authProvider: 'email',
        );
      }

      _isGuest = false;
      ProfileService.instance.userName = cleanName;
      await ProfileService.instance.loadForUser(_currentUser!.uid);
      await ProfileService.instance.saveProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp FirebaseAuthException:  - ');
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('SignUp Error: ');
      throw Exception('Registration failed: ');
    }
  }

  /// Sign In with Email and Password - REAL Firebase Authentication
  Future<void> signInWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }

    try {
      final UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }

      _syncFromFirebaseUser(user);
      _isGuest = false;

      ProfileService.instance.userName = _currentUser!.displayName;
      await ProfileService.instance.loadForUser(user.uid);
      await ProfileService.instance.saveProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('SignIn FirebaseAuthException:  - ');
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('SignIn Error: ');
      throw Exception('Sign In failed: ');
    }
  }

  /// Send Password Reset Email via Firebase
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception('Failed to send reset email: ');
    }
  }

  /// Continue as Guest (local preview mode)
  Future<void> continueAsGuest() async {
    try {
      final guestUid = 'guest_';
      _currentUser = AuthUser(
        uid: guestUid,
        displayName: 'Guest Athlete',
        email: 'guest@getsetgo.app',
        authProvider: 'guest',
      );
      _isGuest = true;

      await ProfileService.instance.loadForUser(guestUid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Guest login error: ');
    }
  }

  /// Update Profile Details
  Future<void> updateProfile({required String displayName, required String email, String? photoURL}) async {
    if (_currentUser == null) return;
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        await fbUser.updateDisplayName(displayName);
        if (photoURL != null && photoURL.isNotEmpty) {
          await fbUser.updatePhotoURL(photoURL);
        }
      }
    } catch (_) {}

    _currentUser = AuthUser(
      uid: _currentUser!.uid,
      displayName: displayName,
      email: email,
      photoURL: photoURL ?? _currentUser!.photoURL,
      authProvider: _currentUser!.authProvider,
      createdAt: _currentUser!.createdAt,
    );
    ProfileService.instance.userName = displayName;
    await ProfileService.instance.saveProfile();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
    notifyListeners();
  }

  /// Sign Out: Completely clear session and sign out of Firebase & Google
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Firebase signOut error: ');
    }
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}

    _currentUser = null;
    _isGuest = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Sign Out Local Error: ');
    }
    notifyListeners();
  }

  /// Human-friendly Firebase error messages
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please check your spelling or sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please verify and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please Sign In instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'popup-closed-by-user':
        return 'Google Sign-In popup was closed before completing verification.';
      case 'popup-blocked':
        return 'Sign-In popup was blocked by your browser. Please allow popups for this site and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console. Please verify Authentication settings.';
      case 'network-request-failed':
        return 'Network connection issue. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred (). Please try again.';
    }
  }
}
