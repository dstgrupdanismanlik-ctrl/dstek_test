import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../shared/widgets/app_drawer.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

enum _SyncTable {
  curriculum,
  generalDefinitions,
  systemConstants,
  opticTests,
  opticPracticeExams,
  student_xray,
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isDeleting = false;
  String _activeTableLabel = '';

  String _syncTableLabel(_SyncTable table) {
    switch (table) {
      case _SyncTable.curriculum:
        return 'YKS Dersleri ve Araclari (curriculum)';
      case _SyncTable.generalDefinitions:
        return 'Genel Tanim Tablosu (general_definitions)';
      case _SyncTable.systemConstants:
        return 'Sistem Sabitleri (system_constants)';
      case _SyncTable.opticTests:
        return 'YKS Optikli Testler';
      case _SyncTable.opticPracticeExams:
        return 'YKS Optikli Denemeler';
      case _SyncTable.student_xray:
        return 'Öğrenci Konu Röntgeni (Geçici Test)';
    }
  }

  Future<void> _showTableSelectionDialog() async {
    final selectedTables = <_SyncTable>{};

    final result = await showDialog<Set<_SyncTable>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void onToggle(_SyncTable table, bool isSelected) {
              setDialogState(() {
                if (isSelected) {
                  selectedTables.add(table);
                } else {
                  selectedTables.remove(table);
                }
              });
            }

            return AlertDialog(
              title: const Text('Guncellenecek Tablolari Secin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedTables.contains(_SyncTable.curriculum),
                      onChanged: (value) =>
                          onToggle(_SyncTable.curriculum, value ?? false),
                      title: Text(_syncTableLabel(_SyncTable.curriculum)),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedTables.contains(
                        _SyncTable.generalDefinitions,
                      ),
                      onChanged: (value) => onToggle(
                        _SyncTable.generalDefinitions,
                        value ?? false,
                      ),
                      title: Text(
                        _syncTableLabel(_SyncTable.generalDefinitions),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedTables.contains(
                        _SyncTable.systemConstants,
                      ),
                      onChanged: (value) =>
                          onToggle(_SyncTable.systemConstants, value ?? false),
                      title: Text(_syncTableLabel(_SyncTable.systemConstants)),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedTables.contains(_SyncTable.opticTests),
                      onChanged: (value) =>
                          onToggle(_SyncTable.opticTests, value ?? false),
                      title: Text(_syncTableLabel(_SyncTable.opticTests)),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedTables.contains(_SyncTable.opticPracticeExams),
                      onChanged: (value) =>
                          onToggle(_SyncTable.opticPracticeExams, value ?? false),
                      title: Text(_syncTableLabel(_SyncTable.opticPracticeExams)),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedTables.contains(_SyncTable.student_xray),
                      onChanged: (value) =>
                          onToggle(_SyncTable.student_xray, value ?? false),
                      title: Text(_syncTableLabel(_SyncTable.student_xray)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgec'),
                ),
                ElevatedButton(
                  onPressed: selectedTables.isEmpty
                      ? null
                      : () => Navigator.of(
                            dialogContext,
                          ).pop(Set<_SyncTable>.from(selectedTables)),
                  child: const Text('Guncelle'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    await _syncDatabase(result);
  }

  Future<int> _upsertTableData({
    required FirebaseFirestore firestore,
    required String payloadKey,
    required String collectionName,
    required List<String> docKeyCandidates,
    required dynamic payload,
  }) async {
    if (mounted) {
      setState(() {
        _activeTableLabel = payloadKey;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$payloadKey tablosu yukleniyor...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final entries = <MapEntry<String?, Map<String, dynamic>>>[];

    if (payload is List) {
      for (final item in payload) {
        if (item is! Map) continue;
        entries.add(MapEntry(null, Map<String, dynamic>.from(item)));
      }
    } else if (payload is Map) {
      payload.forEach((key, value) {
        if (value is Map) {
          entries.add(
            MapEntry(key.toString(), Map<String, dynamic>.from(value)),
          );
        }
      });
    } else {
      return 0;
    }

    var processedCount = 0;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final data = entry.value;
      final docId = _resolveDocId(
        data: data,
        candidates: docKeyCandidates,
        mapKey: entry.key,
        fallbackIndex: i,
      );

      await firestore
          .collection(collectionName)
          .doc(docId)
          .set(data, SetOptions(merge: true));
      processedCount++;
    }

    return processedCount;
  }

  String _resolveDocId({
    required Map<String, dynamic> data,
    required List<String> candidates,
    required String? mapKey,
    required int fallbackIndex,
  }) {
    for (final key in candidates) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    if (mapKey != null && mapKey.trim().isNotEmpty) {
      return mapKey.trim();
    }

    return 'record_$fallbackIndex';
  }

  Map<String, dynamic> _parseJsonObject(dynamic rawValue) {
    if (rawValue is Map) {
      return Map<String, dynamic>.from(rawValue);
    }

    if (rawValue is! String || rawValue.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  int _readScoreValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _calculatePercentage(Map<String, dynamic> scoreData) {
    final correct = _readScoreValue(scoreData, 'D');
    final wrong = _readScoreValue(scoreData, 'Y');
    final blank = _readScoreValue(scoreData, 'B');
    final total = correct + wrong + blank;

    if (total == 0) {
      return 0;
    }

    return (correct / total) * 100;
  }

  bool _hasAnsweredData(Map<String, dynamic> scoreData) {
    return _readScoreValue(scoreData, 'D') > 0 ||
        _readScoreValue(scoreData, 'Y') > 0 ||
        _readScoreValue(scoreData, 'B') > 0;
  }

  double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) {
        return null;
      }
      return double.tryParse(normalized);
    }

    return null;
  }

  dynamic _prepareCurriculumPayload(dynamic payload) {
    Map<String, dynamic> enrichRecord(Map<String, dynamic> rawRecord) {
      final data = Map<String, dynamic>.from(rawRecord);
      data['ders_ici_on_kosul'] = data['ders_ici_on_kosul']?.toString();
      data['ders_disi_on_kosul'] = data['ders_disi_on_kosul']?.toString();
      data['tekrar_calisma_saati'] =
          _parseDouble(data['tekrar_calisma_saati']) ??
          _parseDouble(data['tahmini_calisma_saati']);
      data['soru_cozme_saati'] =
          _parseDouble(data['soru_cozme_saati']) ??
          _parseDouble(data['tahmini_calisma_saati']);
      return data;
    }

    if (payload is List) {
      return payload
          .map((item) => item is Map ? enrichRecord(Map<String, dynamic>.from(item)) : item)
          .toList();
    }

    if (payload is Map) {
      final prepared = <String, dynamic>{};
      payload.forEach((key, value) {
        if (value is Map) {
          prepared[key.toString()] = enrichRecord(Map<String, dynamic>.from(value));
        } else {
          prepared[key.toString()] = value;
        }
      });
      return prepared;
    }

    return payload;
  }

  dynamic _prepareStudentXrayPayload(dynamic payload) {
    Map<String, dynamic> enrichRecord(Map<String, dynamic> rawRecord) {
      final record = Map<String, dynamic>.from(rawRecord);
      final manuelMap = _parseJsonObject(record['manuel_d_y_b']);
      final optikMap = _parseJsonObject(record['optik_test_d_y_b']);

      final manuelYuzde = _calculatePercentage(manuelMap);
      final optikYuzde = _calculatePercentage(optikMap);
      final hasManuel = _hasAnsweredData(manuelMap);
      final hasOptik = _hasAnsweredData(optikMap);
      final manuel = manuelYuzde;
      final optik = optikYuzde;

      final double guvenilirBasariSkoru;
      if (hasOptik && hasManuel) {
        guvenilirBasariSkoru = (optikYuzde * 0.70) + (manuelYuzde * 0.30);
      } else if (hasOptik) {
        guvenilirBasariSkoru = optikYuzde;
      } else if (hasManuel) {
        guvenilirBasariSkoru = manuelYuzde;
      } else {
        guvenilirBasariSkoru = 0;
      }

      record['manuel_d_y_b'] = manuelMap;
      record['optik_test_d_y_b'] = optikMap;
      record['manuel_yuzde'] = manuelYuzde;
      record['optik_yuzde'] = optikYuzde;
      record['guvenilir_basari_skoru'] = guvenilirBasariSkoru;
      debugPrint('🛠️ 70/30 TEST -> Optik: $optik | Manuel: $manuel | SONUÇ: $guvenilirBasariSkoru');
      return record;
    }

    if (payload is List) {
      return payload
          .map((item) => item is Map ? enrichRecord(Map<String, dynamic>.from(item)) : item)
          .toList();
    }

    if (payload is Map) {
      final prepared = <String, dynamic>{};
      payload.forEach((key, value) {
        if (value is Map) {
          prepared[key.toString()] = enrichRecord(Map<String, dynamic>.from(value));
        } else {
          prepared[key.toString()] = value;
        }
      });
      return prepared;
    }

    return payload;
  }

  Future<void> _clearCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emin misiniz?'),
          content: const Text(
            'Bu işlem curriculum, general_definitions, system_constants, yks_optikli_test ve yks_optikli_deneme koleksiyonlarındaki tüm verileri silecektir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await _clearCollection('curriculum');
      await _clearCollection('general_definitions');
      await _clearCollection('system_constants');
      await _clearCollection('yks_optikli_test');
      await _clearCollection('yks_optikli_deneme');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veritabanı temizleme işlemi tamamlandı.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Temizleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _syncDatabase(Set<_SyncTable> selectedTables) async {
    if (selectedTables.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://script.google.com/macros/s/AKfycbxf9Ky8J_aVRS672kQXHyiLgzJ0gdlqusRyd--CbwpBxc5pm4_Ar4rz46o2F0j0ga_R/exec',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        var totalCount = 0;

        String _normalize(String value) {
          return value
              .toLowerCase()
              .replaceAll('ç', 'c')
              .replaceAll('ğ', 'g')
              .replaceAll('ı', 'i')
              .replaceAll('ö', 'o')
              .replaceAll('ş', 's')
              .replaceAll('ü', 'u')
              .replaceAll('_', ' ')
              .replaceAll('-', ' ');
        }

        String? _findPayloadKey(List<String> tokens) {
          for (final key in data.keys) {
            final normalizedKey = _normalize(key);
            for (final token in tokens) {
              if (normalizedKey.contains(token)) {
                return key;
              }
            }
          }
          return null;
        }

        final yksKey = _findPayloadKey(['yks', 'dersler', 'yks dersleri']);
        final t1Key = _findPayloadKey([
          't-1',
          't 1',
          'tanim',
          'genel tanimlar',
        ]);
        final sabitlerKey = _findPayloadKey([
          'tablo9',
          'tablo 9',
          'sabitler',
          'sistem sabitleri',
        ]);
        final studentXrayKey = _findPayloadKey([
          'tablo4',
          'tablo 4',
          'rontgen',
          'xray',
        ]);
        final optikTestKey = data.containsKey('YKS OPTİKLİ TEST') ? 'YKS OPTİKLİ TEST' : null;
        final optikDenemeKey = data.containsKey('YKS OPTİKLİ DENEME') ? 'YKS OPTİKLİ DENEME' : null;

        if (selectedTables.contains(_SyncTable.curriculum)) {
          totalCount += await _upsertTableData(
            firestore: _firestore,
            payloadKey: yksKey ?? 'yks_dersleri',
            collectionName: 'curriculum',
            docKeyCandidates: const ['konu_kodu', 'id', 'kod'],
            payload: yksKey == null ? null : _prepareCurriculumPayload(data[yksKey]),
          );
        }

        if (selectedTables.contains(_SyncTable.generalDefinitions)) {
          totalCount += await _upsertTableData(
            firestore: _firestore,
            payloadKey: t1Key ?? 'genel_tanimlar',
            collectionName: 'general_definitions',
            docKeyCandidates: const ['id', 'tanim_kodu', 'kod', 'key'],
            payload: t1Key == null ? null : data[t1Key],
          );
        }

        if (selectedTables.contains(_SyncTable.systemConstants)) {
          totalCount += await _upsertTableData(
            firestore: _firestore,
            payloadKey: sabitlerKey ?? 'sistem_sabitleri',
            collectionName: 'system_constants',
            docKeyCandidates: const ['id', 'sabit_kodu', 'kod', 'key'],
            payload: sabitlerKey == null ? null : data[sabitlerKey],
          );
        }

        if (selectedTables.contains(_SyncTable.student_xray)) {
          totalCount += await _upsertTableData(
            firestore: _firestore,
            payloadKey: studentXrayKey ?? 'student_subjects_xray',
            collectionName: 'student_subjects_xray',
            docKeyCandidates: const ['id', 'ogrenci_no', 'student_id', 'key'],
            payload: studentXrayKey == null
                ? null
                : _prepareStudentXrayPayload(data[studentXrayKey]),
          );
        }

        if (selectedTables.contains(_SyncTable.opticTests)) {
          totalCount += await _upsertTableData(
            firestore: _firestore,
            payloadKey: optikTestKey ?? 'yks_optikli_test',
            collectionName: 'yks_optikli_test',
            docKeyCandidates: const ['test_adi', 'id', 'test_kodu'],
            payload: optikTestKey == null ? null : data[optikTestKey],
          );
        }

        if (selectedTables.contains(_SyncTable.opticPracticeExams)) {
          totalCount += await _upsertTableData(
            firestore: _firestore,
            payloadKey: optikDenemeKey ?? 'yks_optikli_deneme',
            collectionName: 'yks_optikli_deneme',
            docKeyCandidates: const ['deneme_adi', 'id', 'deneme_kodu'],
            payload: optikDenemeKey == null ? null : data[optikDenemeKey],
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Toplam $totalCount kayit secilen tablolardan Firestore\'a aktarildi/guncellendi!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('API Hatasi: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri aktarim hatasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeTableLabel = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistem Kurulumu (Admin)')),
      drawer: const AppDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'Google Sheets Veritabani Senkronizasyonu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu islem, tablodaki guncel YKS ders ve konu listelerini Firestore "curriculum" koleksiyonuna aktarir.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  _activeTableLabel.isEmpty
                      ? 'Veri yukleniyor...'
                      : 'Yukleniyor: $_activeTableLabel',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _isDeleting ? null : _showTableSelectionDialog,
                  icon: const Icon(Icons.cloud_sync),
                  label: const Text('SISTEMI KUR (EXCEL GUNCELLE)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isDeleting ? null : _clearDatabase,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_forever),
                  label: const Text('VERITABANINI TEMIZLE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
