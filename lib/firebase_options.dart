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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfzbzXoJ0H_AuSSm5kQCxLvFCsOMPCNYE',
    appId: '1:863212987296:android:0fb4bc03c978163cb8bac5',
    messagingSenderId: '863212987296',
    projectId: 'cybercode-9f025',
    storageBucket: 'cybercode-9f025.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAlRkfWsiJrpx2XmaRsxRCLpLmCfYYaqwQ',
    appId: '1:863212987296:ios:52006e33bbbfa8cab8bac5',
    messagingSenderId: '863212987296',
    projectId: 'cybercode-9f025',
    storageBucket: 'cybercode-9f025.firebasestorage.app',
    androidClientId: '863212987296-4k0ft9ifibq5ehbviqecf7su68spf68t.apps.googleusercontent.com',
    iosClientId: '863212987296-7utep5h33vbpr55j6qen7p351q76q7nt.apps.googleusercontent.com',
    iosBundleId: 'com.example.waheeb',
  );
}
