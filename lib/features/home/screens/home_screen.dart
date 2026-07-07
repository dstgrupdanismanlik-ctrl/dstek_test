import 'package:flutter/material.dart';
import 'package:dstek/shared/widgets/expandable_card.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';
import 'package:dstek/core/services/setup_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSTEK'),
        centerTitle: true,
        elevation: 2,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text('Hoş Geldin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ExpandableCard(
            title: 'Günün Motivasyonu', 
            icon: Icons.star, 
            content: 'Başarı, küçük çabaların her gün tekrarlanmasıdır.'
          ),
          SizedBox(height: 16),
          ExpandableCard(
            title: 'Koçluk Notları', 
            icon: Icons.note_alt, 
            content: 'Matematik branşında oran orantı konusuna ağırlık verilmeli.'
          ),
        ],
      ),
    );
  }
}