import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dstek/shared/widgets/app_drawer.dart'; // EKLENDİ: Sandviç menü bağlantısı

// 1. Veri Modeli
class GuidanceItem {
  final String title;
  final String content;
  final IconData icon;
  final bool isLink;
  final String? url;

  GuidanceItem({
    required this.title,
    required this.content,
    required this.icon,
    this.isLink = false,
    this.url,
  });
}

class GuidanceCounselingScreen extends StatelessWidget {
  GuidanceCounselingScreen({Key? key}) : super(key: key);

  // 2. Sahte Veri Seti (İlk madde test için bilerek çok uzun tutulmuştur)
  final List<GuidanceItem> leftColumnItems = [
    GuidanceItem(
      title: "Sistem Kılavuzu: DSTEK Nasıl Kullanılır?",
      content: '''DSTEK, LGS ve YKS gibi sınavlara hazırlık sürecinde seni takip eden akıllı bir asistandır. 'Çalışma Programım' sekmesinden günlük görevlerini takip edebilir, 'Test ve Sınav Merkezi'nden çözdüğün kaynakların netlerini sisteme girebilirsin. Koçun bu verileri analiz ederek sana en uygun rotayı çizer.

DSTEK, LGS ve YKS gibi sınavlara hazırlık sürecinde seni takip eden akıllı bir asistandır. 'Çalışma Programım' sekmesinden günlük görevlerini takip edebilir, 'Test ve Sınav Merkezi'nden çözdüğün kaynakların netlerini sisteme girebilirsin. Koçun bu verileri analiz ederek sana en uygun rotayı çizer.

DSTEK, LGS ve YKS gibi sınavlara hazırlık sürecinde seni takip eden akıllı bir asistandır. 'Çalışma Programım' sekmesinden günlük görevlerini takip edebilir, 'Test ve Sınav Merkezi'nden çözdüğün kaynakların netlerini sisteme girebilirsin. Koçun bu verileri analiz ederek sana en uygun rotayı çizer.

DSTEK, LGS ve YKS gibi sınavlara hazırlık sürecinde seni takip eden akıllı bir asistandır. 'Çalışma Programım' sekmesinden günlük görevlerini takip edebilir, 'Test ve Sınav Merkezi'nden çözdüğün kaynakların netlerini sisteme girebilirsin. Koçun bu verileri analiz ederek sana en uygun rotayı çizer.''',
      icon: Icons.menu_book,
    ),
    GuidanceItem(
      title: "Sıkça Sorulan Sorular (SSS)",
      content: "Soru: Şifremi nasıl değiştirebilirim?\nCevap: Ayarlar menüsüne girerek 'Şifre Güncelle' alanından yeni şifrenizi belirleyebilirsiniz.\n\nSoru: Deneme netlerim yanlış girildi, ne yapmalıyım?\nCevap: Test girişleri ekranından girdiğiniz veriyi tekrar çağırarak üzerinde düzeltme yapıp yeniden kaydedebilirsiniz.",
      icon: Icons.help_outline,
    ),
    GuidanceItem(
      title: "MEB - Milli Eğitim Bakanlığı",
      content: "Milli Eğitim Bakanlığı resmi web sitesine giderek güncel eğitim haberlerine, müfredat değişikliklerine ve duyurulara ulaşabilirsiniz.",
      icon: Icons.account_balance,
      isLink: true,
      url: "https://www.meb.gov.tr",
    ),
  ];

  final List<GuidanceItem> rightColumnItems = [
    GuidanceItem(
      title: "Sınav Sistemleri: YKS Nedir?",
      content: "YKS (Yükseköğretim Kurumları Sınavı), TYT ve AYT olmak üzere iki temel oturumdan oluşur. TYT'de Türkçe, Matematik, Sosyal ve Fen testleri yer alırken; AYT'de alanınıza (SAY, EA, SÖZ, DİL) uygun testleri çözmeniz gerekmektedir.",
      icon: Icons.school,
    ),
    GuidanceItem(
      title: "Sınav Sistemleri: LGS Nedir?",
      content: "LGS (Liselere Geçiş Sistemi), 8. sınıf öğrencileri için uygulanan merkezi bir sınavdır. Sözel ve Sayısal olmak üzere iki oturumda gerçekleşir. Türkçede okuduğunu anlama, matematikte ise analitik düşünme ön plandadır.",
      icon: Icons.article,
    ),
    GuidanceItem(
      title: "ÖSYM - Sınav ve Sonuç Portalı",
      content: "YKS başvuru işlemleri, sınav takvimi, geçmiş yılların çıkmış soruları ve sınav sonuçları için ÖSYM resmi web sitesini ziyaret edebilirsiniz.",
      icon: Icons.how_to_reg,
      isLink: true,
      url: "https://www.osym.gov.tr",
    ),
  ];

  // 3. Link Açma Fonksiyonu
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Link açılamadı');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Bağlantı açılamadı. İnternet bağlantınızı kontrol edin."),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  // 4. Genişleyebilir Kart (Expandable Card) Tasarımı
  Widget _buildExpandableCard(BuildContext context, GuidanceItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Genişlemede taşmaları önler
      child: Theme(
        // Çizgi ve arka plan efektlerini temizler
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(item.icon, color: Colors.blueAccent, size: 28),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // İçeriği sabit yükseklikli ve kaydırılabilir bir kutuya alıyoruz
          children: [
            Container(
              height: 160, // Bütün açık kartların aynı ölçüde olmasını sağlayan sabit yükseklik
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0), // Scrollbar'a yer açmak için
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.content,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                        ),
                        if (item.isLink && item.url != null) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () => _launchUrl(context, item.url!),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text("SİTEYE GİT"),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16), // Alt boşluk
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tüm listeyi mobil (tek sütun) görünüm için birleştir
    final allItems = [...leftColumnItems, ...rightColumnItems];

    return Scaffold(
      drawer: const AppDrawer(), // EKLENDİ: Sandviç menüyü sayfaya dahil eder
      appBar: AppBar(
        title: const Text("Rehberlik ve Yönlendirme"),
        centerTitle: true,
        automaticallyImplyLeading: false, // EKLENDİ: Geri okunu İPTAL EDER
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(), // EKLENDİ: Menü ikonunu basar
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Eğer ekran genişliği 800px'den büyükse (Web/Tablet), 2 sütunlu Row yapısı kullan
          if (constraints.maxWidth > 800) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: leftColumnItems.map((item) => _buildExpandableCard(context, item)).toList(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: rightColumnItems.map((item) => _buildExpandableCard(context, item)).toList(),
                    ),
                  ),
                ],
              ),
            );
          } 
          // Eğer ekran mobil cihaz ise tek sütunlu standart ListView kullan
          else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                return _buildExpandableCard(context, allItems[index]);
              },
            );
          }
        },
      ),
    );
  }
}