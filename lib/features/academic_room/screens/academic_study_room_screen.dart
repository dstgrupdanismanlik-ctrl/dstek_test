import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:dstek/shared/widgets/app_drawer.dart';

class AcademicStudyRoomScreen extends StatefulWidget {
  const AcademicStudyRoomScreen({super.key});

  @override
  State<AcademicStudyRoomScreen> createState() => _AcademicStudyRoomScreenState();
}

class _AcademicStudyRoomScreenState extends State<AcademicStudyRoomScreen> {
  final Future<List<_CurriculumTopic>> _curriculumFuture = _loadCurriculumTopics();

  String? selectedDers;
  String? selectedKonu;

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
          final dersList = _uniqueDersList(topics);
          final konuList = _uniqueKonuList(topics);
          final selectedTopic = _selectedTopic(topics);

          return Center(
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
                              value: selectedDers,
                              items: dersList
                                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                  .toList(),
                              onChanged: dersList.isEmpty ? null : _onDersChanged,
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
                              items: konuList
                                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                  .toList(),
                              onChanged: selectedDers == null ? null : _onKonuChanged,
                              disabledHint: const Text('Önce Ders Seçiniz'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (selectedTopic != null) _buildDetailSection(selectedTopic) else _buildEmptyState(),
                  ],
                ),
              ),
            ),
          );
        },
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
      _StudyTool(title: 'Google Video', icon: Icons.ondemand_video, url: 'https://www.youtube.com/results?search_query=$query'),
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

class _CurriculumTopic {
  final String altSinavTuru;
  final String ders;
  final String konu;
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
