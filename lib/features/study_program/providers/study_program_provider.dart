import 'package:flutter/material.dart';
import '../models/study_subject.dart';

class StudyProgramProvider extends ChangeNotifier {
  StudyProgramProvider() {
    _seedMockSubjects();
  }

  final List<StudySubject> _subjects = [];
  final List<StudySubject> _basketSubjects = [];
  final List<StudySubject> _activeProgramSubjects = []; 

  final List<String> _columnOrder = [
    'column-1',
    'column-2',
    'column-3',
    'column-4',
    'column-5',
  ];

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

  void _seedMockSubjects() {
    final data = [
      StudySubject(id: '1', name: 'T-TR-1-Sözcükte Anlam', opticalSuccess: 94, manualSuccess: 70, estimatedStudyHours: 4, lastTestScore: 95, columnId: 'column-5'),
      StudySubject(id: '2', name: 'T-TR-3-Paragraf', opticalSuccess: 92, manualSuccess: 74, estimatedStudyHours: 4, lastTestScore: 94, columnId: 'column-5'),
      StudySubject(id: '3', name: 'T-M-3-Temel Kavramlar', opticalSuccess: 87, manualSuccess: 72, estimatedStudyHours: 4, lastTestScore: 88, columnId: 'column-4'),
      StudySubject(id: '4', name: 'T-M-7-Rasyonel Sayılar', opticalSuccess: 86, manualSuccess: 71, estimatedStudyHours: 4, lastTestScore: 84, columnId: 'column-4'),
      StudySubject(id: '5', name: 'A-Fİ-6-Enerji ve Hareket', opticalSuccess: 79, manualSuccess: 68, estimatedStudyHours: 4, lastTestScore: 77, columnId: 'column-3'),
      StudySubject(id: '6', name: 'A-M-16-İntegral', opticalSuccess: 79, manualSuccess: 67, estimatedStudyHours: 4, lastTestScore: 76, columnId: 'column-3'),
      StudySubject(id: '7', name: 'A-M-3-Eşitsizlikler', opticalSuccess: 68, manualSuccess: 64, estimatedStudyHours: 4, lastTestScore: 69, columnId: 'column-2'),
      StudySubject(id: '8', name: 'A-TR-15-Tiyatro', opticalSuccess: 61, manualSuccess: 60, estimatedStudyHours: 4, lastTestScore: 62, columnId: 'column-2'),
      StudySubject(id: '9', name: 'A-K-10-Kimyasal Tepkimelerde Denge', opticalSuccess: 0, manualSuccess: 0, estimatedStudyHours: 4, lastTestScore: 0, columnId: 'column-1'),
      StudySubject(id: '10', name: 'A-B-11-Popülasyon Ekolojisi', opticalSuccess: 0, manualSuccess: 0, estimatedStudyHours: 4, lastTestScore: 0, columnId: 'column-1'),
    ];
    _subjects.addAll(data);
    notifyListeners();
  }

  List<StudySubject> getSubjectsForColumn(String columnId) {
    return _subjects.where((subject) => subject.columnId == columnId).toList();
  }

  bool addSubjectToBasket(StudySubject subject) {
    if (!_subjects.contains(subject)) return false;
    int requiredHours = subject.estimatedStudyHours;
    if (_remainingHours < requiredHours) {
      _isOverBudget = true;
      notifyListeners();
      return false;
    }
    _remainingHours -= requiredHours;
    _isOverBudget = false;
    _subjects.remove(subject);
    _basketSubjects.add(subject);
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
    item.assignedDayIndex = null;
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
    item.assignedDayIndex = newDayIndex;
    notifyListeners();
  }

  void distributeProgram(List<int> activeDays) {
    _activeProgramSubjects.addAll(_basketSubjects);
    _basketSubjects.clear();

    int dayPointer = 0;
    for (var item in _activeProgramSubjects) {
      if (item.assignedDayIndex == null) { 
         item.assignedDayIndex = activeDays[dayPointer % activeDays.length];
         dayPointer++;
      }
    }
    _hasActiveProgram = true;
    _isProgramSaved = false; // YENİ: Dağıtım yapılınca "Taslak/Düzenleme" moduna geçer
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