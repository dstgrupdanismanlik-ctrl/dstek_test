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

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isDeleting = false;
  String _activeTableLabel = '';

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
            'Bu işlem curriculum, general_definitions ve system_constants koleksiyonlarındaki tüm verileri silecektir.',
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

  Future<void> _syncDatabase() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://script.google.com/macros/s/AKfycbxf9Ky8J_aVRS672kQXHyiLgzJ0gdlqusRyd--CbwpBxc5pm4_Ar4rz46o2F0j0ga_R/exec',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        var totalCount = 0;

        String _normalize(String value) {
          return value.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
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
        final t1Key = _findPayloadKey(['t-1', 't 1', 'tanim', 'genel tanimlar']);
        final sabitlerKey = _findPayloadKey(['tablo9', 'tablo 9', 'sabitler', 'sistem sabitleri']);

        totalCount += await _upsertTableData(
          firestore: _firestore,
          payloadKey: yksKey ?? 'yks_dersleri',
          collectionName: 'curriculum',
          docKeyCandidates: const ['konu_kodu', 'id', 'kod'],
          payload: yksKey == null ? null : data[yksKey],
        );

        totalCount += await _upsertTableData(
          firestore: _firestore,
          payloadKey: t1Key ?? 'genel_tanimlar',
          collectionName: 'general_definitions',
          docKeyCandidates: const ['id', 'tanim_kodu', 'kod', 'key'],
          payload: t1Key == null ? null : data[t1Key],
        );

        totalCount += await _upsertTableData(
          firestore: _firestore,
          payloadKey: sabitlerKey ?? 'sistem_sabitleri',
          collectionName: 'system_constants',
          docKeyCandidates: const ['id', 'sabit_kodu', 'kod', 'key'],
          payload: sabitlerKey == null ? null : data[sabitlerKey],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Toplam $totalCount kayit Firestore\'a aktarildi/guncellendi!'),
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
      appBar: AppBar(
        title: const Text('Sistem Kurulumu (Admin)'),
      ),
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
                  onPressed: _isDeleting ? null : _syncDatabase,
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
