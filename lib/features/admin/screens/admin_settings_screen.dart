import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  bool _isDeleting = false;

  // Baş Mimarın hazırladığı API Linki
  final String _apiUrl = "https://script.google.com/macros/s/AKfycbxf9Ky8J_aVRS672kQXHyiLgzJ0gdlqusRyd--CbwpBxc5pm4_Ar4rz46o2F0j0ga_R/exec";

  Future<void> _syncDatabase() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final firestore = FirebaseFirestore.instance;
        int successCount = 0;

        // Döngü ile verileri dön ve Firestore'a Upsert (Merge) yap
        for (var item in data) {
          if (item['konu_kodu'] != null && item['konu_kodu'].toString().isNotEmpty) {
            final String docId = item['konu_kodu'].toString();
            
            await firestore
                .collection('curriculum') // Müfredat koleksiyonu
                .doc(docId)
                .set(item as Map<String, dynamic>, SetOptions(merge: true));
                
            successCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sistem güncellendi! $successCount kayıt başarıyla işlendi (Eklendi/Güncellendi).'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception("API'ye ulaşılamadı. Durum Kodu: \\${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı Hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearDatabase() async {
    // Kazara basılmalara karşı Onay Penceresi (Dialog)
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Tehlikeli İşlem'),
          ],
        ),
        content: const Text('Tüm müfredat (Ders ve Konu) veritabanını silmek üzeresiniz. Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('EVET, TAMAMEN SİL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore.collection('curriculum').get();
        
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veritabanı başarıyla temizlendi.'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme Hatası: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AYARLAR (ADMİN)'),
        centerTitle: true,
        elevation: 2,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kurum Bilgisi Başlığı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.domain, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('İŞLEM YAPILAN KURUM: DSTEK_MERKEZ_01', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Adım Kartı (Mavi - Bilgi)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Text('1. Adım: Şablonu İndir', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Sisteme eklenecek dersleri, konuları ve araçları tanımlamak için Google Sheets tablolarınızı hazırlayın.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {}, // Link yönlendirmesi eklenebilir
                    icon: const Icon(Icons.table_view),
                    label: const Text('ŞABLONLARA GİT (DRİVE)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Adım Kartı (Kırmızı - Aksiyon)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                      const SizedBox(width: 8),
                      Text('2. Adım: Sistem Kurulumu', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Google Sheets üzerindeki güncel verileri sisteme yüklemek (senkronize etmek) için aşağıdaki butona tıklayın.\n\nDİKKAT: Bu işlem sadece yeni ve değişen verileri günceller. Mevcut verilerinizi silmez.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _syncDatabase,
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_sync),
                    label: Text(_isLoading ? 'YÜKLENİYOR...' : 'SİSTEMİ KUR (EXCEL GÜNCELLE)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            // Tehlikeli Alan (Silme İşlemi)
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _clearDatabase,
              icon: _isDeleting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                  : const Icon(Icons.delete_forever, color: Colors.red),
              label: Text(_isDeleting ? 'SİLİNİYOR...' : 'TÜM VERİTABANINI TEMİZLE', style: const TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50)
              ),
            )
          ],
        ),
      ),
    );
  }
}
