import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/expandable_card.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/services/setup_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
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
    const Center(child: Text('Test ve Sınav Merkezi\n(Çok Yakında)', textAlign: TextAlign.center, style: TextStyle(fontSize: 20))),
    const ProfileScreen(),
  ];

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
            
            // 1. Çalışma Programım
            _buildDrawerItem(icon: Icons.calendar_month, title: 'Çalışma Programım', onTap: () {}),
            
            // 2. Sorumluluklar ve Ödevler
            _buildDrawerItem(icon: Icons.task_alt, title: 'Sorumluluklar ve Ödevler', onTap: () {}),

            // 3. Test ve Sınav Merkezi
            ExpansionTile(
              leading: const Icon(Icons.edit_document, color: Colors.blueAccent),
              title: const Text('Test ve Sınav Merkezi', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Manuel Test/Deneme Girişi', style: TextStyle(fontSize: 14)),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 56.0),
                  title: const Text('Optikli Test/Deneme Girişi', style: TextStyle(fontSize: 14)),
                  onTap: () {},
                ),
              ],
            ),

            // 4. Akademik Çalışma Odası
            ExpansionTile(
              leading: const Icon(Icons.video_library, color: Colors.blueAccent),
              title: const Text('Akademik Çalışma Odası', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Google Arama Kısayolları', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('PDF Föyler', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Videolar', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Gömülü Ders Linkleri', style: TextStyle(fontSize: 14)), onTap: () {}),
              ],
            ),

            // 5. Detaylı Analiz ve Röntgen
            ExpansionTile(
              leading: const Icon(Icons.analytics, color: Colors.blueAccent),
              title: const Text('Detaylı Analiz ve Röntgen', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Zaman Bazlı Özetler', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Sınav Röntgenleri', style: TextStyle(fontSize: 14)), onTap: () {}),
                
                // İçiçe menü (Dinamik Aksiyon Listeleri)
                ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 56.0, right: 16.0),
                  title: const Text('Dinamik Aksiyon Listeleri', style: TextStyle(fontSize: 14)),
                  children: [
                    ListTile(contentPadding: const EdgeInsets.only(left: 72.0), title: const Text('Tamamlanmış konular', style: TextStyle(fontSize: 13)), onTap: () {}),
                    ListTile(contentPadding: const EdgeInsets.only(left: 72.0), title: const Text('Soru çözülerek tamamlanacaklar', style: TextStyle(fontSize: 13)), onTap: () {}),
                    ListTile(contentPadding: const EdgeInsets.only(left: 72.0), title: const Text('Konu çalışılacaklar', style: TextStyle(fontSize: 13)), onTap: () {}),
                    ListTile(contentPadding: const EdgeInsets.only(left: 72.0), title: const Text('Öğretmene sorulacaklar', style: TextStyle(fontSize: 13)), onTap: () {}),
                  ],
                ),
              ],
            ),

            // 6. Rehberlik ve Yönlendirme
            ExpansionTile(
              leading: const Icon(Icons.explore, color: Colors.blueAccent),
              title: const Text('Rehberlik ve Yönlendirme', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Kılavuz', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('S.S.S.', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Sınav Sistemleri Tanıtımı', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Faydalı Linkler/Videolar', style: TextStyle(fontSize: 14)), onTap: () {}),
              ],
            ),

            // 7. Envanter Sistemi
            ExpansionTile(
              leading: const Icon(Icons.psychology, color: Colors.blueAccent),
              title: const Text('Envanter Sistemi', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Meslek Eğilim', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Öğrenme Stilleri', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Sınav Kaygısı', style: TextStyle(fontSize: 14)), onTap: () {}),
              ],
            ),

            // 8. Sosyal ve Akademik Ağ (FAZ 2)
            ExpansionTile(
              leading: const Icon(Icons.people_alt, color: Colors.grey),
              title: const Text('Sosyal ve Akademik Ağ (FAZ 2)', style: TextStyle(fontSize: 16, color: Colors.grey)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Akran Eşleşmesi', style: TextStyle(fontSize: 14, color: Colors.grey)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Öğretmen Bul ve Soru Sor', style: TextStyle(fontSize: 14, color: Colors.grey)), onTap: () {}),
              ],
            ),

            const Divider(),
            
            // 9. Ayarlar ve KVKK
            ExpansionTile(
              leading: const Icon(Icons.settings, color: Colors.blueAccent),
              title: const Text('Ayarlar', style: TextStyle(fontSize: 16)),
              children: [
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Şifre Değiştirme', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('Bildirim Tercihleri', style: TextStyle(fontSize: 14)), onTap: () {}),
                ListTile(contentPadding: const EdgeInsets.only(left: 56.0), title: const Text('KVKK Dökümü Görüntüleme', style: TextStyle(fontSize: 14)), onTap: () {}),
              ],
            ),
            
            _buildDrawerItem(icon: Icons.exit_to_app, title: 'Çıkış Yap', onTap: () async {
              await context.read<AuthProvider>().signOut();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
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