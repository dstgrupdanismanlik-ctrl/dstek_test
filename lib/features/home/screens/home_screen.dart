import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/expandable_card.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/services/setup_service.dart';
import '../../exams/screens/exam_entry_screen.dart'; // Yeni ekranı import ettik
import '../../../screens/academic_study_room_screen.dart';
import '../../../screens/guidance_counseling_screen.dart';
import '../../../screens/inventory_system_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedExamMode = 0; // 0: Test Girişleri, 1: Deneme Girişleri
  Widget? _customBody;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dinamik geçiş yapabilmesi için Listeyi build metodunun içine aldık
    final List<Widget> pages = [
      ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text('Hoş Geldin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ExpandableCard(title: 'Günün Motivasyonu', icon: Icons.star, content: 'Başarı, küçük çabaların her gün tekrarlanmasıdır.'),
          SizedBox(height: 16),
          ExpandableCard(title: 'Koçluk Notları', icon: Icons.note_alt, content: 'Matematik branşında oran orantı konusuna ağırlık verilmeli.'),
        ],
      ),
      const Center(child: Text('Çalışma Programım\n(Çok Yakında)', textAlign: TextAlign.center, style: TextStyle(fontSize: 20))),
      // Tıklanan menüye göre Test veya Deneme arayüzü çağrılır
      _selectedExamMode == 0 ? const TestEntryScreen() : const PracticeExamEntryScreen(),
      const ProfileScreen(),
    ];

    final Widget bodyWidget = _customBody ?? pages[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('DSTEK'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.redAccent),
            tooltip: 'Sistem Sabitlerini Yükle',
            onPressed: () async {
              await SetupService().initializeSystemConstants(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.school, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Öğrenci Paneli', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.calendar_month, title: 'Çalışma Programım', onTap: () {
              Navigator.pop(context);
              context.go('/study-program');
            }),
            _buildDrawerItem(icon: Icons.task_alt, title: 'Sorumluluklar ve Ödevler', onTap: () { setState(() { _customBody = null; }); }),
            
            // YENİDEN DÜZENLENEN TEST VE SINAV MERKEZİ MENÜSÜ
            ExpansionTile(
              leading: const Icon(Icons.edit_document, color: Colors.blueAccent),
              title: const Text('Test ve Sınav Merkezi', style: TextStyle(fontSize: 16)),
              initiallyExpanded: true,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Test girişleri alanı', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    setState(() {
                      _selectedExamMode = 0; // Test modu
                      _selectedIndex = 2; // Sınavlar sekmesini aç
                      _customBody = null;
                    });
                    Navigator.pop(context); // Menüyü kapat
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Deneme girişleri alanı', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    setState(() {
                      _selectedExamMode = 1; // Deneme modu
                      _selectedIndex = 2; // Sınavlar sekmesini aç
                      _customBody = null;
                    });
                    Navigator.pop(context); // Menüyü kapat
                  },
                ),
                // Akademik Çalışma Odası (taşındı, artık buradan kaldırıldı)
              ],
            ),
            
            // Old 'Akademik Çalışma Odası' draft removed (was an ExpansionTile)

            // Akademik Çalışma Odası (ana menü öğesi)
            ListTile(
              leading: const Icon(Icons.play_lesson, color: Colors.blueAccent),
              title: const Text('Akademik Çalışma Odası', style: TextStyle(fontSize: 16)),
              onTap: () {
                setState(() {
                  _customBody = const AcademicStudyRoomScreen();
                });
                Navigator.pop(context);
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.analytics, color: Colors.blueAccent),
              title: const Text('Detaylı Analiz ve Röntgen', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Zaman Bazlı Özetler', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Sınav Röntgenleri', style: TextStyle(fontSize: 14)), onTap: () {}),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.explore, color: Colors.blueAccent),
              title: const Text('Rehberlik ve Yönlendirme', style: TextStyle(fontSize: 16)),
              onTap: () {
                setState(() {
                  _customBody = GuidanceCounselingScreen();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology, color: Colors.blueAccent),
              title: const Text('Envanter Sistemi', style: TextStyle(fontSize: 16)),
              onTap: () {
                setState(() {
                  _customBody = InventorySystemScreen();
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.settings, color: Colors.blueAccent),
              title: const Text('Ayarlar', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Şifre Değiştirme', style: TextStyle(fontSize: 14)), onTap: () {}),
              ],
            ),
            _buildDrawerItem(icon: Icons.exit_to_app, title: 'Çıkış Yap', onTap: () async {
              await context.read<AuthProvider>().signOut();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: bodyWidget,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Programım'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Sınavlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}