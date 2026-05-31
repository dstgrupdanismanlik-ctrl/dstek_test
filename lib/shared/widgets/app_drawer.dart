import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Uygulamanın her ekranında kullanılabilen evrensel Drawer widget'ı.
///
/// HomeScreen'e özgü state işlemleri (sınav modu seçimi, özel body gösterimi vb.)
/// isteğe bağlı [callback]'ler aracılığıyla enjekte edilir.
/// Callback sağlanmazsa ilgili öğe go_router üzerinden [fallbackRoute]'a yönlendirir.
class AppDrawer extends StatelessWidget {
  /// Test girişleri alanı seçildiğinde çağrılır (HomeScreen'e özgü).
  final VoidCallback? onExamTestTap;

  /// Deneme girişleri alanı seçildiğinde çağrılır (HomeScreen'e özgü).
  final VoidCallback? onExamPracticeTap;

  /// Akademik Çalışma Odası seçildiğinde çağrılır. null ise '/academic-study-room' rotasına gider.
  final VoidCallback? onStudyRoomTap;

  /// Rehberlik ve Yönlendirme seçildiğinde çağrılır (HomeScreen'e özgü).
  final VoidCallback? onGuidanceTap;

  /// Envanter Sistemi seçildiğinde çağrılır (HomeScreen'e özgü).
  final VoidCallback? onInventoryTap;

  /// Sorumluluklar ve Ödevler seçildiğinde çağrılır (HomeScreen'e özgü).
  final VoidCallback? onTasksTap;

  const AppDrawer({
    super.key,
    this.onExamTestTap,
    this.onExamPracticeTap,
    this.onStudyRoomTap,
    this.onGuidanceTap,
    this.onInventoryTap,
    this.onTasksTap,
  });

  /// Drawer'ı kapatır, callback varsa çalıştırır; yoksa [fallbackRoute]'a gider.
  void _handleTap(BuildContext context, VoidCallback? callback, String fallbackRoute) {
    Navigator.pop(context);
    if (callback != null) {
      callback();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- Drawer Başlığı ---
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.school, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Öğrenci Paneli',
                  style: TextStyle(
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

          // --- Sorumluluklar ve Ödevler ---
          ListTile(
            leading: const Icon(Icons.task_alt, color: Colors.blueAccent),
            title: const Text('Sorumluluklar ve Ödevler', style: TextStyle(fontSize: 16)),
            onTap: () => _handleTap(context, onTasksTap, '/home'),
          ),

          // --- Test ve Sınav Merkezi ---
          ExpansionTile(
            leading: const Icon(Icons.edit_document, color: Colors.blueAccent),
            title: const Text('Test ve Sınav Merkezi', style: TextStyle(fontSize: 16)),
            initiallyExpanded: true,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Test girişleri alanı', style: TextStyle(fontSize: 14)),
                onTap: () => _handleTap(context, onExamTestTap, '/home'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Deneme girişleri alanı', style: TextStyle(fontSize: 14)),
                onTap: () => _handleTap(context, onExamPracticeTap, '/home'),
              ),
            ],
          ),

          // --- Akademik Çalışma Odası ---
          ListTile(
            leading: const Icon(Icons.play_lesson, color: Colors.blueAccent),
            title: const Text('Akademik Çalışma Odası', style: TextStyle(fontSize: 16)),
            onTap: () => _handleTap(context, onStudyRoomTap, '/academic-study-room'),
          ),

          // --- Detaylı Analiz ve Röntgen ---
          ExpansionTile(
            leading: const Icon(Icons.analytics, color: Colors.blueAccent),
            title: const Text('Detaylı Analiz ve Röntgen', style: TextStyle(fontSize: 16)),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Zaman Bazlı Özetler', style: TextStyle(fontSize: 14)),
                onTap: () {},
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56.0),
                title: const Text('Sınav Röntgenleri', style: TextStyle(fontSize: 14)),
                onTap: () {},
              ),
            ],
          ),

          // --- Rehberlik ve Yönlendirme ---
          ListTile(
            leading: const Icon(Icons.explore, color: Colors.blueAccent),
            title: const Text('Rehberlik ve Yönlendirme', style: TextStyle(fontSize: 16)),
            onTap: () => _handleTap(context, onGuidanceTap, '/home'),
          ),

          // --- Envanter Sistemi ---
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.blueAccent),
            title: const Text('Envanter Sistemi', style: TextStyle(fontSize: 16)),
            onTap: () => _handleTap(context, onInventoryTap, '/home'),
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
                onTap: () {},
              ),
            ],
          ),

          // --- Çıkış Yap ---
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.blueAccent),
            title: const Text('Çıkış Yap', style: TextStyle(fontSize: 16)),
            onTap: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
