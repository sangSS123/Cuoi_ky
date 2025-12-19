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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBG2K1brTTWgixFFwFTvNG5ZrQxTUu2Cj4',
    appId: '1:103618453854:web:350f146a06c354d8ff2fcf',
    messagingSenderId: '103618453854',
    projectId: 'hatgiong-ban',
    authDomain: 'hatgiong-ban.firebaseapp.com',
    storageBucket: 'hatgiong-ban.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6x3F3KJBHgHK-5ye5q5AFaDtHU5GF49s',
    appId: '1:103618453854:android:58d84d166a1a0627ff2fcf',
    messagingSenderId: '103618453854',
    projectId: 'hatgiong-ban',
    storageBucket: 'hatgiong-ban.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBG2K1brTTWgixFFwFTvNG5ZrQxTUu2Cj4',
    appId: '1:103618453854:web:31e733b9f7036ab0ff2fcf',
    messagingSenderId: '103618453854',
    projectId: 'hatgiong-ban',
    authDomain: 'hatgiong-ban.firebaseapp.com',
    storageBucket: 'hatgiong-ban.appspot.com',
  );
}
