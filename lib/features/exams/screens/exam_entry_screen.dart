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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CustomDropdown(hint: 'Ders seçiniz'),
          const SizedBox(height: 12),
          const CustomDropdown(hint: 'Testle ilgili konu adını seçiniz'),
          const SizedBox(height: 12),
          const CustomDropdown(hint: 'Yayın seçiniz'),
          const SizedBox(height: 12),
          const CustomDropdown(hint: 'Test adını seçiniz'),
          const SizedBox(height: 24),
          const Text(
            'T-TR_01-DST-5 adlı testteki işaretlemeleri aşağıdaki alanda yapabilirsiniz.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Sabit Başlıklı Optik Alan
          Container(
            height: 350,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      const Expanded(flex: 2, child: Text('Soru No', style: TextStyle(fontWeight: FontWeight.bold))),
                      ...['A', 'B', 'C', 'D', 'E'].map((e) => Expanded(child: Center(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold))))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 15,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text('${index + 1}. soru')),
                            ...List.generate(5, (_) => const Expanded(child: Center(child: Icon(Icons.circle_outlined, color: Colors.grey)))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () {}, child: const Text('KONTROL ET')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('SİSTEME KAYDET')),
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
                _buildOpticExamTab(),
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

  Widget _buildOpticExamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          CustomDropdown(hint: 'Deneme alt türü seçiniz'),
          SizedBox(height: 12),
          CustomDropdown(hint: 'Yayınevi seçiniz'),
          SizedBox(height: 12),
          CustomDropdown(hint: 'Denemenin yılını seçiniz'),
          SizedBox(height: 12),
          CustomDropdown(hint: 'Deneme adı seçiniz'),
          SizedBox(height: 24),
          Text('DST_26_TYT_2 adlı denemenin işaretlemelerini aşağıda yapabilirsiniz.', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Center(child: Text('(Optik alan tasarımı Test girişindeki gibi buraya eklenecektir)')),
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