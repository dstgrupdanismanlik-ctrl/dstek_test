import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:dstek/features/exams/providers/exam_provider.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

class AcademicStudyRoomScreen extends StatefulWidget {
  final String? initialDers;
  final String? initialKonu;

  const AcademicStudyRoomScreen({
    super.key,
    this.initialDers,
    this.initialKonu,
  });

  @override
  State<AcademicStudyRoomScreen> createState() => _AcademicStudyRoomScreenState();
}

class _AcademicStudyRoomScreenState extends State<AcademicStudyRoomScreen> {
  final Future<List<_CurriculumTopic>> _curriculumFuture = _loadCurriculumTopics();

  String? selectedDers;
  String? selectedKonu;
  _CurriculumTopic? selectedTopic;

  @override
  void initState() {
    super.initState();
    selectedDers = widget.initialDers;
    selectedKonu = widget.initialKonu;
  }

  static Future<List<_CurriculumTopic>> _loadCurriculumTopics() async {
    final snapshot = await FirebaseFirestore.instance.collection('curriculum').get();
    return snapshot.docs.map((doc) => _CurriculumTopic.fromMap(doc.data())).toList();
  }

  List<String> _uniqueDersList(List<_CurriculumTopic> topics) {
    final dersSet = <String>{};
    for (final topic in topics) {
      if (topic.ders.isNotEmpty) {
        dersSet.add(topic.ders);
      }
    }
    return dersSet.toList()..sort();
  }

  List<String> _uniqueKonuList(List<_CurriculumTopic> topics) {
    if (selectedDers == null) {
      return [];
    }

    final konuSet = <String>{};
    for (final topic in topics) {
      if (topic.ders == selectedDers && topic.konu.isNotEmpty) {
        konuSet.add(topic.konu);
      }
    }
    return konuSet.toList()..sort();
  }

  _CurriculumTopic? _selectedTopic(List<_CurriculumTopic> topics) {
    if (selectedDers == null || selectedKonu == null) {
      return null;
    }

    for (final topic in topics) {
      if (topic.ders == selectedDers && topic.konu == selectedKonu) {
        return topic;
      }
    }
    return null;
  }

  void _onDersChanged(String? value) {
    setState(() {
      selectedDers = value;
      selectedKonu = null;
      selectedTopic = null;
    });
  }

  void _onKonuChanged(String? value) {
    setState(() {
      selectedKonu = value;
      selectedTopic = null;
    });
  }

  Future<void> _openLink(String url) async {
    try {
      final launched = await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı açılamadı. Lütfen URL kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı açılamadı. Lütfen URL kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Akademik Çalışma Odası'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<_CurriculumTopic>>(
        future: _curriculumFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Veriler yüklenemedi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final topics = snapshot.data ?? <_CurriculumTopic>[];
          final uniqueDersler = topics.map((t) => t.ders).toSet().toList()..sort();
          final dersList = uniqueDersler;

          // 1. DERS GÜVENLİĞİ
          if (selectedDers != null && !uniqueDersler.contains(selectedDers)) {
            selectedDers = null;
            selectedTopic = null;
          }

          // 2. SEÇİLİ DERSİN KONULARINI FİLTRELE
          if (selectedDers == null && widget.initialDers != null) {
            selectedDers = widget.initialDers;
          }

          final availableTopics = selectedDers != null
              ? topics.where((t) => t.ders == selectedDers).toList()
              : [];

          final konuList = availableTopics.map((t) => t.konu).toSet().toList()..sort();

          // 3. OTO-SEÇİM: AGRESİF EŞLEŞME (TAM METİN & KELİME PARÇALAMA)
          if (widget.initialKonu != null && selectedTopic == null && availableTopics.isNotEmpty) {
            String normalize(String text) {
              return text
                  .replaceAll('İ', 'i')
                  .replaceAll('I', 'i')
                  .replaceAll('ı', 'i')
                  .replaceAll('Ş', 's')
                  .replaceAll('ş', 's')
                  .replaceAll('Ğ', 'g')
                  .replaceAll('ğ', 'g')
                  .replaceAll('Ü', 'u')
                  .replaceAll('ü', 'u')
                  .replaceAll('Ö', 'o')
                  .replaceAll('ö', 'o')
                  .replaceAll('Ç', 'c')
                  .replaceAll('ç', 'c')
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]'), '');
            }

            final searchStr = normalize(widget.initialKonu!);
            var found = false;

            // Adım A: Tam metin ve kapsama kontrolü
            for (final t in availableTopics) {
              final tKonu = normalize(t.konu);
              final tKodu = normalize(t.konuKodu);

              if (tKonu == searchStr ||
                  (tKonu.isNotEmpty && searchStr.contains(tKonu)) ||
                  (searchStr.isNotEmpty && tKonu.contains(searchStr)) ||
                  (tKodu.isNotEmpty && searchStr.contains(tKodu)) ||
                  (tKodu.isNotEmpty && tKodu == searchStr)) {
                selectedTopic = t;
                found = true;
                break;
              }
            }

            // Adım B: Bulunamadıysa, Kelime Parçalama (Word Match) ile ara (Kısaltmaları yakalar)
            if (!found && widget.initialKonu!.length > 3) {
              final words = widget.initialKonu!
                  .split(RegExp(r'\s+|-|_'))
                  .map((w) => normalize(w))
                  .where((w) => w.length > 3)
                  .toList();

              if (words.isNotEmpty) {
                for (final t in availableTopics) {
                  final tKonu = normalize(t.konu);
                  if (words.any((w) => tKonu.contains(w))) {
                    selectedTopic = t;
                    break;
                  }
                }
              }
            }
          }

          // 4. KONU GÜVENLİĞİ (Çökme Önleyici Zırh)
          if (selectedTopic != null && !availableTopics.any((t) => t.konu == selectedTopic!.konu)) {
            selectedTopic = null;
          }

          if (selectedTopic != null && selectedKonu != selectedTopic!.konu) {
            selectedKonu = selectedTopic!.konu;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<ExamProvider>(
                  builder: (context, examProvider, _) {
                    return Column(
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                              child: Row(
                                children: [
                                  if (Navigator.canPop(context))
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueAccent),
                                      onPressed: () => Navigator.pop(context),
                                      tooltip: 'Geri Dön',
                                    )
                                  else
                                    const SizedBox(width: 48),
                                  const Expanded(
                                    child: Text(
                                      'Akademik Çalışma Odası',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ders seçin, ardından sadece o derse ait konular listelenecektir.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Ders Seçiniz',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.menu_book),
                              ),
                              value: (selectedDers != null && dersList.contains(selectedDers)) ? selectedDers : null,
                              items: dersList
                                  .map<DropdownMenuItem<String>>((ders) {
                                    return DropdownMenuItem<String>(
                                      value: ders,
                                      child: Text(ders, style: const TextStyle(fontSize: 14)),
                                    );
                                  })
                                  .toList(),
                              onChanged: dersList.isEmpty ? null : _onDersChanged,
                            ),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<_CurriculumTopic>(
                              decoration: InputDecoration(
                                labelText: selectedDers == null ? 'Önce Ders Seçiniz' : 'Konu Seçiniz',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.topic),
                                filled: selectedDers == null,
                                fillColor: Colors.grey.shade100,
                              ),
                              value: selectedTopic != null && availableTopics.any((t) => t.konu == selectedTopic!.konu)
                                  ? selectedTopic
                                  : null,
                              items: availableTopics
                                  .map<DropdownMenuItem<_CurriculumTopic>>((topic) {
                                    return DropdownMenuItem<_CurriculumTopic>(
                                      value: topic,
                                      child: Text(topic.konu, style: const TextStyle(fontSize: 14)),
                                    );
                                  })
                                  .toList(),
                              onChanged: selectedDers == null
                                  ? null
                                  : (topic) {
                                      setState(() {
                                        selectedTopic = topic;
                                        selectedKonu = topic?.konu;
                                      });
                                    },
                              disabledHint: const Text('Önce Ders Seçiniz'),
                            ),
                          ],
                        ),
                      ),
                        ),
                        const SizedBox(height: 24),
                        if (selectedTopic != null) _buildSingleTopicXray(selectedTopic!, examProvider),
                        const SizedBox(height: 24),
                        if (selectedTopic != null) _buildDetailSection(selectedTopic!) else _buildEmptyState(),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleTopicXray(_CurriculumTopic topic, ExamProvider provider) {
    double score = 0.0;
    int totalD = 0;
    int totalY = 0;
    int totalB = 0;
    String sonDurum = '';

    final normalizedTopicName = topic.konu.toLowerCase().replaceAll(' ', '');
    final normalizedKocNote = topic.kocTavsiyesi.toLowerCase().replaceAll(' ', '');

    for (final data in provider.xrayData) {
      final kKodu = (data['konu_kodu'] as String? ?? '').toLowerCase().replaceAll(' ', '');

      if (kKodu.isNotEmpty) {
        if (topic.konuKodu.toLowerCase().replaceAll(' ', '') == kKodu ||
            normalizedTopicName.contains(kKodu) ||
            kKodu.contains(normalizedTopicName) ||
            (normalizedKocNote.isNotEmpty && normalizedKocNote.contains(kKodu))) {
          score = ((data['guvenilir_basari_skoru'] ?? 0.0) as num).toDouble();

          final optik = data['optik_test_d_y_b'] as Map<String, dynamic>? ?? {};
          final manuel = data['manuel_d_y_b'] as Map<String, dynamic>? ?? {};

          totalD = ((optik['D'] ?? 0) as num).toInt() + ((manuel['D'] ?? 0) as num).toInt();
          totalY = ((optik['Y'] ?? 0) as num).toInt() + ((manuel['Y'] ?? 0) as num).toInt();
          totalB = ((optik['B'] ?? 0) as num).toInt() + ((manuel['B'] ?? 0) as num).toInt();

          sonDurum = data['yapay_zeka_tavsiyesi'] as String? ?? '';
          if (sonDurum.isEmpty) {
            final sonTest = data['son_test_d_y_b'] as String? ?? '';
            if (sonTest.isNotEmpty) sonDurum = 'Son Test Performansı: $sonTest';
          }
          break;
        }
      }
    }

    final totalQ = totalD + totalY + totalB;
    if (score <= 0 && totalQ == 0) {
      return Card(
        elevation: 1,
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bu konuda henüz yeterli veri yok. İlk testini çözerek röntgeni canlandırabilirsin! 💖',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Konu Başarı Analizi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade200,
                      color: score >= 70 ? Colors.green.shade500 : (score >= 40 ? Colors.orange.shade500 : Colors.red.shade500),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 42,
                  child: Text('%${score.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatChip('Toplam', totalQ.toString(), Colors.blue),
                _buildStatChip('Doğru', totalD.toString(), Colors.green),
                _buildStatChip('Yanlış', totalY.toString(), Colors.red),
                _buildStatChip('Boş', totalB.toString(), Colors.grey),
              ],
            ),
            if (sonDurum.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.favorite, color: Colors.pinkAccent, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      sonDurum,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, color: color.shade900, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(22.0),
        child: Text(
          'Konu seçildikten sonra konu detayları ve uygun araçlar burada gösterilecektir.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildDetailSection(_CurriculumTopic topic) {
    final query = Uri.encodeComponent('${topic.altSinavTuru} ${topic.ders} ${topic.konu}');
    final tools = [
      _StudyTool(title: 'Google PDF', icon: Icons.picture_as_pdf, url: 'https://www.google.com/search?q=$query+filetype:pdf'),
      _StudyTool(title: 'Google Video', icon: Icons.ondemand_video, url: 'https://www.google.com/search?q=$query&tbm=vid'),
      _StudyTool(title: 'MEBİ / EBA PDF', icon: Icons.menu_book, url: 'https://www.google.com/search?q=$query+site:gov.tr+filetype:pdf'),
      _StudyTool(title: 'MEBİ / EBA Video', icon: Icons.video_library, url: 'https://www.google.com/search?q=$query+%22Ortaöğretim+Genel+Müdürlüğü%22+OR+%22TRT+EBA%22&tbm=vid'),
      _StudyTool(title: 'Kurumsal PDF', icon: Icons.description, url: topic.kurumsalPdfLink),
      _StudyTool(title: 'Kurumsal Video', icon: Icons.play_circle_outline, url: topic.kurumsalVideoLink),
      _StudyTool(title: 'Soru Bankası', icon: Icons.library_books, url: topic.soruBankasiLink),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topic.kocTavsiyesi.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 12),
                  child: Icon(Icons.push_pin, color: Colors.deepOrange, size: 28),
                ),
                Expanded(
                  child: Text(
                    'Koçun Notu: ${topic.kocTavsiyesi}',
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

class _CurriculumTopic {
  final String altSinavTuru;
  final String ders;
  final String konu;
  final String konuKodu;
  final String kocTavsiyesi;
  final String? googlePdfLink;
  final String? googleVideoLink;
  final String? mebiPdfLink;
  final String? mebiVideoLink;
  final String? kurumsalPdfLink;
  final String? kurumsalVideoLink;
  final String? soruBankasiLink;

  const _CurriculumTopic({
    required this.altSinavTuru,
    required this.ders,
    required this.konu,
    required this.konuKodu,
    required this.kocTavsiyesi,
    required this.googlePdfLink,
    required this.googleVideoLink,
    required this.mebiPdfLink,
    required this.mebiVideoLink,
    required this.kurumsalPdfLink,
    required this.kurumsalVideoLink,
    required this.soruBankasiLink,
  });

  factory _CurriculumTopic.fromMap(Map<String, dynamic> map) {
    String? readString(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return null;
    }

    return _CurriculumTopic(
      altSinavTuru: readString(['alt_sinav_turu', 'altSinavTuru', 'sinav_turu', 'sinavTuru']) ?? '',
      ders: readString(['ders', 'ders_adi', 'dersAdi', 'course_name', 'courseName']) ?? '',
      konu: readString(['konu', 'konu_adi', 'konuAdi', 'topic_name', 'topicName']) ?? '',
      konuKodu: readString(['konu_kodu', 'konuKodu', 'kod']) ?? '',
      kocTavsiyesi: readString(['koc_tavsiyesi', 'kocTavsiyesi', 'coach_note', 'coachNote']) ?? '',
      googlePdfLink: readString(['google_pdf_link', 'googlePdfLink', 'pdf_link', 'pdfLink']),
      googleVideoLink: readString(['google_video_link', 'googleVideoLink', 'video_link', 'videoLink']),
      mebiPdfLink: readString(['mebi_pdf_link', 'mebiPdfLink', 'eba_pdf_link', 'ebaPdfLink']),
      mebiVideoLink: readString(['mebi_video_link', 'mebiVideoLink', 'eba_video_link', 'ebaVideoLink']),
      kurumsalPdfLink: readString(['dahili_pdf_linki', 'kurumsal_pdf_link', 'kurumsalPdfLink']),
      kurumsalVideoLink: readString(['dahili_video_linki', 'kurumsal_video_link', 'kurumsalVideoLink']),
      soruBankasiLink: readString(['dahili_soru_bankasi_linki', 'soru_bankasi_link', 'soruBankasiLink']),
    );
  }
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
    final active = onTap != null;
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
