import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        uid: map['uid'] ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: map['displayName'] ?? 'Akash K',
        email: map['email'] ?? 'akash.k@example.com',
        photoURL: map['photoURL'],
        authProvider: map['authProvider'] ?? 'google',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : DateTime.now(),
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String _userKey = 'gsg_auth_user_v4';
  AuthUser? _currentUser;
  bool _isGuest = false;

  AuthUser? get currentUser => _currentUser;
  bool get isGuest => _isGuest || _currentUser == null || _currentUser?.authProvider == 'guest';
  bool get isSignedIn => _currentUser != null && !_isGuest;
  String get uid => _currentUser?.uid ?? 'guest_uid';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_userKey);
      if (str != null) {
        final map = json.decode(str);
        _currentUser = AuthUser.fromMap(map);
        _isGuest = _currentUser?.authProvider == 'guest';
        if (_currentUser?.displayName != null && _currentUser!.displayName.isNotEmpty) {
          ProfileService.instance.userName = _currentUser!.displayName;
        }
      } else {
        // Default authenticated active user
        _currentUser = AuthUser(
          uid: 'user_akash_290605',
          displayName: 'Akash K',
          email: 'akash.titan@gmail.com',
          authProvider: 'google',
        );
        _isGuest = false;
        await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
  }

  Future<void> signInWithGoogle({String? name, String? email, String? photoUrl}) async {
    try {
      final displayName = name ?? (ProfileService.instance.userName.isNotEmpty ? ProfileService.instance.userName : 'Akash K');
      final userEmail = email ?? 'akash.titan@gmail.com';
      
      _currentUser = AuthUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: displayName,
        email: userEmail,
        photoURL: photoUrl ?? 'https://avatars.githubusercontent.com/u/203824386?v=4',
        authProvider: 'google',
      );
      _isGuest = false;

      ProfileService.instance.userName = displayName;
      await ProfileService.instance.saveProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password, {String? displayName}) async {
    try {
      final name = displayName ?? email.split('@').first;
      _currentUser = AuthUser(
        uid: 'user_email_${email.hashCode.abs()}',
        displayName: name,
        email: email,
        photoURL: null,
        authProvider: 'email',
      );
      _isGuest = false;

      ProfileService.instance.userName = name;
      await ProfileService.instance.saveProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Email Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    try {
      _currentUser = AuthUser(
        uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Athlete',
        email: 'guest@getsetgo.app',
        authProvider: 'guest',
      );
      _isGuest = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Guest login error: $e');
    }
  }

  Future<void> updateProfile({required String displayName, required String email, String? photoURL}) async {
    if (_currentUser == null) return;
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

  Future<void> signOut() async {
    _currentUser = AuthUser(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Guest User',
      email: 'guest@getsetgo.app',
      authProvider: 'guest',
    );
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
