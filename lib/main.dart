import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialization for Web vs Mobile
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCQH9Mb3fXCEACSo7ZxpBlaxfITWxT_BDI",
        authDomain: "ayurbloom.firebaseapp.com",
        projectId: "ayurbloom",
        storageBucket: "ayurbloom.firebasestorage.app",
        messagingSenderId: "239624593736",
        appId: "1:239624593736:web:192ca43097d986c3abd37d",
      ),
    );
  } else {
    await Firebase.initializeApp(); // Android/iOS use google-services.json
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AyurBloom',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(),
    );
  }
}
