// This is a placeholder firebase_options.dart file.
// It will be overwritten by running: flutterfire configure
//
// To generate the real file:
// 1. Run: firebase login
// 2. Run: flutterfire configure
//
// This placeholder allows the project to compile before Firebase is configured.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these with your actual Firebase project values

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkstx7YQznEgpZiV1fUu_EzUITgOHNMLY',
    appId: '1:615104569677:android:1380ddf9f1b9f6b2b25704',
    messagingSenderId: '615104569677',
    projectId: 'sachdrishti',
    storageBucket: 'sachdrishti.firebasestorage.app',
  );

  // Run `flutterfire configure` to auto-generate this file

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBo6eHPvG2fWOVCaYVPUzs9q7lXTpue1fY',
    appId: '1:615104569677:ios:b34c32409508b357b25704',
    messagingSenderId: '615104569677',
    projectId: 'sachdrishti',
    storageBucket: 'sachdrishti.firebasestorage.app',
    iosBundleId: 'com.sachcheck.sachcheck',
  );

}