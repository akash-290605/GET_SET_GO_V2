import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;

  AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
      };

  factory AuthUser.fromMap(Map<String, dynamic> map) => AuthUser(
        uid: map['uid'] ?? 'guest',
        displayName: map['displayName'],
        email: map['email'],
        photoURL: map['photoURL'],
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String _userKey = 'gsg_auth_user_v3';
  AuthUser? _currentUser;
  bool _isGuest = true;

  AuthUser? get currentUser => _currentUser;
  bool get isGuest => _isGuest || _currentUser == null;
  bool get isSignedIn => _currentUser != null && !_isGuest;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_userKey);
      if (str != null) {
        final map = json.decode(str);
        _currentUser = AuthUser.fromMap(map);
        _isGuest = false;
      } else {
        _isGuest = true;
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Simulate/Trigger Google Sign-In and persist user session
      _currentUser = AuthUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Akash K',
        email: 'akash.k@example.com',
        photoURL: null,
      );
      _isGuest = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _isGuest = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
    notifyListeners();
  }
}
