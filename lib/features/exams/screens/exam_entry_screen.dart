import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// EVRENSEL WIDGET: 2 HANE SINIRLI NUMERİK GİRİŞ
// Dokümantasyon Kuralı: D-Y-B ve Soru Sayısı alanlarına 
// en fazla 2 haneli rakam girilebilir.
// ==========================================
class NumericInputField extends StatelessWidget {
  final String label;
  const NumericInputField({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2), // Max 2 hane kuralı
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String hint;
  const CustomDropdown({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: '1', child: Text('Seçenek 1')),
        DropdownMenuItem(value: '2', child: Text('Seçenek 2')),
      ],
      onChanged: (value) {},
    );
  }
}

// ==========================================
// EKRAN 1: TEST GİRİŞLERİ ALANI
// ==========================================
class TestEntryScreen extends StatelessWidget {
  const TestEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.blue.shade50,
            child: const TabBar(
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: [
                Tab(text: 'Manuel Test Girişi'),
                Tab(text: 'Optikli Test Girişi'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildManualTestTab(),
                _buildOpticTestTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CustomDropdown(hint: 'Ders seçiniz'),
          const SizedBox(height: 12),
          const CustomDropdown(hint: 'Önce ders seçiniz (Konu)'),
          const SizedBox(height: 12),
          const CustomDropdown(hint: 'Test türü'),
          const SizedBox(height: 24),
          
          Row(
            children: const [
              Expanded(child: NumericInputField(label: 'D')),
              SizedBox(width: 12),
              Expanded(child: NumericInputField(label: 'Y')),
              SizedBox(width: 12),
              Expanded(child: NumericInputField(label: 'B')),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            child: const Text('KAYDET'),
          ),
        ],
      ),
    );
  }

  Widget _buildOpticTestTab() {
    return const OpticTestTab();
  }
}

class OpticTestData {
  final String testTuru;
  final String yayinAdi;
  final String seri;
  final String konuKoduAdi;
  final String testAdi;
  final List<String> answers;

  const OpticTestData({
    required this.testTuru,
    required this.yayinAdi,
    required this.seri,
    required this.konuKoduAdi,
    required this.testAdi,
    required this.answers,
  });
}

class OpticTestTab extends StatefulWidget {
  const OpticTestTab({super.key});

  @override
  State<OpticTestTab> createState() => _OpticTestTabState();
}

class _OpticTestTabState extends State<OpticTestTab> {
  String? _selectedTestTuru;
  String? _selectedYayinAdi;
  String? _selectedSeri;
  String? _selectedKonuKoduAdi;
  String? _selectedTestAdi;
  OpticTestData? _selectedTest;
  List<String?> _selectedAnswers = [];
  bool isChecked = false;
  int correctCount = 0;
  int wrongCount = 0;
  int emptyCount = 0;

  static const List<OpticTestData> _mockTests = [
    OpticTestData(
      testTuru: 'Kağıt Test',
      yayinAdi: 'EİS',
      seri: 'Beyaz',
      konuKoduAdi: 'T_TR_3 Paragraf',
      testAdi: 'K_EİS_B_T_TR_3_005',
      answers: ['A', 'C', 'B', 'D', 'E', 'A', 'C', 'B', 'E', 'D', 'A', 'B', 'C', 'D', 'E', 'A', 'B', 'C', 'D', 'E'],
    ),
    OpticTestData(
      testTuru: 'Kağıt Test',
      yayinAdi: 'EİS',
      seri: 'Siyah',
      konuKoduAdi: 'T_TR_1 Dil Bilgisi',
      testAdi: 'K_EİS_S_T_TR_1_001',
      answers: ['B', 'A', 'E', 'C', 'D', 'A', 'B', 'E', 'C', 'D', 'A', 'B', 'C', 'D', 'E'],
    ),
    OpticTestData(
      testTuru: 'Online Test',
      yayinAdi: 'NET',
      seri: 'Lacivert',
      konuKoduAdi: 'M_AT_2 Analiz',
      testAdi: 'O_NET_L_M_AT_2_010',
      answers: ['C', 'D', 'A', 'B', 'E', 'C', 'D', 'A', 'B', 'E', 'C', 'A', 'D', 'B', 'E', 'C', 'A', 'D', 'B', 'E', 'C', 'A', 'D', 'B', 'E'],
    ),
    OpticTestData(
      testTuru: 'Online Test',
      yayinAdi: 'NET',
      seri: 'Gri',
      konuKoduAdi: 'FEN_1 Fizik',
      testAdi: 'O_NET_G_FEN_1_002',
      answers: ['D', 'B', 'C', 'A', 'E', 'B', 'C', 'A', 'D', 'E'],
    ),
  ];

  List<String> get _testTurleri {
    return _mockTests.map((e) => e.testTuru).toSet().toList();
  }

  List<String> get _yayinAdlari {
    if (_selectedTestTuru == null) return [];
    return _mockTests
        .where((e) => e.testTuru == _selectedTestTuru)
        .map((e) => e.yayinAdi)
        .toSet()
        .toList();
  }

  List<String> get _seriListesi {
    if (_selectedTestTuru == null || _selectedYayinAdi == null) return [];
    return _mockTests
        .where((e) => e.testTuru == _selectedTestTuru && e.yayinAdi == _selectedYayinAdi)
        .map((e) => e.seri)
        .toSet()
        .toList();
  }

  List<String> get _konuKodlari {
    if (_selectedTestTuru == null || _selectedYayinAdi == null || _selectedSeri == null) return [];
    return _mockTests
        .where((e) => e.testTuru == _selectedTestTuru && e.yayinAdi == _selectedYayinAdi && e.seri == _selectedSeri)
        .map((e) => e.konuKoduAdi)
        .toSet()
        .toList();
  }

  List<String> get _testAdlari {
    if (_selectedTestTuru == null || _selectedYayinAdi == null || _selectedSeri == null || _selectedKonuKoduAdi == null) return [];
    return _mockTests
        .where((e) => e.testTuru == _selectedTestTuru && e.yayinAdi == _selectedYayinAdi && e.seri == _selectedSeri && e.konuKoduAdi == _selectedKonuKoduAdi)
        .map((e) => e.testAdi)
        .toSet()
        .toList();
  }

  void _resetBelow({required int level}) {
    switch (level) {
      case 1:
        _selectedYayinAdi = null;
        _selectedSeri = null;
        _selectedKonuKoduAdi = null;
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      case 2:
        _selectedSeri = null;
        _selectedKonuKoduAdi = null;
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      case 3:
        _selectedKonuKoduAdi = null;
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      case 4:
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      default:
        break;
    }
    _selectedAnswers = [];
    isChecked = false;
    correctCount = 0;
    wrongCount = 0;
    emptyCount = 0;
  }

  void _selectTestAdi(String? value) {
    _selectedTestAdi = value;
    if (value == null) {
      _selectedTest = null;
      _selectedAnswers = [];
      return;
    }

    final found = _mockTests.where((e) => e.testAdi == value).toList();
    _selectedTest = found.isNotEmpty ? found.first : null;
    _selectedAnswers = List<String?>.filled(_selectedTest?.answers.length ?? 0, null);
  }

  void _toggleAnswer(int index, String option) {
    setState(() {
      if (_selectedAnswers[index] == option) {
        _selectedAnswers[index] = null;
      } else {
        _selectedAnswers[index] = option;
      }
    });
  }

  void _checkAnswers() {
    if (_selectedTest == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce bir test seçiniz.')));
      return;
    }

    final totalQuestions = _selectedTest!.answers.length;
    final answeredCount = _selectedAnswers.where((e) => e != null).length;
    final correct = List.generate(totalQuestions, (index) {
      final answer = _selectedAnswers[index];
      return answer != null && answer == _selectedTest!.answers[index] ? 1 : 0;
    }).fold(0, (sum, value) => sum + value);
    final empty = totalQuestions - answeredCount;
    final wrong = answeredCount - correct;

    setState(() {
      isChecked = true;
      correctCount = correct;
      wrongCount = wrong;
      emptyCount = empty;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Yanıtlanan: $answeredCount, Doğru: $correct / $totalQuestions'),
    ));
  }

  void _saveOpticTestResult() {
    if (!isChecked) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Optik test sonucu sisteme kaydedildi.')));
  }

  Widget _buildResultPill(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? initialValue,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdownField(
            label: 'Test Türü Seçiniz',
            initialValue: _selectedTestTuru,
            items: _testTurleri,
            enabled: true,
            onChanged: (value) {
              setState(() {
                _selectedTestTuru = value;
                _resetBelow(level: 1);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Yayın Adı Seçiniz',
            initialValue: _selectedYayinAdi,
            items: _yayinAdlari,
            enabled: _selectedTestTuru != null,
            onChanged: (value) {
              setState(() {
                _selectedYayinAdi = value;
                _resetBelow(level: 2);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Seri Seçiniz',
            initialValue: _selectedSeri,
            items: _seriListesi,
            enabled: _selectedYayinAdi != null,
            onChanged: (value) {
              setState(() {
                _selectedSeri = value;
                _resetBelow(level: 3);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Konu Kodu ve Adı Seçiniz',
            initialValue: _selectedKonuKoduAdi,
            items: _konuKodlari,
            enabled: _selectedSeri != null,
            onChanged: (value) {
              setState(() {
                _selectedKonuKoduAdi = value;
                _resetBelow(level: 4);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Test Adı Seçiniz',
            initialValue: _selectedTestAdi,
            items: _testAdlari,
            enabled: _selectedKonuKoduAdi != null,
            onChanged: (value) {
              setState(() {
                _selectTestAdi(value);
              });
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Seçilen Test', style: TextStyle(fontSize: 16, color: colorScheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  _selectedTest?.testAdi ?? 'Henüz test seçilmedi',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedTest != null) ...[
            Text(
              '${_selectedTest!.testAdi} için ${_selectedTest!.answers.length} soruluk optik form',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Colors.grey.shade200,
                    child: Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Soru No', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...['A', 'B', 'C', 'D', 'E'].map(
                          (e) => Expanded(child: Center(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedTest!.answers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text('${index + 1}. soru', style: const TextStyle(fontWeight: FontWeight.w500))),
                            ...['A', 'B', 'C', 'D', 'E'].map((option) {
                              final isSelected = _selectedAnswers[index] == option;
                              return Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _toggleAnswer(index, option),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? colorScheme.primary : Colors.transparent,
                                        border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.shade400),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(option, style: TextStyle(color: isSelected ? colorScheme.onPrimary : Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _checkAnswers,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.primary),
              ),
              child: const Text('KONTROL ET'),
            ),
            if (isChecked) ...[
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildResultPill('Doğru', correctCount.toString(), colorScheme.primary),
                      _buildResultPill('Yanlış', wrongCount.toString(), Colors.red.shade700),
                      _buildResultPill('Boş', emptyCount.toString(), Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isChecked ? _saveOpticTestResult : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isChecked ? colorScheme.primary : Colors.grey,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SİSTEME KAYDET'),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SİSTEME KAYDET'),
              ),
            ],
          ] else ...[
            const SizedBox(height: 24),
            const Text('Test seçildikten sonra optik form burada oluşturulacaktır.', textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// EKRAN 2: DENEME GİRİŞLERİ ALANI
// ==========================================
class PracticeExamEntryScreen extends StatelessWidget {
  const PracticeExamEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.teal.shade50,
            child: const TabBar(
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              tabs: [
                Tab(text: 'Manuel Deneme Girişi'),
                Tab(text: 'Optikli Deneme Girişi'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildManualExamTab(),
                const PracticeOpticExamTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualExamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Deneme bilgisi. Örn: DST2601', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          const CustomDropdown(hint: 'Deneme türünü seçiniz. Örn: TYT'),
          const SizedBox(height: 24),
          
          _buildLessonManualRow('TYT Türkçe (40 soru)'),
          const SizedBox(height: 8),
          _buildLessonManualRow('TYT Sosyal (20 soru)'),
          const SizedBox(height: 8),
          _buildLessonManualRow('TYT Matematik (40 soru)'),
          const SizedBox(height: 8),
          _buildLessonManualRow('TYT Fen (20 soru)'),
          
          const SizedBox(height: 24),
          // 2 hane sınırlandırılmış süre yetmediği alanı
          const NumericInputField(label: 'Süre yetmediği için görülemeyen soru sayısı'),
          const SizedBox(height: 24),
          
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
            child: Column(
              children: [
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Doğru yapılamayan sorular alanı / Konu Kodu ve Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Soru Sayısı', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3, // Dinamikleşecek
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: const [
                          Expanded(flex: 2, child: Text('T-TR-3 Paragraf')),
                          // Soru sayısı için de 2 hane kuralı uygulandı
                          Expanded(flex: 1, child: NumericInputField(label: 'Adet')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Girişleri Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonManualRow(String title) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
        const Expanded(flex: 1, child: NumericInputField(label: 'D')),
        const SizedBox(width: 8),
        const Expanded(flex: 1, child: NumericInputField(label: 'Y')),
        const SizedBox(width: 8),
        const Expanded(flex: 1, child: NumericInputField(label: 'B')),
      ],
    );
  }
}

class PracticeOpticExamData {
  final String altSinavTuru;
  final String yayinAdi;
  final String seri;
  final String sayi;
  final String denemeAdi;
  final List<String> answers;

  const PracticeOpticExamData({
    required this.altSinavTuru,
    required this.yayinAdi,
    required this.seri,
    required this.sayi,
    required this.denemeAdi,
    required this.answers,
  });
}

class PracticeOpticExamTab extends StatefulWidget {
  const PracticeOpticExamTab({super.key});

  @override
  State<PracticeOpticExamTab> createState() => _PracticeOpticExamTabState();
}

class _PracticeOpticExamTabState extends State<PracticeOpticExamTab> {
  String? _selectedAltSinavTuru;
  String? _selectedYayinAdi;
  String? _selectedSeri;
  String? _selectedSayi;
  String? _selectedDenemeAdi;
  PracticeOpticExamData? _selectedDeneme;
  List<String?> _selectedAnswers = [];
  bool isChecked = false;
  int correctCount = 0;
  int wrongCount = 0;
  int emptyCount = 0;

  static const List<PracticeOpticExamData> _mockDenemeler = [
    PracticeOpticExamData(
      altSinavTuru: 'TYT',
      yayinAdi: 'EŞS',
      seri: 'BEYAZ 2026',
      sayi: '1',
      denemeAdi: '13_BEY26_TYT_01',
      answers: ['A', 'B', 'C', 'D', 'E', 'A', 'C', 'D', 'B', 'E', 'A', 'C', 'B', 'D', 'E', 'A', 'B', 'C', 'D', 'E', 'A', 'C', 'B', 'D', 'E', 'A', 'B', 'C', 'D', 'E', 'A', 'B', 'C', 'D', 'E', 'A', 'C', 'B', 'D', 'E', 'A', 'B', 'C'],
    ),
    PracticeOpticExamData(
      altSinavTuru: 'AYT',
      yayinAdi: 'Bilgi Sarmal',
      seri: 'PRO',
      sayi: '2',
      denemeAdi: 'BS_PRO_AYT_02',
      answers: ['B', 'C', 'A', 'E', 'D', 'B', 'C', 'A', 'E', 'D', 'A', 'B', 'C', 'D', 'E', 'A', 'B', 'C', 'D', 'E', 'B', 'C', 'A', 'E', 'D', 'A', 'B', 'C', 'D', 'E'],
    ),
    PracticeOpticExamData(
      altSinavTuru: 'TYT',
      yayinAdi: 'Bilgi Sarmal',
      seri: 'PRO',
      sayi: '5',
      denemeAdi: 'BS_PRO_TYT_05',
      answers: ['E', 'D', 'C', 'B', 'A', 'E', 'D', 'C', 'B', 'A', 'E', 'D', 'C', 'B', 'A', 'E', 'D', 'C', 'B', 'A', 'E', 'D', 'C', 'B', 'A', 'E', 'D', 'C', 'B', 'A'],
    ),
  ];

  List<String> get _altSinavTurleri => _mockDenemeler.map((e) => e.altSinavTuru).toSet().toList();

  List<String> get _yayinAdlari {
    if (_selectedAltSinavTuru == null) return [];
    return _mockDenemeler
        .where((e) => e.altSinavTuru == _selectedAltSinavTuru)
        .map((e) => e.yayinAdi)
        .toSet()
        .toList();
  }

  List<String> get _seriListesi {
    if (_selectedAltSinavTuru == null || _selectedYayinAdi == null) return [];
    return _mockDenemeler
        .where((e) => e.altSinavTuru == _selectedAltSinavTuru && e.yayinAdi == _selectedYayinAdi)
        .map((e) => e.seri)
        .toSet()
        .toList();
  }

  List<String> get _sayiListesi {
    if (_selectedAltSinavTuru == null || _selectedYayinAdi == null || _selectedSeri == null) return [];
    return _mockDenemeler
        .where((e) => e.altSinavTuru == _selectedAltSinavTuru && e.yayinAdi == _selectedYayinAdi && e.seri == _selectedSeri)
        .map((e) => e.sayi)
        .toSet()
        .toList();
  }

  List<String> get _denemeAdlari {
    if (_selectedAltSinavTuru == null || _selectedYayinAdi == null || _selectedSeri == null || _selectedSayi == null) return [];
    return _mockDenemeler
        .where((e) => e.altSinavTuru == _selectedAltSinavTuru && e.yayinAdi == _selectedYayinAdi && e.seri == _selectedSeri && e.sayi == _selectedSayi)
        .map((e) => e.denemeAdi)
        .toSet()
        .toList();
  }

  void _resetBelow({required int level}) {
    switch (level) {
      case 1:
        _selectedYayinAdi = null;
        _selectedSeri = null;
        _selectedSayi = null;
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      case 2:
        _selectedSeri = null;
        _selectedSayi = null;
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      case 3:
        _selectedSayi = null;
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      case 4:
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      default:
        break;
    }
    _selectedAnswers = [];
    isChecked = false;
    correctCount = 0;
    wrongCount = 0;
    emptyCount = 0;
  }

  void _selectDenemeAdi(String? value) {
    _selectedDenemeAdi = value;
    if (value == null) {
      _selectedDeneme = null;
      _selectedAnswers = [];
      isChecked = false;
      correctCount = 0;
      wrongCount = 0;
      emptyCount = 0;
      return;
    }

    final found = _mockDenemeler.where((e) => e.denemeAdi == value).toList();
    _selectedDeneme = found.isNotEmpty ? found.first : null;
    _selectedAnswers = List<String?>.filled(_selectedDeneme?.answers.length ?? 0, null);
    isChecked = false;
    correctCount = 0;
    wrongCount = 0;
    emptyCount = 0;
  }

  void _toggleAnswer(int index, String option) {
    setState(() {
      if (_selectedAnswers[index] == option) {
        _selectedAnswers[index] = null;
      } else {
        _selectedAnswers[index] = option;
      }
    });
  }

  void _checkAnswers() {
    if (_selectedDeneme == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce bir deneme seçiniz.')));
      return;
    }

    final answeredCount = _selectedAnswers.where((e) => e != null).length;
    final correct = List.generate(_selectedDeneme!.answers.length, (index) {
      final answer = _selectedAnswers[index];
      return answer != null && answer == _selectedDeneme!.answers[index] ? 1 : 0;
    }).fold(0, (sum, value) => sum + value);
    final empty = _selectedDeneme!.answers.length - answeredCount;
    final wrong = answeredCount - correct;

    setState(() {
      isChecked = true;
      correctCount = correct;
      wrongCount = wrong;
      emptyCount = empty;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Yanıtlanan: $answeredCount, Doğru: $correct / ${_selectedDeneme!.answers.length}'),
    ));
  }

  void _savePracticeOpticExamResult() {
    if (!isChecked) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Optik deneme sonucu sisteme kaydedildi.')));
  }

  Widget _buildResultPill(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? initialValue,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdownField(
            label: 'Alt Sınav Türü Seçiniz',
            initialValue: _selectedAltSinavTuru,
            items: _altSinavTurleri,
            enabled: true,
            onChanged: (value) {
              setState(() {
                _selectedAltSinavTuru = value;
                _resetBelow(level: 1);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Yayınevi Seçiniz',
            initialValue: _selectedYayinAdi,
            items: _yayinAdlari,
            enabled: _selectedAltSinavTuru != null,
            onChanged: (value) {
              setState(() {
                _selectedYayinAdi = value;
                _resetBelow(level: 2);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Seri Seçiniz',
            initialValue: _selectedSeri,
            items: _seriListesi,
            enabled: _selectedYayinAdi != null,
            onChanged: (value) {
              setState(() {
                _selectedSeri = value;
                _resetBelow(level: 3);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Deneme Sayısı Seçiniz',
            initialValue: _selectedSayi,
            items: _sayiListesi,
            enabled: _selectedSeri != null,
            onChanged: (value) {
              setState(() {
                _selectedSayi = value;
                _resetBelow(level: 4);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Deneme Adı Seçiniz',
            initialValue: _selectedDenemeAdi,
            items: _denemeAdlari,
            enabled: _selectedSayi != null,
            onChanged: (value) {
              setState(() {
                _selectDenemeAdi(value);
              });
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Seçilen Deneme', style: TextStyle(fontSize: 16, color: colorScheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  _selectedDeneme?.denemeAdi ?? 'Henüz deneme seçilmedi',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDeneme != null) ...[
            Text(
              '${_selectedDeneme!.denemeAdi} için ${_selectedDeneme!.answers.length} soruluk optik form',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Colors.grey.shade200,
                    child: Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Soru No', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...['A', 'B', 'C', 'D', 'E'].map(
                          (e) => Expanded(child: Center(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedDeneme!.answers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text('${index + 1}. soru', style: const TextStyle(fontWeight: FontWeight.w500))),
                            ...['A', 'B', 'C', 'D', 'E'].map((option) {
                              final isSelected = _selectedAnswers[index] == option;
                              return Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _toggleAnswer(index, option),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? colorScheme.primary : Colors.transparent,
                                        border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.shade400),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(option, style: TextStyle(color: isSelected ? colorScheme.onPrimary : Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _checkAnswers,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.primary),
              ),
              child: const Text('KONTROL ET'),
            ),
            if (isChecked) ...[
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildResultPill('Doğru', correctCount.toString(), colorScheme.primary),
                      _buildResultPill('Yanlış', wrongCount.toString(), Colors.red.shade700),
                      _buildResultPill('Boş', emptyCount.toString(), Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isChecked ? _savePracticeOpticExamResult : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isChecked ? colorScheme.primary : Colors.grey,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SİSTEME KAYDET'),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SİSTEME KAYDET'),
              ),
            ],
          ] else ...[
            const SizedBox(height: 24),
            const Text('Deneme seçildikten sonra optik form burada oluşturulacaktır.', textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
