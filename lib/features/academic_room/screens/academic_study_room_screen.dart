import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

class AcademicStudyRoomScreen extends StatefulWidget {
  const AcademicStudyRoomScreen({Key? key}) : super(key: key);

  @override
  State<AcademicStudyRoomScreen> createState() => _AcademicStudyRoomScreenState();
}

class _AcademicStudyRoomScreenState extends State<AcademicStudyRoomScreen> {
  String? selectedAltSinavTuru;
  String? selectedDers;
  String? selectedKonu;

  final List<StudyTopic> _mockStudyTopics = const [
    StudyTopic(
      altSinavTuru: 'TYT',
      ders: 'Türkçe',
      konu: 'Paragraf',
      kocTavsiyesi: 'Paragrafta ana düşünceyi hızlıca bul, bağlaçlara dikkat et ve her paragrafı 1 cümleyle özetle.',
      googlePdfLink: 'https://www.google.com/search?q=TYT+Paragraf+PDF',
      googleVideoLink: 'https://www.google.com/search?q=TYT+Paragraf+Video',
      mebiPdfLink: 'https://www.eba.gov.tr/arama?q=TYT+Paragraf+PDF',
      mebiVideoLink: 'https://www.eba.gov.tr/arama?q=TYT+Paragraf+Video',
      kurumsalPdfLink: 'https://dstek.com/assets/tyt_paragraf.pdf',
      kurumsalVideoLink: 'https://dstek.com/assets/tyt_paragraf_video',
      soruBankasiLink: 'https://dstek.com/soru-bankasi/tyt_paragraf',
    ),
    StudyTopic(
      altSinavTuru: 'TYT',
      ders: 'Türkçe',
      konu: 'Sözcükte Anlam',
      kocTavsiyesi: 'Sözcük anlamını cümlenin bağlamına göre değerlendir. Eş ve zıt anlamları ayırt et.',
      googlePdfLink: 'https://www.google.com/search?q=TYT+Sözcükte+Anlam+PDF',
      googleVideoLink: 'https://www.google.com/search?q=TYT+Sözcükte+Anlam+Video',
      mebiPdfLink: '',
      mebiVideoLink: '',
      kurumsalPdfLink: 'https://dstek.com/assets/tyt_sozcukte_anlam.pdf',
      kurumsalVideoLink: '',
      soruBankasiLink: 'https://dstek.com/soru-bankasi/tyt_sozcukte_anlam',
    ),
    StudyTopic(
      altSinavTuru: 'TYT',
      ders: 'Matematik',
      konu: 'Üslü Sayılar',
      kocTavsiyesi: 'Üslü sayılarda taban ve üs ilişkisini ezberlemek yerine örneklerle pekiştir.',
      googlePdfLink: 'https://www.google.com/search?q=TYT+Üslü+Sayılar+PDF',
      googleVideoLink: 'https://www.google.com/search?q=TYT+Üslü+Sayılar+Video',
      mebiPdfLink: 'https://www.eba.gov.tr/arama?q=TYT+Üslü+Sayılar+PDF',
      mebiVideoLink: 'https://www.eba.gov.tr/arama?q=TYT+Üslü+Sayılar+Video',
      kurumsalPdfLink: 'https://dstek.com/assets/tyt_uslu_sayilar.pdf',
      kurumsalVideoLink: 'https://dstek.com/assets/tyt_uslu_sayilar_video',
      soruBankasiLink: 'https://dstek.com/soru-bankasi/tyt_uslu_sayilar',
    ),
    StudyTopic(
      altSinavTuru: 'AYT',
      ders: 'Fizik',
      konu: 'Newton\'un Hareket Yasaları',
      kocTavsiyesi: 'Newton yasalarında serbest cisim diyagramlarını çizerek kuvvetleri grupla.',
      googlePdfLink: 'https://www.google.com/search?q=AYT+Newton+Hareket+Yasaları+PDF',
      googleVideoLink: 'https://www.google.com/search?q=AYT+Newton+Hareket+Yasaları+Video',
      mebiPdfLink: 'https://www.eba.gov.tr/arama?q=AYT+Newton+PDF',
      mebiVideoLink: 'https://www.eba.gov.tr/arama?q=AYT+Newton+Video',
      kurumsalPdfLink: 'https://dstek.com/assets/ayt_newton.pdf',
      kurumsalVideoLink: 'https://dstek.com/assets/ayt_newton_video',
      soruBankasiLink: 'https://dstek.com/soru-bankasi/ayt_newton',
    ),
  ];

  List<String> get _altSinavTurleri => _mockStudyTopics.map((e) => e.altSinavTuru).toSet().toList();

  List<String> get _dersListesi {
    if (selectedAltSinavTuru == null) return [];
    return _mockStudyTopics
        .where((e) => e.altSinavTuru == selectedAltSinavTuru)
        .map((e) => e.ders)
        .toSet()
        .toList();
  }

  List<String> get _konuListesi {
    if (selectedAltSinavTuru == null || selectedDers == null) return [];
    return _mockStudyTopics
        .where((e) => e.altSinavTuru == selectedAltSinavTuru && e.ders == selectedDers)
        .map((e) => e.konu)
        .toSet()
        .toList();
  }

  StudyTopic? get _selectedStudyTopic {
    if (selectedAltSinavTuru == null || selectedDers == null || selectedKonu == null) return null;
    for (final topic in _mockStudyTopics) {
      if (topic.altSinavTuru == selectedAltSinavTuru && topic.ders == selectedDers && topic.konu == selectedKonu) {
        return topic;
      }
    }
    return null;
  }

  void _onAltSinavTuruChanged(String? value) {
    setState(() {
      selectedAltSinavTuru = value;
      selectedDers = null;
      selectedKonu = null;
    });
  }

  void _onDersChanged(String? value) {
    setState(() {
      selectedDers = value;
      selectedKonu = null;
    });
  }

  void _onKonuChanged(String? value) {
    setState(() {
      selectedKonu = value;
    });
  }

  Future<void> _openLink(String url) async {
    try {
      final launched = await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı açılamadı. Lütfen URL kontrol edin.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı açılamadı. Lütfen URL kontrol edin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _selectedStudyTopic;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Akademik Çalışma Odası'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Akademik Çalışma Odası',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Alt sınav türü, ders ve konuyu seçerek size özel çalışma araçlarına hızlıca ulaşın.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Alt Sınav Türü Seçiniz',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.filter_alt),
                          ),
                          value: selectedAltSinavTuru,
                          items: _altSinavTurleri.map((value) {
                            return DropdownMenuItem(value: value, child: Text(value));
                          }).toList(),
                          onChanged: _onAltSinavTuruChanged,
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: selectedAltSinavTuru == null ? 'Önce Alt Sınav Türü Seçiniz' : 'Ders Seçiniz',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.menu_book),
                            filled: selectedAltSinavTuru == null,
                            fillColor: Colors.grey.shade100,
                          ),
                          value: selectedDers,
                          items: _dersListesi.map((value) {
                            return DropdownMenuItem(value: value, child: Text(value));
                          }).toList(),
                          onChanged: selectedAltSinavTuru == null ? null : _onDersChanged,
                          disabledHint: const Text('Önce Alt Sınav Türü Seçiniz'),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: selectedDers == null ? 'Önce Ders Seçiniz' : 'Konu Seçiniz',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.topic),
                            filled: selectedDers == null,
                            fillColor: Colors.grey.shade100,
                          ),
                          value: selectedKonu,
                          items: _konuListesi.map((value) {
                            return DropdownMenuItem(value: value, child: Text(value));
                          }).toList(),
                          onChanged: selectedDers == null ? null : _onKonuChanged,
                          disabledHint: const Text('Önce Ders Seçiniz'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (topic != null) _buildDetailSection(topic) else _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Text(
              'Konu seçildikten sonra konu detayları ve uygun araçlar burada gösterilecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(StudyTopic topic) {
    final tools = [
      _StudyTool(title: '🔍 Google PDF Ara', icon: Icons.picture_as_pdf, url: topic.googlePdfLink),
      _StudyTool(title: '🎥 Google Video Ara', icon: Icons.ondemand_video, url: topic.googleVideoLink),
      _StudyTool(title: '🏛️ MEBİ / EBA PDF (Resmi)', icon: Icons.menu_book, url: topic.mebiPdfLink),
      _StudyTool(title: '🏛️ MEBİ / EBA Video (Resmi)', icon: Icons.video_library, url: topic.mebiVideoLink),
      _StudyTool(title: '📄 Kurumsal Ders Föyü (Dahili PDF)', icon: Icons.description, url: topic.kurumsalPdfLink),
      _StudyTool(title: '📺 Kurumsal Konu Anlatımı (Dahili Video)', icon: Icons.play_circle_outline, url: topic.kurumsalVideoLink),
      _StudyTool(title: '📝 Dijital Soru Bankası', icon: Icons.library_books, url: topic.soruBankasiLink),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topic.kocTavsiyesi != null && topic.kocTavsiyesi!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 12),
                  child: Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                ),
                Expanded(
                  child: Text(
                    '💡 Koçun Notu: ${topic.kocTavsiyesi}',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çalışma Araçları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tools.map((tool) {
                    return _StudyToolButton(
                      tool: tool,
                      onTap: tool.url != null && tool.url!.isNotEmpty ? () => _openLink(tool.url!) : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StudyTopic {
  final String altSinavTuru;
  final String ders;
  final String konu;
  final String? kocTavsiyesi;
  final String? googlePdfLink;
  final String? googleVideoLink;
  final String? mebiPdfLink;
  final String? mebiVideoLink;
  final String? kurumsalPdfLink;
  final String? kurumsalVideoLink;
  final String? soruBankasiLink;

  const StudyTopic({
    required this.altSinavTuru,
    required this.ders,
    required this.konu,
    this.kocTavsiyesi,
    this.googlePdfLink,
    this.googleVideoLink,
    this.mebiPdfLink,
    this.mebiVideoLink,
    this.kurumsalPdfLink,
    this.kurumsalVideoLink,
    this.soruBankasiLink,
  });
}

class _StudyTool {
  final String title;
  final IconData icon;
  final String? url;

  const _StudyTool({
    required this.title,
    required this.icon,
    this.url,
  });
}

class _StudyToolButton extends StatelessWidget {
  final _StudyTool tool;
  final VoidCallback? onTap;

  const _StudyToolButton({
    required this.tool,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = onTap != null;
    return SizedBox(
      width: 170,
      child: OutlinedButton.icon(
        onPressed: active ? onTap : null,
        icon: Icon(tool.icon, size: 20),
        label: Text(
          tool.title,
          style: const TextStyle(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: active ? Theme.of(context).colorScheme.primary : Colors.grey,
          side: BorderSide(color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
          backgroundColor: active ? Colors.white : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}
