import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


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
    apiKey: 'AIzaSyAalBvjn9HOjmRSsApKgvtkvt7VwX2iYws',
    appId: '1:42221391863:web:fb6be4667717711e06e8f2',
    messagingSenderId: '42221391863',
    projectId: 'glomags-tire-center-d3745',
    authDomain: 'glomags-tire-center-d3745.firebaseapp.com',
    storageBucket: 'glomags-tire-center-d3745.firebasestorage.app',
    measurementId: 'G-C67TEM1TCN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTxVT6v1sFfF_oKnaBt30UhqXxT9c7oaE',
    appId: '1:42221391863:android:9ac8c670179b155e06e8f2',
    messagingSenderId: '42221391863',
    projectId: 'glomags-tire-center-d3745',
    storageBucket: 'glomags-tire-center-d3745.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBnIHVNnXaNrup5nNXffmoflU7ENjvpuCI',
    appId: '1:42221391863:ios:5b1243b51ec8503906e8f2',
    messagingSenderId: '42221391863',
    projectId: 'glomags-tire-center-d3745',
    storageBucket: 'glomags-tire-center-d3745.firebasestorage.app',
    iosBundleId: 'com.example.glomagsTireApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBnIHVNnXaNrup5nNXffmoflU7ENjvpuCI',
    appId: '1:42221391863:ios:5b1243b51ec8503906e8f2',
    messagingSenderId: '42221391863',
    projectId: 'glomags-tire-center-d3745',
    storageBucket: 'glomags-tire-center-d3745.firebasestorage.app',
    iosBundleId: 'com.example.glomagsTireApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAalBvjn9HOjmRSsApKgvtkvt7VwX2iYws',
    appId: '1:42221391863:web:a916367a1982075806e8f2',
    messagingSenderId: '42221391863',
    projectId: 'glomags-tire-center-d3745',
    authDomain: 'glomags-tire-center-d3745.firebaseapp.com',
    storageBucket: 'glomags-tire-center-d3745.firebasestorage.app',
    measurementId: 'G-F8D32MYW9T',
  );
}
