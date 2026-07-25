import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExamProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _toplamSoru = 0;
  int _gunlukSoru = 0;
  double _genelBasari = 0.0;
  bool _isLoading = false;

  // Zaman Filtreleme Değişkenleri
  String _activeTimeFilter = 'Gün';
  int _filteredToplamSoru = 0;
  double _filteredGenelBasari = 0.0;
  List<Map<String, dynamic>> _allLogs = [];

  // Son 6 haftanın soru çözüm dağılımı (Çizgi grafik için)
  List<double> _altiHaftalikDagilim = List.filled(6, 0.0);

  int get toplamSoru => _toplamSoru;
  int get gunlukSoru => _gunlukSoru;
  double get genelBasari => _genelBasari;
  bool get isLoading => _isLoading;
  String get activeTimeFilter => _activeTimeFilter;
  int get filteredToplamSoru => _filteredToplamSoru;
  double get filteredGenelBasari => _filteredGenelBasari;
  List<double> get altiHaftalikDagilim => _altiHaftalikDagilim;

  List<Map<String, dynamic>> _xrayData = [];
  List<Map<String, dynamic>> get xrayData => _xrayData;

  ExamProvider() {
    _listenToAllExamData();
  }

  void setTimeFilter(String filter) {
    if (_activeTimeFilter != filter) {
      _activeTimeFilter = filter;
      _applyTimeFilter();
    }
  }

  void _listenToAllExamData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    int logsTotalQ = 0;
    int logsTotalC = 0;
    int logsDailyQ = 0;
    List<double> logsWeekly = List.filled(6, 0.0);

    int xrayTotalQ = 0;
    int xrayTotalC = 0;
    List<double> xrayWeekly = List.filled(6, 0.0);

    void calculateAndNotify() {
      _toplamSoru = logsTotalQ + xrayTotalQ;
      final totalCorrect = logsTotalC + xrayTotalC;

      _gunlukSoru = logsDailyQ;
      _genelBasari = _toplamSoru > 0 ? (totalCorrect / _toplamSoru) * 100 : 0.0;

      // Haftalık verileri birleştir
      for (int i = 0; i < 6; i++) {
        _altiHaftalikDagilim[i] = logsWeekly[i] + xrayWeekly[i];
      }

      _isLoading = false;
      _applyTimeFilter();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // 1. YENİ GÜNLÜKLER (GERÇEK ZAMANLI)
    _firestore
        .collection('student_exam_logs')
        .where('student_id', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      logsTotalQ = 0;
      logsTotalC = 0;
      logsDailyQ = 0;
      logsWeekly = List.filled(6, 0.0);
      _allLogs.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        _allLogs.add(data);
        int docTotal = 0;
        int correct = 0;

        if (data.containsKey('lesson_results')) {
          final lessons = data['lesson_results'] as List<dynamic>? ?? [];
          for (var lesson in lessons) {
            if (lesson is Map<String, dynamic>) {
              correct += (lesson['correct'] ?? 0) as int;
              docTotal += correct + ((lesson['wrong'] ?? 0) as int) + ((lesson['empty'] ?? 0) as int);
            }
          }
        } else {
          correct = (data['correct_count'] ?? 0) as int;
          docTotal = correct + ((data['wrong_count'] ?? 0) as int) + ((data['empty_count'] ?? 0) as int);
        }

        logsTotalQ += docTotal;
        logsTotalC += correct;

        final createdAt = data['created_at'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          if (date.isAfter(startOfDay)) {
            logsDailyQ += docTotal;
          }
          // Son 6 hafta (42 gün) hesaplaması
          final difference = now.difference(date).inDays;
          if (difference < 42 && difference >= 0) {
            int weekIndex = 5 - (difference ~/ 7);
            logsWeekly[weekIndex] += docTotal.toDouble();
          }
        }
      }
      calculateAndNotify();
    });

    // 2. EXCEL RÖNTGEN VERİLERİ (ZAMAN MAKİNESİ SİMÜLASYONU)
    _firestore
        .collection('student_subjects_xray')
        .where('ogrenci_id', isEqualTo: user.email)
        .snapshots()
        .listen((snapshot) {
      xrayTotalQ = 0;
      xrayTotalC = 0;
      xrayWeekly = List.filled(6, 0.0);
      _xrayData.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        _xrayData.add(data);

        int docTotal = 0;
        int docCorrect = 0;

        final optik = data['optik_test_d_y_b'] as Map<String, dynamic>? ?? {};
        final manuel = data['manuel_d_y_b'] as Map<String, dynamic>? ?? {};

        final num oD = (optik['D'] ?? 0) as num;
        final num oY = (optik['Y'] ?? 0) as num;
        final num oB = (optik['B'] ?? 0) as num;
        docCorrect += oD.toInt();
        docTotal += (oD + oY + oB).toInt();

        final num mD = (manuel['D'] ?? 0) as num;
        final num mY = (manuel['Y'] ?? 0) as num;
        final num mB = (manuel['B'] ?? 0) as num;
        docCorrect += mD.toInt();
        docTotal += (mD + mY + mB).toInt();

        xrayTotalC += docCorrect;
        xrayTotalQ += docTotal;

        // ZAMAN MAKİNESİ: ID Hash'ine göre son 42 güne homojen dağıt
        final hash = doc.id.hashCode.abs();
        final simulatedDaysAgo = hash % 42;
        int weekIndex = 5 - (simulatedDaysAgo ~/ 7);
        xrayWeekly[weekIndex] += docTotal.toDouble();
      }
      calculateAndNotify();
    });
  }

  void _applyTimeFilter() {
    int filteredQ = 0;
    int filteredC = 0;
    final now = DateTime.now();

    DateTime getStartDate() {
      switch (_activeTimeFilter) {
        case 'Gün':
          return DateTime(now.year, now.month, now.day);
        case 'Hafta':
          return now.subtract(Duration(days: now.weekday - 1));
        case 'Ay':
          return DateTime(now.year, now.month, 1);
        case 'Yıl':
          return DateTime(now.year, 1, 1);
        default:
          return DateTime(now.year, now.month, now.day);
      }
    }

    final startDate = getStartDate();

    for (var data in _allLogs) {
      final createdAt = data['created_at'] as Timestamp?;
      if (createdAt != null && createdAt.toDate().isAfter(startDate)) {
        int docTotal = 0;
        int correct = 0;
        if (data.containsKey('lesson_results')) {
          final lessons = data['lesson_results'] as List<dynamic>? ?? [];
          for (var lesson in lessons) {
            if (lesson is Map<String, dynamic>) {
              final lessonCorrect = (lesson['correct'] ?? 0) as int;
              final lessonWrong = (lesson['wrong'] ?? 0) as int;
              final lessonEmpty = (lesson['empty'] ?? 0) as int;
              correct += lessonCorrect;
              docTotal += lessonCorrect + lessonWrong + lessonEmpty;
            }
          }
        } else {
          correct = (data['correct_count'] ?? 0) as int;
          docTotal = correct + ((data['wrong_count'] ?? 0) as int) + ((data['empty_count'] ?? 0) as int);
        }
        filteredQ += docTotal;
        filteredC += correct;
      }
    }

    for (var data in _xrayData) {
      final hash = data.hashCode.abs();
      final simulatedDaysAgo = hash % 42;
      final simulatedDate = now.subtract(Duration(days: simulatedDaysAgo));

      if (simulatedDate.isAfter(startDate)) {
        final optik = data['optik_test_d_y_b'] as Map<String, dynamic>? ?? {};
        final manuel = data['manuel_d_y_b'] as Map<String, dynamic>? ?? {};

        final num oD = (optik['D'] ?? 0) as num;
        final num oY = (optik['Y'] ?? 0) as num;
        final num oB = (optik['B'] ?? 0) as num;

        final num mD = (manuel['D'] ?? 0) as num;
        final num mY = (manuel['Y'] ?? 0) as num;
        final num mB = (manuel['B'] ?? 0) as num;

        filteredC += (oD + mD).toInt();
        filteredQ += (oD + oY + oB + mD + mY + mB).toInt();
      }
    }

    _filteredToplamSoru = filteredQ;
    _filteredGenelBasari = filteredQ > 0 ? (filteredC / filteredQ) * 100 : 0.0;
    notifyListeners();
  }

  // --- KONU RÖNTGENİ İÇİN VERİ FİLTRELEME ---
  // Seçilen bir dersin altındaki konuları ve güvenilir başarı skorlarını döndürür
  Map<String, double> getSubjectXrayData(String selectedDers) {
    if (_xrayData.isEmpty || selectedDers.isEmpty) {
      return {};
    }

    final Map<String, double> result = {};

    for (var data in _xrayData) {
      final konuKodu = data['konu_kodu'] as String? ?? '';
      final basariSkoru = (data['guvenilir_basari_skoru'] ?? 0.0) as num;

      if (konuKodu.isNotEmpty) {
        result[konuKodu] = basariSkoru.toDouble();
      }
    }

    return result;
  }

  // --- MOMENTUM RADAR VERİSİ ---
  List<Map<String, dynamic>> getMomentumData() {
    final Map<String, Map<String, dynamic>> latestTests = {};

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    void addTestResult(String d, String k, int dogru, int yanlis, int bos, DateTime date) {
      if (d.isEmpty || k.isEmpty) return;
      final total = dogru + yanlis + bos;
      if (total > 0) {
        final basari = (dogru / total) * 100;
        final key = '${d}_$k';
        if (!latestTests.containsKey(key)) {
          latestTests[key] = {'ders': d, 'konu': k, 'date': date, 'score': basari};
        } else {
          final existingDate = latestTests[key]!['date'] as DateTime;
          if (date.isAfter(existingDate)) {
            latestTests[key]!['date'] = date;
            latestTests[key]!['score'] = basari;
          }
        }
      }
    }

    for (var log in _allLogs) {
      final createdAt = parseDate(log['created_at'] ?? log['date'] ?? log['timestamp'] ?? log['tarih']);
      if (createdAt == null) continue;

      if (log.containsKey('lesson_results')) {
        final lessons = log['lesson_results'] as List<dynamic>? ?? [];
        for (var lesson in lessons) {
          if (lesson is Map<String, dynamic>) {
            final d = lesson['ders'] as String? ?? lesson['ders_adi'] as String? ?? lesson['lesson_name'] as String? ?? '';
            final k = lesson['konu'] as String? ?? lesson['konu_adi'] as String? ?? log['konu'] as String? ?? log['konu_adi'] as String? ?? '';
            final dogru = (lesson['correct'] ?? lesson['correct_count'] ?? lesson['dogru'] ?? 0) as int;
            final yanlis = (lesson['wrong'] ?? lesson['wrong_count'] ?? lesson['yanlis'] ?? 0) as int;
            final bos = (lesson['empty'] ?? lesson['empty_count'] ?? lesson['bos'] ?? 0) as int;
            addTestResult(d, k, dogru, yanlis, bos, createdAt);
          }
        }
      } else {
        final d = log['ders'] as String? ?? log['ders_adi'] as String? ?? log['lesson'] as String? ?? '';
        final k = log['konu'] as String? ?? log['konu_adi'] as String? ?? log['topic'] as String? ?? '';
        final dogru = (log['correct_count'] ?? log['correct'] ?? log['dogru'] ?? 0) as int;
        final yanlis = (log['wrong_count'] ?? log['wrong'] ?? log['yanlis'] ?? 0) as int;
        final bos = (log['empty_count'] ?? log['empty'] ?? log['bos'] ?? 0) as int;
        addTestResult(d, k, dogru, yanlis, bos, createdAt);
      }
    }

    final momentum = <Map<String, dynamic>>[];

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

    for (var test in latestTests.values) {
      final ders = test['ders'] as String;
      final konu = test['konu'] as String;
      final recentScore = test['score'] as double;

      double baseline = 0.0;
      var foundBaseline = false;
      final searchKonu = normalize(konu);

      for (var xray in _xrayData) {
        final xKodu = normalize(xray['konu_kodu'] as String? ?? '');
        final xKonu = normalize(xray['konu'] as String? ?? '');

        if ((xKodu.isNotEmpty && searchKonu.contains(xKodu)) ||
            (xKonu.isNotEmpty && searchKonu.contains(xKonu)) ||
            (xKonu.isNotEmpty && xKonu.contains(searchKonu))) {
          baseline = ((xray['guvenilir_basari_skoru'] ?? 0.0) as num).toDouble();

          if (baseline == 0.0) {
            final optik = xray['optik_test_d_y_b'] as Map<String, dynamic>? ?? {};
            final manuel = xray['manuel_d_y_b'] as Map<String, dynamic>? ?? {};
            final tD = ((optik['D'] ?? 0) as num).toInt() + ((manuel['D'] ?? 0) as num).toInt();
            final tY = ((optik['Y'] ?? 0) as num).toInt() + ((manuel['Y'] ?? 0) as num).toInt();
            final tB = ((optik['B'] ?? 0) as num).toInt() + ((manuel['B'] ?? 0) as num).toInt();
            final tot = tD + tY + tB;
            if (tot > 0) baseline = (tD / tot) * 100;
          }

          foundBaseline = true;
          break;
        }
      }

      if (foundBaseline) {
        final diff = recentScore - baseline;
        momentum.add({
          'ders': ders,
          'konu': konu,
          'eski': baseline,
          'yeni': recentScore,
          'fark': diff,
          'durum': diff >= 0 ? 'yukseliste' : 'dususte',
        });
      }
    }

    momentum.sort((a, b) => (b['fark'] as double).abs().compareTo((a['fark'] as double).abs()));
    return momentum;
  }
}
