import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = (authProvider.currentUserData?['role'] ?? '').toString().toLowerCase();
    final isim = authProvider.currentUserData?['name'];
    final canSeeAdminSections = role == 'admin';
    final canSeeUserManagement =
        role == 'admin' || role == 'yönetici' || role == 'koc' || role == 'koç';
    final canSeeTopicManagement = canSeeUserManagement;
    final headerTitle = (isim != null && isim.toString().isNotEmpty)
        ? 'Hoş Geldin,\n$isim'
        : 'Öğrenci Paneli';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- Drawer Başlığı ---
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.school, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  headerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // --- Çalışma Programım ---
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blueAccent),
            title: const Text('Çalışma Programım', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              context.go('/study-program');
            },
          ),

          // --- Test ve Sınav Merkezi ---
          ExpansionTile(
            leading: const Icon(Icons.edit_document, color: Colors.blueAccent),
            title: const Text('Test ve Sınav Merkezi', style: TextStyle(fontSize: 16)),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Test Girişleri', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/exams?mode=test');
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Deneme Girişleri', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/exams?mode=deneme');
                },
              ),
            ],
          ),

          // --- Durum Analizi ---
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.blueAccent),
            title: const Text('Durum Analizi', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              context.go('/analysis');
            },
          ),

          // --- Akademik Çalışma Odası ---
          ListTile(
            leading: const Icon(Icons.play_lesson, color: Colors.blueAccent),
            title: const Text('Akademik Çalışma Odası', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              context.go('/academic-study-room');
            },
          ),

          // --- Rehberlik ve Yönlendirme ---
          ListTile(
            leading: const Icon(Icons.explore, color: Colors.blueAccent),
            title: const Text('Rehberlik ve Yönlendirme', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              context.go('/guidance-counseling');
            },
          ),

          // --- Envanter Sistemi ---
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.blueAccent),
            title: const Text('Envanter Sistemi', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              context.go('/inventory-system');
            },
          ),

          const Divider(),

          // --- Ayarlar ---
          ExpansionTile(
            leading: const Icon(Icons.settings, color: Colors.blueAccent),
            title: const Text('Ayarlar', style: TextStyle(fontSize: 16)),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Şifre Değiştirme', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
              if (canSeeUserManagement)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Kullanıcı İşlemleri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/user-management');
                  },
                ),
              if (canSeeTopicManagement)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Müfredat İşlemleri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/topic-management');
                  },
                ),
              if (canSeeAdminSections)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Sistem Kurulumu (Admin)', style: TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context); // Menüyü kapat
                    context.go('/admin-settings'); // Admin sayfasına git
                  },
                ),
            ],
          ),

          // --- Çıkış Yap ---
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            title: const Text('Çıkış Yap', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) context.go('/login');
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}