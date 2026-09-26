import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String authProvider; // 'google', 'email', 'guest'
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.authProvider,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? 'guest_user',
      email: map['email'] as String? ?? 'guest@getsetgo.app',
      displayName: map['displayName'] as String? ?? 'GetSetGo Titan',
      photoUrl: map['photoUrl'] as String? ?? '',
      authProvider: map['authProvider'] as String? ?? 'guest',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserProfile? _currentUser;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isGuest => _currentUser?.authProvider == 'guest';
  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String _userKey = 'gsg_auth_user_v1';

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserProfile.fromJson(userJson);
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final now = DateTime.now();
      final user = UserProfile(
        uid: 'google_user_${now.millisecondsSinceEpoch}',
        email: 'akash.titan@gmail.com',
        displayName: 'Akash K (Titan)',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        authProvider: 'google',
        createdAt: now,
      );

      await _persistUser(user);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!email.contains('@') || !email.contains('.')) {
        throw Exception('Please enter a valid email address.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final sanitizedName = email.split('@').first;
      final displayName = sanitizedName.isNotEmpty
          ? sanitizedName[0].toUpperCase() + sanitizedName.substring(1)
          : 'Titan Member';

      final user = UserProfile(
        uid: 'mail_${email.hashCode.abs()}',
        email: email.trim().toLowerCase(),
        displayName: displayName,
        photoUrl: '',
        authProvider: 'email',
        createdAt: DateTime.now(),
      );

      await _persistUser(user);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (name.trim().isEmpty) {
        throw Exception('Please enter your full name.');
      }
      if (!email.contains('@') || !email.contains('.')) {
        throw Exception('Please enter a valid email address.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      await Future.delayed(const Duration(milliseconds: 600));

      final user = UserProfile(
        uid: 'mail_${email.hashCode.abs()}',
        email: email.trim().toLowerCase(),
        displayName: name.trim(),
        photoUrl: '',
        authProvider: 'email',
        createdAt: DateTime.now(),
      );

      await _persistUser(user);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signInAsGuest() async {
    final now = DateTime.now();
    final user = UserProfile(
      uid: 'guest_${now.millisecondsSinceEpoch}',
      email: 'guest@getsetgo.app',
      displayName: 'Guest Explorer',
      photoUrl: '',
      authProvider: 'guest',
      createdAt: now,
    );
    await _persistUser(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('SignOut error: $e');
    }
  }

  Future<void> _persistUser(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson());
    } catch (e) {
      debugPrint('Failed to persist user: $e');
    }
  }
}
