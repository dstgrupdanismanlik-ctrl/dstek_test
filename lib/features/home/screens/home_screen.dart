import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/expandable_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/services/setup_service.dart';
import '../../exams/screens/exam_entry_screen.dart';
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
      drawer: AppDrawer(
        onExamTestTap: () {
          setState(() {
            _selectedExamMode = 0;
            _selectedIndex = 2;
            _customBody = null;
          });
        },
        onExamPracticeTap: () {
          setState(() {
            _selectedExamMode = 1;
            _selectedIndex = 2;
            _customBody = null;
          });
        },
        onGuidanceTap: () {
          setState(() {
            _customBody = GuidanceCounselingScreen();
          });
        },
        onInventoryTap: () {
          setState(() {
            _customBody = InventorySystemScreen();
          });
        },
        onTasksTap: () {
          setState(() {
            _customBody = null;
          });
        },
      ),
      body: bodyWidget,
    );
  }
}