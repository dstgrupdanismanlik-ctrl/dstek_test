import 'package:flutter/material.dart';

class AcademicStudyRoomScreen extends StatefulWidget {
  const AcademicStudyRoomScreen({Key? key}) : super(key: key);

  @override
  State<AcademicStudyRoomScreen> createState() => _AcademicStudyRoomScreenState();
}

class _AcademicStudyRoomScreenState extends State<AcademicStudyRoomScreen> {
  // 1. Durum (State) Değişkenleri
  String? selectedDers;
  String? selectedKonu;
  String? selectedArac;
  String? selectedKaynak;

  // Sisteme giriş yapan öğrencinin sınav türü (Firestore bağlanınca profilden gelecek)
  final String studentExamType = "YKS"; 

  // 2. Sahte (Mock) Veritabanı (Firestore'a geçince bu veriler dinamik çekilecek)
  final Map<String, List<String>> dersler = {
    "YKS": ["TYT Türkçe", "TYT Matematik", "AYT Fizik"],
    "LGS": ["LGS Türkçe", "LGS Matematik", "LGS Fen Bilimleri"],
  };

  final Map<String, List<String>> konular = {
    "TYT Türkçe": ["Sözcükte Anlam", "Cümlede Anlam", "Paragraf"],
    "TYT Matematik": ["Temel Kavramlar", "Üslü Sayılar", "Köklü Sayılar"],
    "AYT Fizik": ["Vektörler", "Bağıl Hareket", "Newton'un Hareket Yasaları"],
    "LGS Türkçe": ["Fiilimsiler", "Cümlenin Ögeleri", "Metin Türleri"],
    "LGS Matematik": ["Çarpanlar ve Katlar", "EBOB-EKOK", "Olasılık"],
    "LGS Fen Bilimleri": ["Mevsimler ve İklim", "DNA ve Genetik Kod", "Basınç"],
  };

  final List<String> araclar = [
    "Videolar",
    "Konu Anlatım Dosyaları (PDF)",
    "Soru Bankası"
  ];

  final Map<String, List<String>> kaynaklar = {
    "Videolar": ["YouTube - DST Kanalı", "EBA TV Gömülü Link", "Özel Kaynak V1"],
    "Konu Anlatım Dosyaları (PDF)": ["DST Yayınları PDF Föy", "Google Drive Kaynağı", "Özel Ders Notları"],
    "Soru Bankası": ["DST Dijital Soru Havuzu", "MEB Kazanım Testleri", "Çıkmış Sorular"],
  };

  // 3. Seçim Sıfırlama Mantığı (Üst menü değişince alt menüler temizlenir)
  void _onDersChanged(String? newValue) {
    setState(() {
      selectedDers = newValue;
      selectedKonu = null;
      selectedArac = null;
      selectedKaynak = null;
    });
  }

  void _onKonuChanged(String? newValue) {
    setState(() {
      selectedKonu = newValue;
      selectedArac = null;
      selectedKaynak = null;
    });
  }

  void _onAracChanged(String? newValue) {
    setState(() {
      selectedArac = newValue;
      selectedKaynak = null;
    });
  }

  void _onKaynakChanged(String? newValue) {
    setState(() {
      selectedKaynak = newValue;
    });
  }

  // 4. Kaynağa Git Aksiyonu
  void _kaynagaGit() {
    // Burada URL yönlendirme (url_launcher vb.) işlemleri yapılacak.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$selectedKaynak kaynağına yönlendiriliyorsunuz...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Öğrencinin sınav türüne göre ders listesini çek
    final currentDersler = dersler[studentExamType] ?? [];
    // Seçilen derse göre konu listesini çek
    final currentKonular = selectedDers != null ? konular[selectedDers!] ?? [] : [];
    // Seçilen araca göre kaynak listesini çek
    final currentKaynaklar = selectedArac != null ? kaynaklar[selectedArac!] ?? [] : [];

    // Return only the inner content so this widget can be embedded inside the main Scaffold's body.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), // Web/Tablet uyumluluğu için genişlik sınırı
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Akademik Materyal Seçimi",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Çalışmak istediğiniz konuya ait dijital materyallere ulaşmak için aşağıdaki seçimleri yapınız.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- 1. DERS SEÇİMİ ---
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Ders Seçiniz",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    initialValue: selectedDers,
                    items: currentDersler.map((ders) {
                      return DropdownMenuItem<String>(
                        value: ders,
                        child: Text(ders),
                      );
                    }).toList(),
                    onChanged: _onDersChanged,
                  ),
                  const SizedBox(height: 20),

                  // --- 2. KONU SEÇİMİ ---
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: selectedDers == null ? "Önce Ders Seçiniz" : "Konu Seçiniz",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.format_list_bulleted),
                      filled: selectedDers == null,
                      fillColor: Colors.grey.shade200,
                    ),
                    initialValue: selectedKonu,
                    items: currentKonular.map((konu) {
                      return DropdownMenuItem<String>(
                        value: konu,
                        child: Text(konu),
                      );
                    }).toList(),
                    onChanged: selectedDers == null ? null : _onKonuChanged,
                    disabledHint: const Text("Önce Ders Seçiniz"),
                  ),
                  const SizedBox(height: 20),

                  // --- 3. ARAÇ SEÇİMİ ---
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: selectedKonu == null ? "Önce Konu Seçiniz" : "Çalışma Aracını Seçiniz",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.build),
                      filled: selectedKonu == null,
                      fillColor: Colors.grey.shade200,
                    ),
                    initialValue: selectedArac,
                    items: araclar.map((arac) {
                      return DropdownMenuItem<String>(
                        value: arac,
                        child: Text(arac),
                      );
                    }).toList(),
                    onChanged: selectedKonu == null ? null : _onAracChanged,
                    disabledHint: const Text("Önce Konu Seçiniz"),
                  ),
                  const SizedBox(height: 20),

                  // --- ARAÇ ONAY METNİ & 4. KAYNAK SEÇİMİ ---
                  if (selectedArac != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        "Seçtiğiniz '$selectedArac' aracı için aşağıdan kaynak seçiniz.",
                        style: TextStyle(color: Colors.blue.shade900, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Kaynak Seçiniz",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      initialValue: selectedKaynak,
                      items: currentKaynaklar.map((kaynak) {
                        return DropdownMenuItem<String>(
                          value: kaynak,
                          child: Text(kaynak),
                        );
                      }).toList(),
                      onChanged: _onKaynakChanged,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- KAYNAK ONAY METNİ & GİT BUTONU ---
                  if (selectedKaynak != null) ...[
                     Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        "Seçtiğiniz '$selectedKaynak' kaynağına ulaşmanızı sağlayacak link aşağıdadır.",
                        style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _kaynagaGit,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text(
                          "KAYNAĞA GİT",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
