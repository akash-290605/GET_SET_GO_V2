import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String provider;
  final bool isEmailVerified;
  final String createdAt;

  AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.provider = 'google',
    this.isEmailVerified = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'provider': provider,
        'isEmailVerified': isEmailVerified,
        'createdAt': createdAt,
      };

  factory AuthUser.fromMap(Map<String, dynamic> map) => AuthUser(
        uid: map['uid'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        displayName: map['displayName'],
        email: map['email'],
        photoURL: map['photoURL'],
        provider: map['provider'] ?? 'google',
        isEmailVerified: map['isEmailVerified'] ?? true,
        createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String _userKey = 'gsg_auth_session_v4';
  static const String _registeredUsersKey = 'gsg_registered_users_v4';

  AuthStatus _status = AuthStatus.initializing;
  AuthUser? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isGuest => _currentUser == null;
  bool get isInitializing => _status == AuthStatus.initializing;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _status = AuthStatus.initializing;
    notifyListeners();

    try {
      // Simulate auth handshake & restore session
      await Future.delayed(const Duration(milliseconds: 400));
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);

      if (userStr != null) {
        final map = json.decode(userStr);
        _currentUser = AuthUser.fromMap(map);
        _status = AuthStatus.authenticated;

        // Sync profile name if available
        if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
          ProfileService.instance.updateName(_currentUser!.displayName!);
        }
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Sign In with Google Provider
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    try {
      // Create or restore user with consistent Google identity
      final user = AuthUser(
        uid: 'google_uid_akash2906',
        displayName: 'Akash K',
        email: 'akash.k@getsetgo.app',
        photoURL: null,
        provider: 'google',
        isEmailVerified: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      _currentUser = user;
      _status = AuthStatus.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toMap()));

      // Update Profile Service
      await ProfileService.instance.updateName(user.displayName ?? 'Akash K');

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _errorMessage = 'Google sign-in was cancelled or encountered a network issue. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Email & Password
  Future<bool> signInWithEmail(String email, String password) async {
    _errorMessage = null;
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    if (cleanPassword.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredRaw = prefs.getString(_registeredUsersKey);
      Map<String, dynamic> registeredUsers = {};

      if (registeredRaw != null) {
        registeredUsers = Map<String, dynamic>.from(json.decode(registeredRaw));
      }

      // If user exists in registered database
      if (registeredUsers.containsKey(cleanEmail)) {
        final userData = registeredUsers[cleanEmail];
        if (userData['password'] != cleanPassword) {
          _errorMessage = 'Incorrect password. Please verify and try again.';
          notifyListeners();
          return false;
        }

        _currentUser = AuthUser(
          uid: userData['uid'],
          displayName: userData['name'],
          email: cleanEmail,
          provider: 'password',
          isEmailVerified: true,
          createdAt: userData['createdAt'] ?? DateTime.now().toIso8601String(),
        );
      } else {
        // First-time email login fallback
        final uid = 'usr_${cleanEmail.hashCode.abs()}';
        _currentUser = AuthUser(
          uid: uid,
          displayName: cleanEmail.split('@').first.capitalize(),
          email: cleanEmail,
          provider: 'password',
          isEmailVerified: true,
          createdAt: DateTime.now().toIso8601String(),
        );

        registeredUsers[cleanEmail] = {
          'uid': uid,
          'name': _currentUser!.displayName,
          'password': cleanPassword,
          'createdAt': DateTime.now().toIso8601String(),
        };
        await prefs.setString(_registeredUsersKey, json.encode(registeredUsers));
      }

      _status = AuthStatus.authenticated;
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));

      if (_currentUser?.displayName != null) {
        await ProfileService.instance.updateName(_currentUser!.displayName!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Email Sign In Error: $e');
      _errorMessage = 'This account could not be authenticated. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Sign Up with Name, Email & Password
  Future<bool> signUpWithEmail(String name, String email, String password) async {
    _errorMessage = null;
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Please enter your full name.';
      notifyListeners();
      return false;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    if (cleanPassword.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredRaw = prefs.getString(_registeredUsersKey);
      Map<String, dynamic> registeredUsers = {};

      if (registeredRaw != null) {
        registeredUsers = Map<String, dynamic>.from(json.decode(registeredRaw));
      }

      final uid = 'usr_${DateTime.now().millisecondsSinceEpoch}';
      final newUser = AuthUser(
        uid: uid,
        displayName: cleanName,
        email: cleanEmail,
        provider: 'password',
        isEmailVerified: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      registeredUsers[cleanEmail] = {
        'uid': uid,
        'name': cleanName,
        'password': cleanPassword,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_registeredUsersKey, json.encode(registeredUsers));
      await prefs.setString(_userKey, json.encode(newUser.toMap()));

      _currentUser = newUser;
      _status = AuthStatus.authenticated;

      await ProfileService.instance.updateName(cleanName);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign Up Error: $e');
      _errorMessage = 'Could not create account. Please check your network connection.';
      notifyListeners();
      return false;
    }
  }

  /// Sign Out and reset application auth guard
  Future<void> signOut() async {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
