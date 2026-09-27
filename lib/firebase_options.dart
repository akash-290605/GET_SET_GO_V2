// File generated for GET SET GO Firebase Configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLCdiMkagwwF7KdaeVk-QR4hP5gsOBHcs',
    appId: '1:159071674059:web:dc5507a78921237dc4054e',
    messagingSenderId: '159071674059',
    projectId: 'get-set-go-10897',
    authDomain: 'get-set-go-10897.firebaseapp.com',
    storageBucket: 'get-set-go-10897.firebasestorage.app',
    measurementId: 'G-99CEQ2FWFV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVlkNqbGHwxrbinMBvoDAKJQHpA7hwJu8',
    appId: '1:159071674059:android:d3575b80e17bee2dc4054e',
    messagingSenderId: '159071674059',
    projectId: 'get-set-go-10897',
    storageBucket: 'get-set-go-10897.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLCdiMkagwwF7KdaeVk-QR4hP5gsOBHcs',
    appId: '1:159071674059:web:dc5507a78921237dc4054e',
    messagingSenderId: '159071674059',
    projectId: 'get-set-go-10897',
    storageBucket: 'get-set-go-10897.firebasestorage.app',
    measurementId: 'G-99CEQ2FWFV',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLCdiMkagwwF7KdaeVk-QR4hP5gsOBHcs',
    appId: '1:159071674059:web:dc5507a78921237dc4054e',
    messagingSenderId: '159071674059',
    projectId: 'get-set-go-10897',
    storageBucket: 'get-set-go-10897.firebasestorage.app',
    measurementId: 'G-99CEQ2FWFV',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCLCdiMkagwwF7KdaeVk-QR4hP5gsOBHcs',
    appId: '1:159071674059:web:dc5507a78921237dc4054e',
    messagingSenderId: '159071674059',
    projectId: 'get-set-go-10897',
    storageBucket: 'get-set-go-10897.firebasestorage.app',
    measurementId: 'G-99CEQ2FWFV',
  );
}
