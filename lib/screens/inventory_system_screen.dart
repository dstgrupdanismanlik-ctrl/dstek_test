import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. Veri Modeli (Envanter Kartları İçin)
class InventoryItem {
  final String title;
  final String description;
  final IconData icon;
  final String url;
  final Color color;

  InventoryItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.url,
    required this.color,
  });
}

class InventorySystemScreen extends StatelessWidget {
  InventorySystemScreen({Key? key}) : super(key: key);

  // 2. Sabit Veri Seti (PRD Dokümanına Göre Doldurulmuştur)
  final List<InventoryItem> inventories = [
    InventoryItem(
      title: "Öğrenme Stilleri Envanteri",
      description: "Görsel, işitsel veya kinestetik... Hangi yöntemle daha hızlı ve kalıcı öğrendiğini keşfetmek için bu testi çöz.",
      icon: Icons.psychology,
      color: Colors.blueAccent,
      url: "https://forms.gle/5PL51bXnZgr86A1t9",
    ),
    InventoryItem(
      title: "Sınav Kaygısı Envanteri",
      description: "Sınav anında yaşadığın stres ve kaygı seviyeni ölçerek, bu durumla başa çıkma stratejilerini geliştirmene yardımcı olur.",
      icon: Icons.monitor_heart,
      color: Colors.redAccent,
      url: "https://forms.gle/5dSWgiVSYD41GGWV8",
    ),
    InventoryItem(
      title: "Meslek Eğilim Envanteri",
      description: "Kişilik özelliklerine, ilgi alanlarına ve yeteneklerine en uygun meslek gruplarını ve akademik rotayı belirle.",
      icon: Icons.explore,
      color: Colors.green,
      url: "https://www.meslekiyaklasimenvanteri.com/",
    ),
  ];

  // 3. Link Açma Fonksiyonu (url_launcher)
  Future<void> _launchInventoryUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Link açılamadı: $url');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Bağlantı açılırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edin."),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Web ve Tablet için genişlik sınırı
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: inventories.length,
          itemBuilder: (context, index) {
            final item = inventories[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, size: 32, color: item.color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _launchInventoryUrl(context, item.url),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text("TESTE BAŞLA"),
                        style: FilledButton.styleFrom(
                          backgroundColor: item.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
