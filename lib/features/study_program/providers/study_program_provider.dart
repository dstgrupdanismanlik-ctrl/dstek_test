import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_subject.dart';

class PrerequisiteStatus {
  const PrerequisiteStatus({required this.missingPrerequisites});

  final List<StudySubject> missingPrerequisites;

  bool get hasBlockingPrerequisites => missingPrerequisites.isNotEmpty;
}

class StudyProgramProvider extends ChangeNotifier {
  StudyProgramProvider() {
    _loadFromFirestore();
  }

  final List<StudySubject> _subjects = [];
  final List<StudySubject> _basketSubjects = [];
  final List<StudySubject> _activeProgramSubjects = []; 
  final List<String> teacherSupportList = [];
  final List<String> notificationMessages = [];
  final Map<String, StudySubject> _subjectsByCode = {};
  final Map<String, String> _subjectCodeById = {};
  final Map<String, List<String>> _prerequisiteCodesBySubjectCode = {};
  final Map<String, double> _xrayScoresByCode = {};
  // Sadece ön koşul olarak eklenen konuların ID'lerini tutar (Ana konu ayrıcalığı için)
  final Set<String> _prerequisiteOnlyIds = {};
  List<bool> holidayPreferences = [false, false, false, false, false, false, true];

  final List<String> _columnOrder = [
    'column-1',
    'column-2',
    'column-3',
    'column-4',
    'column-5',
  ];

  final Map<String, String?> _columnFilters = {
    'column-1': null,
    'column-2': null,
    'column-3': null,
    'column-4': null,
    'column-5': null,
  };

  int _activeDayCount = 6;
  double _remainingHours = 50.0;
  String? _lastMessage;
  bool _isOverBudget = false;
  bool _hasActiveProgram = false;
  
  // YENİ: Program kilitlenme (Kaydedilme) durumu
  bool _isProgramSaved = false; 

  List<StudySubject> get subjects => List.unmodifiable(_subjects);
  List<StudySubject> get basketSubjects => List.unmodifiable(_basketSubjects);
  List<StudySubject> get activeProgramSubjects => List.unmodifiable(_activeProgramSubjects);
  List<StudySubject> get allSubjects {
    final byId = <String, StudySubject>{};
    for (final subject in [..._subjects, ..._basketSubjects, ..._activeProgramSubjects]) {
      byId[subject.id] = subject;
    }
    return byId.values.toList();
  }
  List<String> get columnOrder => List.unmodifiable(_columnOrder);

  double get remainingHours => _remainingHours;
  int get activeDayCount => _activeDayCount;
  String? get lastMessage => _lastMessage;
  bool get isOverBudget {
    final activeDays = holidayPreferences.where((isHoliday) => !isHoliday).length;
    final maxCapacity = (activeDays * 8.0) + 2.0;
    final totalEffectiveHours = _calculateEffectiveHoursFor([
      ..._basketSubjects,
      ..._activeProgramSubjects,
    ]);
    return totalEffectiveHours > maxCapacity;
  }
  bool get hasActiveProgram => _hasActiveProgram;
  bool get isProgramSaved => _isProgramSaved; // YENİ

  double get weeklyBudgetHours => _calculateWeeklyBudgetHours(_activeDayCount);
  double get budgetProgress => (_remainingHours / weeklyBudgetHours).clamp(0.0, 1.0);

  double _calculateWeeklyBudgetHours(int activeDayCount) {
    if (activeDayCount == 6) return 50.0;
    if (activeDayCount == 7) return 58.0;
    return (50 - ((6 - activeDayCount) * 8)).toDouble();
  }

  List<String> _parsePrerequisiteCodes(dynamic rawValue) {
    final codes = rawValue is List
        ? rawValue.map((item) => item.toString()).join(',')
        : rawValue?.toString();

    if (codes == null || codes.trim().isEmpty) {
      return const [];
    }

    final rawCodes = <String>[];
    final regExp = RegExp(r'\b[TA]_[A-ZÇĞİÖŞÜ]+_\d+\b');

    for (final part in codes.split(',')) {
      final match = regExp.firstMatch(part);
      if (match != null) {
        rawCodes.add(match.group(0)!);
      }
    }

    return rawCodes;
  }

  List<String> _extractPrerequisiteCodesFromText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const [];
    }

    final regExp = RegExp(r'\b[TA]_[A-ZÇĞİÖŞÜ]+_\d+\b');
    return regExp
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  Iterable<StudySubject> get _allKnownSubjects sync* {
    final seenIds = <String>{};
    for (final subject in [..._subjects, ..._basketSubjects, ..._activeProgramSubjects]) {
      if (seenIds.add(subject.id)) {
        yield subject;
      }
    }
  }

  bool _isQueuedOrActive(StudySubject subject) {
    return _basketSubjects.contains(subject) || _activeProgramSubjects.contains(subject);
  }

  double _calculateEffectiveHoursFor(Iterable<StudySubject> subjects) {
    return subjects.fold<double>(
      0.0,
      (sum, subject) => sum + getEffectiveDuration(subject, subject.columnId),
    );
  }

  bool _addSubjectsToBasketInternal(List<StudySubject> subjectsToAdd) {
    final availableSubjects = subjectsToAdd.where((subject) => _subjects.contains(subject)).toList();
    if (availableSubjects.isEmpty) {
      return false;
    }

    final requiredHours = _calculateEffectiveHoursFor(availableSubjects);
    final absoluteMaxHours = (_activeDayCount * 12).toDouble();
    final currentTotalHours = weeklyBudgetHours - _remainingHours;

    if ((currentTotalHours + requiredHours) > absoluteMaxHours) {
      _lastMessage = 'KAPASİTE DOLDU! Günde ortalama 12 saati aşamazsınız. Daha fazla konu eklenemez.';
      notifyListeners();
      return false;
    }

    _remainingHours -= requiredHours;
    _isOverBudget = _remainingHours < 0;

    final insertIndex = _basketSubjects.length;
    for (var i = 0; i < availableSubjects.length; i++) {
      final subject = availableSubjects[i];
      _subjects.remove(subject);
      _basketSubjects.insert(insertIndex + i, subject);
    }

    if (_isOverBudget) {
      _lastMessage = 'Haftalık bütçenizi aştınız! Bu kadar konuyu çalışmakta zorlanabilirsiniz.';
    } else if (availableSubjects.length == 1) {
      _lastMessage = '${availableSubjects.first.name} sepete eklendi.';
    } else {
      _lastMessage = '${availableSubjects.length} konu sepete eklendi.';
    }

    notifyListeners();
    return true;
  }

  double getEffectiveDuration(StudySubject subject, String sourceColumnId) {
    if (sourceColumnId == 'column-1') {
      return subject.estimatedStudyHours.toDouble();
    }

    if (sourceColumnId == 'column-2' || sourceColumnId == 'column-3') {
      return subject.repeatStudyHours;
    }

    if (sourceColumnId == 'column-4' || sourceColumnId == 'column-5') {
      return subject.questionSolveHours;
    }

    return subject.estimatedStudyHours.toDouble();
  }

  String _columnIdForScore(double score) {
    if (!score.isFinite || score <= 0) {
      return 'column-1';
    }
    if (score < 70) {
      return 'column-2';
    }
    if (score < 80) {
      return 'column-3';
    }
    if (score < 90) {
      return 'column-4';
    }
    return 'column-5';
  }

  Future<void> _loadFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('curriculum').get();
      final xraySnapshot = await firestore
          .collection('student_subjects_xray')
          .get();

      _xrayScoresByCode.clear();
      _prerequisiteCodesBySubjectCode.clear();
      for (final doc in xraySnapshot.docs) {
        final xrayData = doc.data();
        final konuKodu = xrayData['konu_kodu']?.toString().trim() ?? '';
        if (konuKodu.isEmpty) {
          continue;
        }

        final rawScore = xrayData['guvenilir_basari_skoru'];
        final parsedScore = rawScore is num
            ? rawScore.toDouble()
            : double.tryParse(rawScore?.toString() ?? '') ?? 0.0;
        _xrayScoresByCode[konuKodu] = parsedScore.isFinite ? parsedScore : 0.0;
        _prerequisiteCodesBySubjectCode[konuKodu] = {
          ..._parsePrerequisiteCodes(xrayData['ders_ici_on_kosul']),
          ..._parsePrerequisiteCodes(xrayData['ders_disi_on_kosul']),
        }.toList();
      }

      final List<StudySubject> loadedSubjects = [];
      _subjectsByCode.clear();
      _subjectCodeById.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final String konuKodu = data['konu_kodu']?.toString() ?? '';
        final String konuAdi = data['konu_adi']?.toString() ?? 'İsimsiz Konu';
        final String dersAdi = data['ders_adi']?.toString() ?? 'Bilinmeyen Ders';
        final int saat = int.tryParse(data['tahmini_calisma_saati']?.toString() ?? '4') ?? 4;
        final double tekrarCalismaSaati = data['tekrar_calisma_saati'] is num
          ? (data['tekrar_calisma_saati'] as num).toDouble()
          : double.tryParse(data['tekrar_calisma_saati']?.toString() ?? '') ??
              saat.toDouble();
        final double soruCozmeSaati = data['soru_cozme_saati'] is num
          ? (data['soru_cozme_saati'] as num).toDouble()
          : double.tryParse(data['soru_cozme_saati']?.toString() ?? '') ??
              saat.toDouble();
        final int onerilenGun = int.tryParse(data['onerilen_gun_sayisi']?.toString().trim() ?? '1') ?? 1;
        final int sira = int.tryParse(data['program_sirasi']?.toString().trim() ?? '9999') ?? 9999;
        final double konuSkoru = _xrayScoresByCode[konuKodu] ?? 0.0;

        if (data['is_active'] == true || data['is_active'] == 'TRUE') {
          final subject = StudySubject(
            id: doc.id,
            name: '$konuKodu - $konuAdi',
            opticalSuccess: konuSkoru,
            manualSuccess: konuSkoru,
            estimatedStudyHours: saat,
            repeatStudyHours: tekrarCalismaSaati,
            questionSolveHours: soruCozmeSaati,
            inCoursePrerequisite: data['ders_ici_on_kosul']?.toString(),
            outOfCoursePrerequisite: data['ders_disi_on_kosul']?.toString(),
            recommendedDays: onerilenGun,
            courseName: dersAdi,
            programOrder: sira,
            columnId: _columnIdForScore(konuSkoru),
          );
          loadedSubjects.add(subject);
          if (konuKodu.trim().isNotEmpty) {
            _subjectsByCode[konuKodu.trim()] = subject;
            _subjectCodeById[subject.id] = konuKodu.trim();
          }
        }
      }

      loadedSubjects.sort((a, b) => a.programOrder.compareTo(b.programOrder));

      _subjects.clear();
      _subjects.addAll(loadedSubjects);
      notifyListeners();

    } catch (e) {
      debugPrint('Firestore çekme hatası: $e');
      _lastMessage = 'Veritabanına bağlanılamadı. İnternet bağlantınızı kontrol edin.';
      notifyListeners();
    }
  }

  String? getColumnFilter(String columnId) => _columnFilters[columnId];

  List<String> get sortedCourseNames {
    final List<String> orderedList = [];
    // _subjects listesi Firestore'dan çekilirken zaten 'program_sirasi' ile dizildi!
    for (var s in _subjects) {
      final cName = s.courseName.trim();
      if (cName.isNotEmpty && !orderedList.contains(cName)) {
        orderedList.add(cName); // Dizilmiş listede gördüğün ilk yeni dersi ekle
      }
    }
    return orderedList;
  }

  List<String> getCourseNamesForColumn(String columnId) {
    final courses = _subjects
        .where((subject) => subject.columnId == columnId)
        .map((subject) => subject.courseName)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    courses.sort();
    return courses;
  }

  void setColumnFilter(String columnId, String? courseName) {
    _columnFilters[columnId] = courseName;
    notifyListeners();
  }

  List<StudySubject> getSubjectsForColumn(String columnId) {
    var list = _subjects.where((subject) => subject.columnId == columnId).toList();

    // BAŞ MİMAR KURALI 1: Dropdown'dan seçilen dersi UYGULA (Filtrele)
    final filter = _columnFilters[columnId];
    if (filter != null && filter.isNotEmpty && filter != "Tüm Dersler") {
      list = list.where((s) => s.courseName.trim() == filter).toList();
    }

    list.sort((a, b) {
      bool aIsTyt = a.name.startsWith('T_');
      bool bIsTyt = b.name.startsWith('T_');
      if (aIsTyt && !bIsTyt) return -1;
      if (!aIsTyt && bIsTyt) return 1;
      return a.programOrder.compareTo(b.programOrder);
    });

    return list;
  }

  List<StudySubject> getMissingPrerequisites(StudySubject subject) {
    if (subject.inCoursePrerequisite == null ||
        subject.inCoursePrerequisite!.trim().isEmpty) {
      return const <StudySubject>[];
    }

    final rawCodes = _extractPrerequisiteCodesFromText(
      subject.inCoursePrerequisite,
    );

    final missingPrerequisites = <StudySubject>[];
    final seenIds = <String>{};
    final allSubjects = _allKnownSubjects.toList();

    for (final rawCode in rawCodes) {
      final preSubject = allSubjects.firstWhere(
        (s) => RegExp('^${RegExp.escape(rawCode)}\\b').hasMatch(s.name),
        orElse: () => _subjectsByCode[rawCode] ?? subject,
      );

      if (identical(preSubject, subject)) {
        continue;
      }

      final prerequisiteScore = _xrayScoresByCode[rawCode] ?? preSubject.safeScore;
      if (prerequisiteScore < 70 && seenIds.add(preSubject.id)) {
        missingPrerequisites.add(preSubject);
      }
    }

    missingPrerequisites.sort((a, b) => a.programOrder.compareTo(b.programOrder));
    return missingPrerequisites;
  }

  PrerequisiteStatus analyzePrerequisites(StudySubject subject) {
    return PrerequisiteStatus(
      missingPrerequisites: getMissingPrerequisites(subject),
    );
  }

  bool addSubjectToBasket(StudySubject subject) {
    final trueSubject = _subjects.cast<StudySubject?>().firstWhere(
      (s) => s?.id == subject.id,
      orElse: () => null,
    );

    if (trueSubject == null) {
      if (_basketSubjects.any((s) => s.id == subject.id) ||
          _activeProgramSubjects.any((s) => s.id == subject.id)) {
        _prerequisiteOnlyIds.remove(subject.id);
        notifyListeners();
      }
      return false;
    }

    _prerequisiteOnlyIds.remove(trueSubject.id);
    return _addSubjectsToBasketInternal([trueSubject]);
  }

  // TODO: Bu veri ileride system_constants'tan veya öğrenci profilinden çekilecek. Şimdilik test için 150 gün veriyoruz.
  int get daysUntilExam => 150;

  int getCompletedSubjectCountInProgram() {
    int basketCount = _basketSubjects.where((s) => s.columnId == 'column-5').length;
    int programCount = _activeProgramSubjects.where((s) => s.columnId == 'column-5').length;
    return basketCount + programCount;
  }

  void sendToTeacher(StudySubject subject) {
    if (!teacherSupportList.contains(subject.name)) {
      _subjects.remove(subject);
      teacherSupportList.add(subject.name);
      notificationMessages.add(
        '📌 ${subject.name} konusu için öğretmenden destek almalısın!',
      );
      notifyListeners();
    }
  }

  bool addSubjectToBasketWithPrerequisites(
    StudySubject subject,
    List<StudySubject> selectedPrerequisites,
  ) {
    _prerequisiteOnlyIds.remove(subject.id);

    final prerequisitesToAdd = <StudySubject>[];

    for (var pre in selectedPrerequisites) {
      if (pre.id == subject.id) continue;

      if (_basketSubjects.any((s) => s.id == pre.id) ||
          _activeProgramSubjects.any((s) => s.id == pre.id)) {
        continue;
      }

      final truePre = _subjects.cast<StudySubject?>().firstWhere(
        (s) => s?.id == pre.id,
        orElse: () => null,
      );
      if (truePre != null) {
        prerequisitesToAdd.add(truePre);
        _prerequisiteOnlyIds.add(truePre.id);
      }
    }

    final warningMsg = '📌 Ön koşul zinciri takvime sığmıyor. 2. sıradaki konuyu sonraki haftaya bırakabilir veya takvimden ilk konunun gün sayısını manuel azaltarak yer açabilirsin.';
    prerequisitesToAdd.sort((a, b) => a.programOrder.compareTo(b.programOrder));

    final trueSubject = _subjects.cast<StudySubject?>().firstWhere(
      (s) => s?.id == subject.id,
      orElse: () => null,
    );

    if (trueSubject == null) {
      if (prerequisitesToAdd.isEmpty) return false;
      return _addSubjectsToBasketInternal(prerequisitesToAdd);
    }

    return _addSubjectsToBasketInternal([
      ...prerequisitesToAdd,
      trueSubject,
    ]);
  }

  StudySubject? findSubjectByCode(String code) {
    for (final subject in _allKnownSubjects) {
      if (subject.name.startsWith('$code ' ) || subject.name.startsWith('$code-')) {
        return subject;
      }
    }
    return _subjectsByCode[code.trim()];
  }

  void removeFromBasket(StudySubject subject) {
    _basketSubjects.remove(subject);
    _prerequisiteOnlyIds.remove(subject.id);
    _subjects.add(subject);
    _remainingHours += getEffectiveDuration(subject, subject.columnId);
    _isOverBudget = false;
    notifyListeners();
  }

  void removeFromProgram(StudySubject item) {
    _activeProgramSubjects.remove(item);
    _prerequisiteOnlyIds.remove(item.id);
    final resetItem = item.copyWith(completedDays: const []);
    resetItem.assignedDays = [];
    _subjects.add(resetItem); 
    
    if (_activeProgramSubjects.isEmpty) {
      _hasActiveProgram = false;
    }
    _remainingHours += getEffectiveDuration(item, item.columnId);
    _isOverBudget = false;
    notifyListeners();
  }

  void changeSubjectDay(StudySubject item, int newDayIndex) {
    item.assignedDays = [newDayIndex];
    notifyListeners();
  }

  // 1. Sadece İlgili Günü Silme (Multi-Day Delete)
  void removeSubjectFromDay(StudySubject subject, int dayIndex) {
    final index = _activeProgramSubjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      final updatedDays = List<int>.from(_activeProgramSubjects[index].assignedDays);
      updatedDays.remove(dayIndex);

      if (updatedDays.isEmpty) {
        removeFromProgram(subject);
      } else {
        _activeProgramSubjects[index].assignedDays = updatedDays;
        final double partialHour = getEffectiveDuration(subject, subject.columnId) / subject.recommendedDays;
        _remainingHours += partialHour;
        _isOverBudget = _remainingHours < 0;
        notifyListeners();
      }
    }
  }

  // 2. Konunun İlgili Gününü Taşıma (Drag & Drop Move)
  void moveSubjectDay(StudySubject subject, int oldDayIndex, int newDayIndex) {
    final index = _activeProgramSubjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      final updatedDays = List<int>.from(_activeProgramSubjects[index].assignedDays);
      updatedDays.remove(oldDayIndex);
      if (!updatedDays.contains(newDayIndex)) {
        updatedDays.add(newDayIndex);
        updatedDays.sort();
      }
      _activeProgramSubjects[index].assignedDays = updatedDays;
      notifyListeners();
    }
  }

  // BAŞ MİMAR KURALI: Taşıma işleminde ön koşul çakışmasını tespit et
  StudySubject? getConflictingPrerequisiteForMove(StudySubject subject, int newDayIndex) {
    final prereqCodes = [
      ..._extractPrerequisiteCodesFromText(subject.inCoursePrerequisite),
      ..._extractPrerequisiteCodesFromText(subject.outOfCoursePrerequisite)
    ];

    for (var p in _activeProgramSubjects) {
      if (prereqCodes.any((code) => p.name.startsWith('$code ') || p.name.startsWith('$code-'))) {
        if (p.assignedDays.isNotEmpty) {
          // Eğer ön koşulun son çalışıldığı gün, yeni taşınmak istenen günden BÜYÜK veya EŞİTSE pedagojik çakışma vardır.
          int pLastDay = p.assignedDays.last;
          if (pLastDay >= newDayIndex) {
            return p;
          }
        }
      }
    }
    return null;
  }

  void toggleSubjectCompletion(StudySubject subject, int dayIndex) {
    final index = _activeProgramSubjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      final updatedCompletedDays = List<int>.from(
        _activeProgramSubjects[index].completedDays,
      );
      if (updatedCompletedDays.contains(dayIndex)) {
        updatedCompletedDays.remove(dayIndex);
      } else {
        updatedCompletedDays.add(dayIndex);
      }

      _activeProgramSubjects[index] = _activeProgramSubjects[index].copyWith(
        completedDays: updatedCompletedDays,
      );
      notifyListeners();
    }
  }

  void distributeProgram(List<int> activeDays) {
    if (activeDays.isEmpty) return;

    final allToDistribute = [..._activeProgramSubjects, ..._basketSubjects];
    // Program sırasına göre pedagojik dizilim
    allToDistribute.sort((a, b) => a.programOrder.compareTo(b.programOrder));

    List<StudySubject> distributed = [];
    List<StudySubject> leftInBasket = [];
    
    // Her aktif günün üzerindeki saat yükünü takip eden hafıza
    List<double> dailyHours = List.filled(activeDays.length, 0.0);

    for (var subject in allToDistribute) {
      subject.assignedDays = [];
      
      double originalDuration = subject.estimatedStudyHours.toDouble();
      double effectiveDuration = getEffectiveDuration(subject, subject.columnId);
      int originalDays = subject.recommendedDays;
      int daysNeeded = originalDays;

      // Evrensel Amortisman Kuralı
      if (effectiveDuration < originalDuration && originalDuration > 0) {
        double ratio = effectiveDuration / originalDuration;
        daysNeeded = (originalDays * ratio).round();
      }
      if (daysNeeded < 1) daysNeeded = 1;

      int earliestAllowedDay = 0;

      // 1. BAŞ MİMAR KURALI: Ön Koşul Kontrolü (Zincirleme)
      final prereqCodes = [
        ..._extractPrerequisiteCodesFromText(subject.inCoursePrerequisite),
        ..._extractPrerequisiteCodesFromText(subject.outOfCoursePrerequisite)
      ];
      
      for (var d in distributed) {
        if (prereqCodes.any((code) => d.name.startsWith('$code ') || d.name.startsWith('$code-'))) {
          if (d.assignedDays.isNotEmpty) {
            int lastAssignedIndex = activeDays.indexOf(d.assignedDays.last);
            if (lastAssignedIndex + 1 > earliestAllowedDay) {
              earliestAllowedDay = lastAssignedIndex + 1;
            }
          }
        }
      }

      // 2. BAŞ MİMAR KURALI: Dengeli Dağıtım (Min-Load Algorithm)
      // Konuyu takvimdeki "en az yükü olan" uygun günlere yerleştir ki yığılma olmasın
      int bestStartDay = -1;
      double minMaxLoad = 9999.0;
      double dailyLoad = effectiveDuration / daysNeeded;

      for (int start = earliestAllowedDay; start <= activeDays.length - daysNeeded; start++) {
        double currentMaxLoad = 0.0;
        for (int i = 0; i < daysNeeded; i++) {
          double load = dailyHours[start + i] + dailyLoad;
          if (load > currentMaxLoad) currentMaxLoad = load;
        }
        // Eğer bu gün aralığı 12 saatlik mutlak sınırı aşmıyorsa ve şu ana kadarki en boş yerse
        if (currentMaxLoad <= 12.0 && currentMaxLoad < minMaxLoad) {
          minMaxLoad = currentMaxLoad;
          bestStartDay = start;
        }
      }

      // 3. BAŞ MİMAR KURALI: Takvime sığıyor mu? (Haftalık sınır kontrolü)
      if (bestStartDay != -1) {
        for (int i = 0; i < daysNeeded; i++) {
          int dayToAssign = bestStartDay + i;
          subject.assignedDays.add(activeDays[dayToAssign]);
          dailyHours[dayToAssign] += dailyLoad; // O günün yükünü artır
        }
        distributed.add(subject);
      } else {
        leftInBasket.add(subject); // Sığmadıysa haftaya bırak (Sepet)
      }
    }

    _activeProgramSubjects.clear();
    _activeProgramSubjects.addAll(distributed);
    _basketSubjects.clear();
    _basketSubjects.addAll(leftInBasket);

    _hasActiveProgram = _activeProgramSubjects.isNotEmpty;
    
    // Eski taşma uyarılarını temizle
    notificationMessages.removeWhere((msg) => msg.contains('Takvim doldu') || msg.contains('sığmayan'));
    
    if (leftInBasket.isNotEmpty) {
      final String overflowNames = leftInBasket.map((s) => s.name.split('-').last.trim()).join(', ');
      notificationMessages.add('📌 Takvim doldu! Günlük kapasiteye veya ön koşul sırasına sığmayan şu konular sonraki haftaya (sepete) bırakıldı: $overflowNames');
    } else {
      _lastMessage = 'Program başarıyla günlere dağıtıldı.';
    }
    
    notifyListeners();
  }

  // YENİ: Programı Kalıcı Olarak Kaydetme
  void saveProgram() {
    _isProgramSaved = true;
    _lastMessage = 'Program başarıyla kaydedildi!';
    notifyListeners();
  }

  void setActiveDayCount(int value) {
    _activeDayCount = value.clamp(4, 7);
    final double usedHours = _calculateEffectiveHoursFor([..._basketSubjects, ..._activeProgramSubjects]);
    _remainingHours = _calculateWeeklyBudgetHours(_activeDayCount) - usedHours;
    _isOverBudget = _remainingHours < 0;
    notifyListeners();
  }
}