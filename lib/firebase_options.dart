import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for AttendX.
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
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoAttendXApiKeyWebForLocalTesting001',
    appId: '1:123456789012:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'attendx-smart-attendance',
    authDomain: 'attendx-smart-attendance.firebaseapp.com',
    storageBucket: 'attendx-smart-attendance.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoAttendXApiKeyAndroidLocalTesting02',
    appId: '1:123456789012:android:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'attendx-smart-attendance',
    storageBucket: 'attendx-smart-attendance.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoAttendXApiKeyIosForLocalTesting003',
    appId: '1:123456789012:ios:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'attendx-smart-attendance',
    storageBucket: 'attendx-smart-attendance.appspot.com',
    iosBundleId: 'com.attendx.attendx',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemoAttendXApiKeyWinForLocalTesting004',
    appId: '1:123456789012:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'attendx-smart-attendance',
    authDomain: 'attendx-smart-attendance.firebaseapp.com',
    storageBucket: 'attendx-smart-attendance.appspot.com',
  );
}
