// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBF_GpLxVb7kTrFrgD1V6a_26EBX44Tcuo',
    appId: '1:1018485225472:web:fb865b7c6ba445c05240e5',
    messagingSenderId: '1018485225472',
    projectId: 'step-coin-27b92',
    authDomain: 'step-coin-27b92.firebaseapp.com',
    storageBucket: 'step-coin-27b92.appspot.com',
    measurementId: 'G-MFSYQVH80S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANMDQZyXA53_fyysOGeQ1gdgt2YSbljCg',
    appId: '1:1018485225472:android:5c5362ff1cd032a05240e5',
    messagingSenderId: '1018485225472',
    projectId: 'step-coin-27b92',
    storageBucket: 'step-coin-27b92.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTWCpKUvLSrb083ejSTKNN9XliT_Z3t4E',
    appId: '1:1018485225472:ios:6161bf877fd61eef5240e5',
    messagingSenderId: '1018485225472',
    projectId: 'step-coin-27b92',
    storageBucket: 'step-coin-27b92.appspot.com',
    iosBundleId: 'com.example.stepCoin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDTWCpKUvLSrb083ejSTKNN9XliT_Z3t4E',
    appId: '1:1018485225472:ios:6161bf877fd61eef5240e5',
    messagingSenderId: '1018485225472',
    projectId: 'step-coin-27b92',
    storageBucket: 'step-coin-27b92.appspot.com',
    iosBundleId: 'com.example.stepCoin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBF_GpLxVb7kTrFrgD1V6a_26EBX44Tcuo',
    appId: '1:1018485225472:web:1cc170e4d3ad5a4e5240e5',
    messagingSenderId: '1018485225472',
    projectId: 'step-coin-27b92',
    authDomain: 'step-coin-27b92.firebaseapp.com',
    storageBucket: 'step-coin-27b92.appspot.com',
    measurementId: 'G-4N2GFEDLF2',
  );
}
