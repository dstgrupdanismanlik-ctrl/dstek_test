import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Text Form Kontrolleri
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentPhoneController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _firstNetController = TextEditingController();
  final TextEditingController _targetRankingController = TextEditingController();

  // Açılır Menü Seçimleri
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedEducationLevel;
  String? _selectedExam;
  String? _selectedField;

  // Veritabanı Listeleri
  List<String> _cities = [];
  Map<String, List<dynamic>> _districtsMap = {};
  List<String> _educationLevels = [];
  List<String> _exams = [];
  Map<String, dynamic> _examMatrixMap = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentPhoneController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _schoolController.dispose();
    _firstNetController.dispose();
    _targetRankingController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileOptions() async {
    try {
      final optionsDoc = await _firestore.collection('system_constants').doc('profile_options').get();
      if (optionsDoc.exists) {
        final data = optionsDoc.data()!;
        _districtsMap = Map<String, List<dynamic>>.from(data['cities'] ?? {});
        _cities = _districtsMap.keys.toList()..sort();
        _educationLevels = List<String>.from(data['education_levels'] ?? []);
        _exams = List<String>.from(data['exams'] ?? []);
      }

      final matrixDoc = await _firestore.collection('system_constants').doc('exam_matrix').get();
      if (matrixDoc.exists) {
        _examMatrixMap = matrixDoc.data() ?? {};
      }
    } catch (e) {
      debugPrint('Sabitler yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _currentDistricts => _selectedCity == null ? [] : List<String>.from(_districtsMap[_selectedCity] ?? []);
  List<String> get _currentFields => (_selectedExam == null || !_examMatrixMap.containsKey(_selectedExam)) ? [] : List<String>.from(_examMatrixMap[_selectedExam]['fields'] ?? []);

  // Form Elemanı Yardımcı Metodu (Filtreleme ve İpucu (Hint) Özelliği Eklendi)
  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text, List<TextInputFormatter>? formatters, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint, // Gri bilgilendirme metni
          border: const OutlineInputBorder()
        ),
        validator: (value) => value == null || value.isEmpty ? 'Bu alan boş bırakılamaz' : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kartım'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Kişisel ve İletişim Bilgileri'),
              _buildTextField('Ad Soyad', _nameController, hint: 'Örn: Ahmet Yılmaz'),
              
              _buildTextField('Öğrenci Telefon', _studentPhoneController, 
                type: TextInputType.phone, 
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'Sadece rakam giriniz (Örn: 5551234567)'
              ),
              
              _buildTextField('Veli Adı Soyadı', _parentNameController, hint: 'Örn: Ayşe Yılmaz'),
              
              _buildTextField('Veli Telefon', _parentPhoneController, 
                type: TextInputType.phone, 
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'Sadece rakam giriniz (Örn: 5551234567)'
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'İl', border: OutlineInputBorder()),
                value: _selectedCity,
                items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() { _selectedCity = val; _selectedDistrict = null; }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'İlçe', border: OutlineInputBorder()),
                value: _selectedDistrict,
                items: _currentDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: _selectedCity == null ? null : (val) => setState(() => _selectedDistrict = val),
                disabledHint: const Text('Önce İl Seçiniz'),
              ),

              const Divider(height: 48, thickness: 1),
              _buildSectionTitle('Akademik Bilgiler'),
              _buildTextField('Okulunuz', _schoolController, hint: 'Örn: YBAL, Eşref Ergin'),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Öğrenim Durumu', border: OutlineInputBorder()),
                value: _selectedEducationLevel,
                items: _educationLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => _selectedEducationLevel = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Hedef Sınav', border: OutlineInputBorder()),
                value: _selectedExam,
                items: _exams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() { _selectedExam = val; _selectedField = null; }),
              ),
              const SizedBox(height: 16),
              if (_currentFields.isNotEmpty && _currentFields.first != 'Alan Yok')
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Alanınız (Bölüm)', border: OutlineInputBorder()),
                  value: _selectedField,
                  items: _currentFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) => setState(() => _selectedField = val),
                ),

              const Divider(height: 48, thickness: 1),
              _buildSectionTitle('Hedef ve Başlangıç Verileri'),
              
              _buildTextField('İlk Başarı / Tanılama Netiniz', _firstNetController, 
                type: const TextInputType.numberWithOptions(decimal: true),
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                hint: 'Nümerik değer giriniz (Örn: 45.5 veya 45,5)'
              ),
              
              _buildTextField('Hedeflenen Sıralama', _targetRankingController,
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'Sadece rakam giriniz (Örn: 50000)'
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil başarıyla kaydedildi!')));
                    }
                  },
                  child: const Text('Bilgileri Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}