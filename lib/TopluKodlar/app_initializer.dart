import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Logonun ekranda bir süre görünmesi için kısa bir bekleme (Splash Screen efekti)
    await Future.delayed(const Duration(seconds: 2));

    // Firebase Auth üzerinden cihazda kayıtlı mevcut kullanıcıyı kontrol ediyoruz
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (currentUser != null) {
        // Oturum açmış kullanıcı varsa doğrudan Ana Sayfaya yönlendir
        context.go('/home');
      } else {
        // Oturum yoksa Giriş Ekranına yönlendir
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ekranda görünecek geçici logomuz ve yükleme animasyonu
            Icon(Icons.school, size: 100, color: Colors.blueAccent),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Sistem Başlatılıyor...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}