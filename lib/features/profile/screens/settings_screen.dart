import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handlePasswordUpdate() async {
    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showSnackBar(
        'Yeni şifre en az 6 karakter olmalıdır.',
        Colors.red,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar(
        'Yeni şifre ve tekrar alanı eşleşmiyor.',
        Colors.red,
      );
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) {
      _showSnackBar(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
        Colors.red,
      );
      return;
    }

    try {
      await currentUser.updatePassword(newPassword);
      if (!mounted) {
        return;
      }
      _showSnackBar('Şifreniz başarıyla güncellendi', Colors.green);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        try {
          final credential = EmailAuthProvider.credential(
            email: currentUser.email!,
            password: currentPassword,
          );
          await currentUser.reauthenticateWithCredential(credential);
          await currentUser.updatePassword(newPassword);

          if (!mounted) {
            return;
          }
          _showSnackBar('Şifreniz başarıyla güncellendi', Colors.green);
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } on FirebaseAuthException catch (reauthError) {
          if (!mounted) {
            return;
          }
          _showSnackBar(
            reauthError.code == 'wrong-password'
                ? 'Mevcut şifre yanlış.'
                : 'Şifre güncellenemedi: ${reauthError.message ?? 'Bilinmeyen hata'}',
            Colors.red,
          );
        } catch (_) {
          if (!mounted) {
            return;
          }
          _showSnackBar(
            'Şifre güncellenemedi. Lütfen tekrar deneyin.',
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          error.message ?? 'Şifre güncellenemedi.',
          Colors.red,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar(
        'Şifre güncellenemedi. Lütfen tekrar deneyin.',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre ve Hesap Ayarları')),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Şifre ve Hesap Ayarları',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu ekrandan şifrenizi güvenli şekilde güncelleyebilirsiniz.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mevcut Şifre',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          prefixIcon: Icon(Icons.lock_reset),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre Tekrar',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handlePasswordUpdate,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Kaydet'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
