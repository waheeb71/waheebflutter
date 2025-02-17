import 'package:camera/camera.dart';
import 'package:chatapp/Screens/CameraScreen.dart';
import 'package:chatapp/Screens/Homescreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // لتهيئة Firebase
import 'firebase_options.dart'; // ملف يُنشأ تلقائيًا عند إضافة Firebase

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة الكاميرات
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Error accessing cameras: $e");
    // يمكنك عرض رسالة خطأ للمستخدم إذا فشلت عملية الوصول إلى الكاميرا
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: "OpenSans",
        primaryColor: Color(0xFF075E54),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFF128C7E)),
      ),
      home: Homescreen(),
    );
  }
}