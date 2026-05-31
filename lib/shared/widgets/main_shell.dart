import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/study-program')) {
      return 1;
    }
    // Sınavlar sekmesine (index 2) veya profil sekmesine (index 3) geçişler
    // uygulamanın kendi iç mantığıyla ayarlandığı için şimdilik route'a dayalı 
    // basic bir mapping yapıyoruz.
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 0) {
      context.go('/home');
    } else if (index == 1) {
      context.go('/study-program');
    } else if (index == 2) {
      // Şimdilik test sekmesine ana sayfadan geçiliyor varsayıyoruz
      context.go('/home');
    } else if (index == 3) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      // Bu dış kabuk sadece body ve bottom bar'ı içerir.
      // Her sayfanın kendi AppBar'ı ve Drawer'ı kendi içindeki Scaffold'unda bulunur.
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Programım'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Sınavlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
