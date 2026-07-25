import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

class TopicManagementScreen extends StatefulWidget {
  const TopicManagementScreen({super.key});

  @override
  State<TopicManagementScreen> createState() => _TopicManagementScreenState();
}

class _TopicManagementScreenState extends State<TopicManagementScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _konuKoduController = TextEditingController();
  final TextEditingController _dersAdiController = TextEditingController();
  final TextEditingController _konuAdiController = TextEditingController();
  final TextEditingController _calismaSuresiController = TextEditingController();
  final TextEditingController _yayilimGunController = TextEditingController();
  final TextEditingController _onKosulKoduController = TextEditingController();

  String _selectedSinavTuru = 'TYT';
  bool _isMasterTopic = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _konuKoduController.dispose();
    _dersAdiController.dispose();
    _konuAdiController.dispose();
    _calismaSuresiController.dispose();
    _yayilimGunController.dispose();
    _onKosulKoduController.dispose();
    super.dispose();
  }

  String _normalizeRole(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  String _resolveInstitutionCode(Map<String, dynamic>? userData) {
    if (userData == null) {
      return '';
    }

    final candidates = [
      userData['institutionCode'],
      userData['kurum_kodu'],
      userData['kurumKodu'],
      userData['institution_code'],
      userData['code'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final role = _normalizeRole(authProvider.currentUserData?['role']);
    final canSetMaster = role == 'admin' || role == 'yönetici';
    final institutionCode = _isMasterTopic && canSetMaster
        ? 'MASTER'
        : _resolveInstitutionCode(authProvider.currentUserData);

    final calismaSuresiSaat = int.tryParse(_calismaSuresiController.text.trim());
    final yayilimGun = int.tryParse(_yayilimGunController.text.trim());

    if (calismaSuresiSaat == null || yayilimGun == null) {
      _showSnackBar('Süre ve gün alanlarına sayısal değer girin.', Colors.red);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('mufredat').add({
        'konuKodu': _konuKoduController.text.trim(),
        'sinavTuru': _selectedSinavTuru,
        'dersAdi': _dersAdiController.text.trim(),
        'konuAdi': _konuAdiController.text.trim(),
        'calismaSuresiSaat': calismaSuresiSaat,
        'yayilimGun': yayilimGun,
        'onKosulKodu': _onKosulKoduController.text.trim(),
        'isActive': true,
        'institutionCode': institutionCode,
      });

      if (!mounted) {
        return;
      }

      _konuKoduController.clear();
      _dersAdiController.clear();
      _konuAdiController.clear();
      _calismaSuresiController.clear();
      _yayilimGunController.clear();
      _onKosulKoduController.clear();
      _selectedSinavTuru = 'TYT';
      _isMasterTopic = false;

      _showSnackBar('Müfredat konusu başarıyla kaydedildi.', Colors.green);
    } catch (error) {
      if (mounted) {
        _showSnackBar('Kayıt sırasında hata oluştu: $error', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = _normalizeRole(authProvider.currentUserData?['role']);
    final canSetMaster = role == 'admin' || role == 'yönetici';

    if (!canSetMaster) {
      _isMasterTopic = false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Müfredat İşlemleri')),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const Text(
                          'Sisteme Yeni Konu / Müfredat Ekle',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _konuKoduController,
                          decoration: const InputDecoration(
                            labelText: 'Konu Kodu',
                            prefixIcon: Icon(Icons.qr_code_2_outlined),
                            border: OutlineInputBorder(),
                            helperText: 'Format: SINAV_DERS_SIRA (Örn: T_TR_28)',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Konu kodu zorunludur';
                            }
                            if (text.contains('-')) {
                              return 'Lütfen tire (-) yerine alt çizgi (_) kullanın. Örn: T_TR_28';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSinavTuru,
                          decoration: const InputDecoration(
                            labelText: 'Sınav Türü',
                            prefixIcon: Icon(Icons.school_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TYT', child: Text('TYT')),
                            DropdownMenuItem(value: 'AYT', child: Text('AYT')),
                            DropdownMenuItem(value: 'YDT', child: Text('YDT')),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedSinavTuru = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dersAdiController,
                          decoration: const InputDecoration(
                            labelText: 'Ders Adı',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ders adı zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _konuAdiController,
                          decoration: const InputDecoration(
                            labelText: 'Konu Adı',
                            prefixIcon: Icon(Icons.topic_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Konu adı zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _calismaSuresiController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Ana Çalışma Süresi (Saat)',
                            prefixIcon: Icon(Icons.timelapse_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ana çalışma süresi zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _yayilimGunController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Kaç Güne Yayılır (Gün)',
                            prefixIcon: Icon(Icons.date_range_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Yayılım günü zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _onKosulKoduController,
                          decoration: const InputDecoration(
                            labelText: 'Ders İçi Ön Koşul Kodu',
                            prefixIcon: Icon(Icons.link_outlined),
                            border: OutlineInputBorder(),
                            helperText:
                                'Bağlı olduğu önceki konunun kodu (Opsiyonel)',
                          ),
                        ),
                        if (canSetMaster) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _isMasterTopic,
                            onChanged: (value) {
                              setState(() {
                                _isMasterTopic = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'Bu Konuyu Tüm Kurumlarda Geçerli Kıl (MASTER)',
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: const Icon(Icons.save_outlined),
                            label: _isSaving
                                ? const Text('Kaydediliyor...')
                                : const Text('Müfredatı Kaydet'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}