import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileData {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final bool isGuest;
  final DateTime createdAt;

  UserProfileData({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl = '',
    this.isGuest = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'isGuest': isGuest,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfileData.fromMap(Map<String, dynamic> map) => UserProfileData(
    uid: map['uid']?.toString() ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
    displayName: map['displayName']?.toString() ?? 'Athlete',
    email: map['email']?.toString() ?? 'user@getsetgo.app',
    photoUrl: map['photoUrl']?.toString() ?? '',
    isGuest: map['isGuest'] == true || map['isGuest'] == 1,
    createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
  );

  String toJson() => json.encode(toMap());
  factory UserProfileData.fromJson(String source) => UserProfileData.fromMap(json.decode(source));
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  AuthService._internal();

  UserProfileData? _currentUser;
  bool _isLoading = false;

  UserProfileData? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? true;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('auth_current_user');
      if (userJson != null) {
        _currentUser = UserProfileData.fromJson(userJson);
      } else {
        // Default to initialized guest session if none exists
        _currentUser = UserProfileData(
          uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Akash K',
          email: 'akash@getsetgo.app',
          photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
          isGuest: false,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Smooth UX transition
      _currentUser = UserProfileData(
        uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Akash K (Google Verified)',
        email: 'akash290605@gmail.com',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
        isGuest: false,
        createdAt: DateTime.now(),
      );
      await _saveUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final name = email.split('@').first;
      _currentUser = UserProfileData(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: name.isNotEmpty ? name.toUpperCase() : 'Athlete',
        email: email,
        photoUrl: '',
        isGuest: false,
        createdAt: DateTime.now(),
      );
      await _saveUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> continueAsGuest() async {
    _currentUser = UserProfileData(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Guest Athlete',
      email: 'guest@getsetgo.local',
      photoUrl: '',
      isGuest: true,
      createdAt: DateTime.now(),
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_current_user');
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email, String? photoUrl}) async {
    if (_currentUser == null) return;
    _currentUser = UserProfileData(
      uid: _currentUser!.uid,
      displayName: name ?? _currentUser!.displayName,
      email: email ?? _currentUser!.email,
      photoUrl: photoUrl ?? _currentUser!.photoUrl,
      isGuest: _currentUser!.isGuest,
      createdAt: _currentUser!.createdAt,
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> _saveUser() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_current_user', _currentUser!.toJson());
  }
}
