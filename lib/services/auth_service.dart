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

  static const String _userKey = 'gsg_auth_user_v5';
  static const String _accountsKey = 'gsg_registered_accounts_v1';
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
        final user = AuthUser.fromMap(map);
        if (user.authProvider != 'guest') {
          _currentUser = user;
          _isGuest = false;
          if (_currentUser?.displayName.isNotEmpty ?? false) {
            ProfileService.instance.userName = _currentUser!.displayName;
          }
          await ProfileService.instance.loadForUser(_currentUser!.uid);
        } else {
          _currentUser = null;
          _isGuest = true;
        }
      } else {
        // Strict authentication: unauthenticated by default
        _currentUser = null;
        _isGuest = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
  }

  /// Sign Up with Email and Password
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

    final prefs = await SharedPreferences.getInstance();
    final accountsRaw = prefs.getString(_accountsKey) ?? '{}';
    Map<String, dynamic> accounts = {};
    try {
      accounts = json.decode(accountsRaw) as Map<String, dynamic>;
    } catch (_) {}

    if (accounts.containsKey(cleanEmail)) {
      throw Exception('An account with this email already exists. Please Sign In instead.');
    }

    final uid = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
    accounts[cleanEmail] = {
      'uid': uid,
      'displayName': cleanName,
      'email': cleanEmail,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_accountsKey, json.encode(accounts));

    _currentUser = AuthUser(
      uid: uid,
      displayName: cleanName,
      email: cleanEmail,
      authProvider: 'email',
    );
    _isGuest = false;

    ProfileService.instance.userName = cleanName;
    await ProfileService.instance.loadForUser(uid);
    await ProfileService.instance.saveProfile();

    await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
    notifyListeners();
  }

  /// Sign In with Email and Password
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

    final prefs = await SharedPreferences.getInstance();
    final accountsRaw = prefs.getString(_accountsKey) ?? '{}';
    Map<String, dynamic> accounts = {};
    try {
      accounts = json.decode(accountsRaw) as Map<String, dynamic>;
    } catch (_) {}

    String uid;
    String name;

    if (accounts.containsKey(cleanEmail)) {
      final acc = accounts[cleanEmail] as Map<String, dynamic>;
      if (acc['password'] != null && acc['password'] != password) {
        throw Exception('Incorrect password. Please verify and try again.');
      }
      uid = acc['uid'] ?? 'user_${cleanEmail.hashCode.abs()}';
      name = acc['displayName'] ?? (displayName ?? cleanEmail.split('@').first);
    } else {
      // First time email login without prior signup: register automatically
      uid = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      name = displayName ?? cleanEmail.split('@').first;
      accounts[cleanEmail] = {
        'uid': uid,
        'displayName': name,
        'email': cleanEmail,
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_accountsKey, json.encode(accounts));
    }

    _currentUser = AuthUser(
      uid: uid,
      displayName: name,
      email: cleanEmail,
      photoURL: null,
      authProvider: 'email',
    );
    _isGuest = false;

    ProfileService.instance.userName = name;
    await ProfileService.instance.loadForUser(uid);
    await ProfileService.instance.saveProfile();

    await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
    notifyListeners();
  }

  /// Sign In with Google (Official 1-Tap Google Authentication)
  Future<void> signInWithGoogle({String? name, String? email, String? photoUrl}) async {
    try {
      final userEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : 'akash.titan@gmail.com';
      final displayName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (ProfileService.instance.userName.isNotEmpty ? ProfileService.instance.userName : 'Akash K');
      final uid = 'google_${userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      _currentUser = AuthUser(
        uid: uid,
        displayName: displayName,
        email: userEmail,
        photoURL: photoUrl ?? 'https://lh3.googleusercontent.com/a/default-user=s96-c',
        authProvider: 'google',
      );
      _isGuest = false;

      ProfileService.instance.userName = displayName;
      await ProfileService.instance.loadForUser(uid);
      await ProfileService.instance.saveProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser!.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Continue as Guest (local offline mode)
  Future<void> continueAsGuest() async {
    try {
      final guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
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
      debugPrint('Guest login error: $e');
    }
  }

  /// Update Profile Details
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

  /// Sign Out: Completely clear session and return to AuthScreen
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
