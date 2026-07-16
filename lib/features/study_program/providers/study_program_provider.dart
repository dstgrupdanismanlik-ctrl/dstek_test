import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_subject.dart';

class StudyProgramProvider extends ChangeNotifier {
  StudyProgramProvider() {
    _loadFromFirestore();
  }

  final List<StudySubject> _subjects = [];
  final List<StudySubject> _basketSubjects = [];
  final List<StudySubject> _activeProgramSubjects = []; 
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
  int _remainingHours = 50;
  String? _lastMessage;
  bool _isOverBudget = false;
  bool _hasActiveProgram = false;
  
  // YENİ: Program kilitlenme (Kaydedilme) durumu
  bool _isProgramSaved = false; 

  List<StudySubject> get subjects => List.unmodifiable(_subjects);
  List<StudySubject> get basketSubjects => List.unmodifiable(_basketSubjects);
  List<StudySubject> get activeProgramSubjects => List.unmodifiable(_activeProgramSubjects);
  List<String> get columnOrder => List.unmodifiable(_columnOrder);

  int get remainingHours => _remainingHours;
  int get activeDayCount => _activeDayCount;
  String? get lastMessage => _lastMessage;
  bool get isOverBudget => _isOverBudget;
  bool get hasActiveProgram => _hasActiveProgram;
  bool get isProgramSaved => _isProgramSaved; // YENİ

  int get weeklyBudgetHours => _calculateWeeklyBudgetHours(_activeDayCount);
  double get budgetProgress => (_remainingHours / weeklyBudgetHours).clamp(0.0, 1.0);

  int _calculateWeeklyBudgetHours(int activeDayCount) {
    if (activeDayCount == 6) return 50;
    if (activeDayCount == 7) return 58;
    return 50 - ((6 - activeDayCount) * 8);
  }

  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('curriculum').get();

      final List<StudySubject> loadedSubjects = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final String konuKodu = data['konu_kodu']?.toString() ?? '';
        final String konuAdi = data['konu_adi']?.toString() ?? 'İsimsiz Konu';
        final String dersAdi = data['ders_adi']?.toString() ?? 'Bilinmeyen Ders';
        final int saat = int.tryParse(data['tahmini_calisma_saati']?.toString() ?? '4') ?? 4;
        final int onerilenGun = int.tryParse(data['onerilen_gun_sayisi']?.toString().trim() ?? '1') ?? 1;
        final int sira = int.tryParse(data['program_sirasi']?.toString().trim() ?? '9999') ?? 9999;

        if (data['is_active'] == true || data['is_active'] == 'TRUE') {
          loadedSubjects.add(StudySubject(
            id: doc.id,
            name: '$konuKodu - $konuAdi',
            opticalSuccess: 0.0,
            manualSuccess: 0.0,
            estimatedStudyHours: saat,
            recommendedDays: onerilenGun,
            courseName: dersAdi,
            programOrder: sira,
            columnId: 'column-1',
          ));
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

    // BAŞ MİMAR KURALI 2: Filtrelenen listeyi kesin olarak Excel'deki "programOrder" değerine göre diz
    list.sort((a, b) => a.programOrder.compareTo(b.programOrder));

    return list;
  }

  bool addSubjectToBasket(StudySubject subject) {
    if (!_subjects.contains(subject)) return false;

    int requiredHours = subject.estimatedStudyHours;

    // BAŞ MİMAR KURALI: Mutlak Kapasite Reddi (Günde max 10 saat + 2 saat ısrar payı)
    int absoluteMaxHours = _activeDayCount * 12;
    int currentTotalHours = weeklyBudgetHours - _remainingHours;

    if ((currentTotalHours + requiredHours) > absoluteMaxHours) {
      _lastMessage = 'KAPASİTE DOLDU! Günde ortalama 12 saati aşamazsınız. Daha fazla konu eklenemez.';
      notifyListeners();
      return false; // Sistemi kilitler ve konuyu sepete atmaz
    }

    _remainingHours -= requiredHours;
    _isOverBudget = _remainingHours < 0;

    _subjects.remove(subject);
    _basketSubjects.add(subject);

    if (_isOverBudget) {
      _lastMessage = 'Haftalık bütçenizi aştınız! Bu kadar konuyu çalışmakta zorlanabilirsiniz.';
    } else {
      _lastMessage = '${subject.name} sepete eklendi.';
    }

    notifyListeners();
    return true;
  }

  void removeFromBasket(StudySubject subject) {
    _basketSubjects.remove(subject);
    _subjects.add(subject);
    _remainingHours += subject.estimatedStudyHours;
    _isOverBudget = false;
    notifyListeners();
  }

  void removeFromProgram(StudySubject item) {
    _activeProgramSubjects.remove(item);
    item.assignedDays = [];
    item.isCompleted = false;
    _subjects.add(item); 
    
    if (_activeProgramSubjects.isEmpty) {
      _hasActiveProgram = false;
    }
    _remainingHours += item.estimatedStudyHours;
    _isOverBudget = false;
    notifyListeners();
  }

  void changeSubjectDay(StudySubject item, int newDayIndex) {
    item.assignedDays = [newDayIndex];
    notifyListeners();
  }

  void distributeProgram(List<int> activeDays) {
    if (activeDays.isEmpty) return;

    // Hem eski programı hem sepettekileri birleştirip yepyeni bir dağıtım yapıyoruz
    final allToDistribute = [..._activeProgramSubjects, ..._basketSubjects];

    int dayPointer = 0;
    for (var subject in allToDistribute) {
      subject.assignedDays = [];
      int daysNeeded = subject.recommendedDays;
      if (daysNeeded > activeDays.length) daysNeeded = activeDays.length;
      if (daysNeeded < 1) daysNeeded = 1;

      for (int i = 0; i < daysNeeded; i++) {
        subject.assignedDays.add(activeDays[(dayPointer + i) % activeDays.length]);
      }
      dayPointer = (dayPointer + daysNeeded) % activeDays.length;
    }

    _activeProgramSubjects.clear();
    _activeProgramSubjects.addAll(allToDistribute);
    _basketSubjects.clear();

    _hasActiveProgram = true;
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
    _remainingHours = _calculateWeeklyBudgetHours(_activeDayCount);
    _isOverBudget = false;
    notifyListeners();
  }
}