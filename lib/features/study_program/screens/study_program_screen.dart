import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dstek/features/study_program/models/study_subject.dart';
import 'package:dstek/features/study_program/providers/study_program_provider.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

class _PrerequisiteDialogResult {
  const _PrerequisiteDialogResult({
    this.addOnlyMainSubject = false,
    this.selectedPrerequisites = const <StudySubject>[],
  });

  final bool addOnlyMainSubject;
  final List<StudySubject> selectedPrerequisites;
}

enum _PrerequisiteLockMode {
  unstudiedInfo,
  hardLock,
  softLock,
  none,
}

class StudyProgramScreen extends StatefulWidget {
  const StudyProgramScreen({super.key});

  @override
  State<StudyProgramScreen> createState() => _StudyProgramScreenState();
}

class _StudyProgramScreenState extends State<StudyProgramScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _kanbanScrollController = ScrollController();
  final ScrollController _weeklyScrollController = ScrollController();
  final Map<String, ScrollController> _columnScrollControllers = {};
  
  // YENİ: Uçan pencereleri devreden çıkardık, standart TextField kontrolcüsü ve metin tutucu ekledik.
  final TextEditingController _inlineSearchController = TextEditingController();
  String _searchQuery = '';
  
  DateTime currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  bool isWeeklyView = true;
  int selectedDayIndex = DateTime.now().weekday - 1;

  final List<String> weekDaysTr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final List<String> monthsTr = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  final Map<String, Map<String, dynamic>> columnConfigs = {
    'column-1': {'title': 'Hiç Çalışılmamış', 'color': Colors.grey},
    'column-2': {'title': 'Destek Al', 'color': Colors.orange},
    'column-3': {'title': 'Tekrar Et', 'color': Colors.blue},
    'column-4': {'title': 'Soru Çöz', 'color': Colors.green},
    'column-5': {'title': 'Tamamlandı', 'color': Colors.purple},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kanbanScrollController.dispose();
    _weeklyScrollController.dispose();
    _inlineSearchController.dispose(); // Yeni arama motorunun hafızasını temizle
    for (final controller in _columnScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _getColumnScrollController(String columnId) {
    return _columnScrollControllers.putIfAbsent(columnId, () => ScrollController());
  }

  String _formatDate(DateTime date) => '${date.day} ${monthsTr[date.month]}';

  void _changeWeek(int delta) {
    setState(() {
      currentWeekStart = currentWeekStart.add(Duration(days: delta * 7));
    });
  }

  void _showHolidaySelectionDialog(BuildContext context, StudyProgramProvider provider) {
    List<bool> selectedHolidays = List.from(provider.holidayPreferences);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tatil Günlerini Seçin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (index) {
                    return CheckboxListTile(
                      title: Text(weekDaysTr[index]),
                      value: selectedHolidays[index],
                      onChanged: (val) {
                        setDialogState(() => selectedHolidays[index] = val ?? false);
                      },
                    );
                  }),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    final activeDays = <int>[];
                    for (int i = 0; i < selectedHolidays.length; i++) {
                      if (!selectedHolidays[i]) activeDays.add(i);
                    }

                    final basketHours = provider.basketSubjects.fold<int>(
                      0,
                      (sum, item) =>
                          sum +
                          provider
                              .getEffectiveDuration(item, item.columnId)
                              .round(),
                    );
                    final programHours = provider.activeProgramSubjects.fold<int>(
                      0,
                      (sum, item) =>
                          sum +
                          provider
                              .getEffectiveDuration(item, item.columnId)
                              .round(),
                    );
                    final totalScheduledHours = basketHours + programHours;

                    final absoluteMax = activeDays.length * 12;

                    if (totalScheduledHours > absoluteMax) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⛔ KAPASİTE AŞIMI! ${activeDays.length} aktif gün için mutlak sınır $absoluteMax saattir. Sepetinizde $totalScheduledHours saatlik yük var. Lütfen tatil günlerini azaltın veya sepeti hafifletin.'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      return; // Dağıtımı iptal eder, ekranda kalır
                    }

                    // Tercihleri hafızaya kaydet
                    provider.holidayPreferences = List.from(selectedHolidays);

                    Navigator.of(dialogContext).pop();
                    provider.setActiveDayCount(activeDays.length);
                    provider.distributeProgram(activeDays);
                    _tabController.animateTo(1);
                  },
                  child: const Text('Dağıt'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return hours.toStringAsFixed(0);
    }
    return hours.toStringAsFixed(1);
  }

  String _resolveTaskTagLabel(String columnId) {
    switch (columnId) {
      case 'column-1':
        return 'Konu Çalış';
      case 'column-2':
      case 'column-3':
        return 'Tekrar Et / Destek';
      case 'column-4':
      case 'column-5':
        return 'Soru Çöz';
      default:
        return 'Görev';
    }
  }

  Color _resolveTaskTagBackgroundColor(String columnId) {
    switch (columnId) {
      case 'column-1':
        return Colors.blue.shade50;
      case 'column-2':
      case 'column-3':
        return Colors.orange.shade50;
      case 'column-4':
      case 'column-5':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _resolveTaskTagBorderColor(String columnId) {
    switch (columnId) {
      case 'column-1':
        return Colors.blue.shade200;
      case 'column-2':
      case 'column-3':
        return Colors.orange.shade200;
      case 'column-4':
      case 'column-5':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _resolveTaskTagTextColor(String columnId) {
    switch (columnId) {
      case 'column-1':
        return Colors.blue.shade800;
      case 'column-2':
      case 'column-3':
        return Colors.orange.shade900;
      case 'column-4':
      case 'column-5':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  List<StudySubject> _kanbanTopics(StudyProgramProvider provider) {
    return provider.subjects
        .where((subject) => provider.columnOrder.contains(subject.columnId))
        .toList();
  }

  Widget _buildTaskTagChip(String columnId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _resolveTaskTagBackgroundColor(columnId),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _resolveTaskTagBorderColor(columnId)),
      ),
      child: Text(
        _resolveTaskTagLabel(columnId),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _resolveTaskTagTextColor(columnId),
        ),
      ),
    );
  }

  Widget _buildSmartTopicSearch(BuildContext context, StudyProgramProvider provider) {
    final kanbanTopics = _kanbanTopics(provider);
    final matches = _searchQuery.isEmpty 
        ? <StudySubject>[] 
        : kanbanTopics.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inlineSearchController,
            decoration: InputDecoration(
              hintText: 'Müfredatta Konu Ara (Örn: Logaritma)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _inlineSearchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          if (matches.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: matches.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final subject = matches[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1,
                    child: ListTile(
                      title: Text(subject.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Sepete At'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _inlineSearchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          FocusScope.of(context).unfocus();
                          _handleAddToBasket(subject, subject.columnId);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  _PrerequisiteLockMode _resolvePrerequisiteLockMode(StudySubject subject) {
    final score = subject.safeScore;
    if (score <= 0) {
      return _PrerequisiteLockMode.unstudiedInfo;
    }
    if (score < 80) {
      return _PrerequisiteLockMode.hardLock;
    }
    if (score < 90) {
      return _PrerequisiteLockMode.softLock;
    }
    return _PrerequisiteLockMode.none;
  }

  Future<void> _handleAddToBasket(
    StudySubject subject,
    String sourceColumnId,
  ) async {
    final provider = context.read<StudyProgramProvider>();
    
    // 🚨 HATA BURADAYDI! copyWith yeni bir referans (klon) üretiyordu.
    // Provider arka planda bu klon konuyu listelerinde bulamadığı için
    // hiçbir hata fırlatmadan (sessizce) işlemi iptal ediyordu!
    // ÇÖZÜM: Doğrudan orijinal referansı (subject) kullanıyoruz.
    final item = subject;

    if (item.columnId == 'column-2' && item.placementCount >= 3) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            '👨‍🏫 Öğretmen Desteği',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${item.name} konusunu daha önce çok kez programa aldın. Verim için öğretmenden destek alman önerilir.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.sendToTeacher(item);
              },
              child: const Text('Öğretmenden Destek Alacağım'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _checkPrerequisitesAndAdd(item, provider);
              },
              child: const Text('Kendim Çalışacağım'),
            ),
          ],
        ),
      );
      return;
    }

    if (item.columnId == 'column-5') {
      int limit = provider.daysUntilExam > 120 ? 2 : 5;
      if (provider.getCompletedSubjectCountInProgram() >= limit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.daysUntilExam > 120
                  ? 'Sınava henüz çok vakit var. Bu sütundan haftada en fazla $limit tekrar konusu seçebilirsin.'
                  : 'Genel tekrar dönemi limitine ulaştın. (Maks: $limit konu)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    await _checkPrerequisitesAndAdd(item, provider);
  }

  Future<void> _checkPrerequisitesAndAdd(
    StudySubject item,
    StudyProgramProvider provider,
  ) async {
    final eksikOnKosullar = provider.getMissingPrerequisites(item);
    final lockMode = _resolvePrerequisiteLockMode(item);

    if (eksikOnKosullar.isEmpty || lockMode == _PrerequisiteLockMode.none) {
      provider.addSubjectToBasket(item);
      return;
    }

    if (lockMode == _PrerequisiteLockMode.unstudiedInfo) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ön Koşul Bilgilendirmesi'),
          content: Text(
            '${item.name} konusundan önce aşağıdaki temel konuları da gözden geçirmen önerilir:\n\n${eksikOnKosullar.map((e) => '• ${e.name}').join('\n')}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.addSubjectToBasket(item);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    final dialogResult = await _showPrerequisiteSelectionDialog(
      subject: item,
      provider: provider,
      missingPrerequisites: eksikOnKosullar,
      allowSkip: lockMode == _PrerequisiteLockMode.softLock,
    );

    if (!mounted || dialogResult == null) {
      return;
    }

    if (dialogResult.addOnlyMainSubject) {
      provider.addSubjectToBasket(item);
      return;
    }

    if (dialogResult.selectedPrerequisites.isNotEmpty) {
      provider.addSubjectToBasketWithPrerequisites(
        item,
        dialogResult.selectedPrerequisites,
      );
    }
  }

  Future<_PrerequisiteDialogResult?> _showPrerequisiteSelectionDialog({
    required StudySubject subject,
    required StudyProgramProvider provider,
    required List<StudySubject> missingPrerequisites,
    required bool allowSkip,
  }) {
    final selectedIds = <String>{};

    return showDialog<_PrerequisiteDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                allowSkip ? 'Ön Koşul Önerisi' : 'Ön Koşul Gerekli',
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allowSkip
                          ? '${subject.name} konusuna geçmeden önce aşağıdaki ön koşulları sepete eklemen önerilir.'
                          : 'Bu ${subject.name} konusunu sepete atmadan önce en az 1 ön koşul seçmelisin.',
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: missingPrerequisites.map((prerequisite) {
                            final effectiveHours = provider.getEffectiveDuration(
                              prerequisite,
                              prerequisite.columnId,
                            );
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: selectedIds.contains(prerequisite.id),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedIds.add(prerequisite.id);
                                  } else {
                                    selectedIds.remove(prerequisite.id);
                                  }
                                });
                              },
                              title: Text(prerequisite.name),
                              subtitle: Text(
                                'Saf skor: ${prerequisite.opticalSuccess.toStringAsFixed(0)} • +${_formatHours(effectiveHours)} Saat',
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                if (allowSkip)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(
                      const _PrerequisiteDialogResult(addOnlyMainSubject: true),
                    ),
                    child: const Text('Sadece Bunu Ekle'),
                  ),
                ElevatedButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () {
                          final selectedPrerequisites = missingPrerequisites
                              .where((item) => selectedIds.contains(item.id))
                              .toList();
                          Navigator.of(dialogContext).pop(
                            _PrerequisiteDialogResult(
                              selectedPrerequisites: selectedPrerequisites,
                            ),
                          );
                        },
                  child: const Text('Ön Koşulla Birlikte Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectColumn(String columnId, StudyProgramProvider provider) {
    final config = columnConfigs[columnId]!;
    final String title = config['title'];
    final Color color = config['color'];
    final items = provider.getSubjectsForColumn(columnId);
    final totalEffectiveHours = items.fold<double>(
      0.0,
      (sum, item) => sum + provider.getEffectiveDuration(item, columnId),
    );

    final List<DropdownMenuItem<String?>> dropdownItems = [
      const DropdownMenuItem<String?>(value: null, child: Text("Tüm Dersler", style: TextStyle(fontSize: 13))),
      ...provider.sortedCourseNames.map((course) => DropdownMenuItem<String?>(
            value: course,
            child: Text(course, style: const TextStyle(fontSize: 13)),
          )),
    ];

    final columnScrollController = _getColumnScrollController(columnId);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.9), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} Konu / ${totalEffectiveHours % 1 == 0 ? totalEffectiveHours.toStringAsFixed(0) : totalEffectiveHours.toStringAsFixed(1)} Saat',
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.85), fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: provider.getColumnFilter(columnId),
                  icon: Icon(Icons.keyboard_arrow_down, size: 20, color: color),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  items: dropdownItems,
                  onChanged: (newValue) => provider.setColumnFilter(columnId, newValue),
                ),
              ),
            ),
          ),
          Expanded(
            child: DragTarget<StudySubject>(
              builder: (context, candidateData, rejectedData) {
                return Scrollbar(
                  thumbVisibility: columnScrollController.hasClients,
                  controller: columnScrollController,
                  child: ListView.builder(
                    controller: columnScrollController,
                    primary: false,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final effectiveHours = provider.getEffectiveDuration(item, columnId);
                      return Draggable<StudySubject>(
                        data: item,
                        feedback: Material(elevation: 6, color: Colors.transparent, child: Container(width: 220, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent)), child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)))),
                        childWhenDragging: const SizedBox.shrink(),
                        child: Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            title: Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saf skor: ${item.safeScore.toStringAsFixed(0)} • Süre: ${effectiveHours % 1 == 0 ? effectiveHours.toStringAsFixed(0) : effectiveHours.toStringAsFixed(1)} saat',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  child: _buildTaskTagChip(columnId),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 20),
                              onPressed: () => _handleAddToBasket(item, item.columnId),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramBuilderTab(StudyProgramProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Haftalık Toplam Bütçe: ${provider.weeklyBudgetHours} Saat", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: provider.budgetProgress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: provider.isOverBudget ? Colors.red.shade100 : Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(provider.isOverBudget ? Colors.red : Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final currentTotalHours = provider.weeklyBudgetHours - provider.remainingHours;
                  final absoluteMaxHours = provider.activeDayCount * 12;

                  if (currentTotalHours >= absoluteMaxHours) {
                    return const Text(
                      '⛔ KAPASİTE DOLDU! Günde ortalama 12 saatlik mutlak sınırı doldurdun, programa daha fazla konu seçemezsin.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    );
                  } else if (provider.remainingHours < 0) {
                    return Text(
                      '⚠️ Haftalık ${-(provider.remainingHours)} saat fazladan konu çalışması koydun programa, bu seni zorlar.',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    );
                  } else {
                    return Text(
                      'Kalan süre: ${provider.remainingHours} saat',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Scrollbar(
            thumbVisibility: _kanbanScrollController.hasClients,
            controller: _kanbanScrollController,
            child: SingleChildScrollView(
              controller: _kanbanScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: provider.columnOrder.map((colId) => _buildSubjectColumn(colId, provider)).toList()),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: DragTarget<StudySubject>(
            onAcceptWithDetails: (details) {
              _handleAddToBasket(details.data, details.data.columnId);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text('Programa Eklenecek Konular (Sepet)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 45,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: provider.basketSubjects.length,
                        itemBuilder: (context, index) {
                          final item = provider.basketSubjects[index];
                          return Card(
                            elevation: 1,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              leading: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              title: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              trailing: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                onPressed: () {
                                  provider.removeFromBasket(item);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCardUI(
    StudySubject task,
    StudyProgramProvider provider, {
    required int dayIndex,
    bool isCompact = false,
  }) {
    bool isSaved = provider.isProgramSaved;
    final isCompletedForDay = task.completedDays.contains(dayIndex);

    return Card(
      elevation: isCompact ? 1 : 2,
      color: isCompletedForDay ? Colors.green.shade50 : Colors.white,
      margin: EdgeInsets.only(bottom: isCompact ? 6 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 16, vertical: 0),
            leading: Checkbox(
              value: isCompletedForDay,
              activeColor: Colors.green,
              onChanged: (_) => provider.toggleSubjectCompletion(task, dayIndex),
            ),
            title: Text(
              task.name, 
              style: TextStyle(fontSize: isCompact ? 11 : 14, fontWeight: FontWeight.bold, decoration: isCompletedForDay ? TextDecoration.lineThrough : null),
              maxLines: isCompact ? 2 : null, overflow: isCompact ? TextOverflow.ellipsis : null,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCompact)
                  Text('Durum: ${task.effectiveScore.toStringAsFixed(0)} puan'),
                SizedBox(height: isCompact ? 2 : 4),
                _buildTaskTagChip(task.columnId),
              ],
            ),
            trailing: isSaved ? null : IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: isCompact ? 16 : 24),
              onPressed: () => provider.removeFromProgram(task),
            ),
          ),
          if (!isCompact) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
              child: Text('Koçun Notu: ${task.opticalSuccess < 70 ? 'Temel kavramları tekrar et.' : 'Eksik kazanımlara odaklan.'}'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDailyTaskCard(StudySubject task, int dayIndex) {
    final provider = context.read<StudyProgramProvider>();
    return _buildTaskCardUI(task, provider, dayIndex: dayIndex, isCompact: true);
  }

  Widget _buildWeeklyGridView(StudyProgramProvider provider) {
    final visibleDays = List.generate(7, (index) => index)
        .where((dayIndex) => !(provider.holidayPreferences.length > dayIndex && provider.holidayPreferences[dayIndex]))
        .toList();

    return Expanded(
      child: Container(
        color: Colors.grey.shade50,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: visibleDays.map((dayIndex) {
            final loopDay = currentWeekStart.add(Duration(days: dayIndex));
            final dayTasks = provider.activeProgramSubjects.where((item) => item.assignedDays.contains(dayIndex)).toList();

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // Gün Başlığı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: loopDay.day == DateTime.now().day ? Colors.blueAccent : Colors.blueGrey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      child: Column(
                        children: [
                          Text(weekDaysTr[dayIndex], style: TextStyle(fontWeight: FontWeight.bold, color: loopDay.day == DateTime.now().day ? Colors.white : Colors.black87)),
                          Text(_formatDate(loopDay), style: TextStyle(fontSize: 12, color: loopDay.day == DateTime.now().day ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                    // Görev Listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: dayTasks.length,
                        itemBuilder: (context, taskIndex) => _buildDailyTaskCard(dayTasks[taskIndex], dayIndex),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopBanner(StudyProgramProvider provider) {
    final isOverBudget = provider.isOverBudget;
    final statusMessage = isOverBudget
        ? '⚠️ Kapasite Aşımı! Lütfen programı hafifletin.'
        : '✅ Program kapasitesi ideal seviyede.';
    final statusColors = isOverBudget
        ? [Colors.redAccent, Colors.deepOrangeAccent]
        : [Colors.green.shade600, Colors.blueAccent];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: statusColors,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isOverBudget ? Icons.warning_amber_rounded : Icons.verified, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusMessage,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (provider.notificationMessages.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: provider.notificationMessages
                  .map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyDetailedView(StudyProgramProvider provider) {
    final dayTasks = provider.activeProgramSubjects.where((item) => item.assignedDays.contains(selectedDayIndex)).toList();

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 70,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (context, index) {
                bool isSelected = selectedDayIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedDayIndex = index),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        weekDaysTr[index], 
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dayTasks.isEmpty 
              ? const Center(child: Text("Bu güne atanmış bir görev bulunmuyor.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayTasks.length,
                  itemBuilder: (context, index) => _buildTaskCardUI(dayTasks[index], provider, dayIndex: selectedDayIndex, isCompact: false),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCalendarTab(StudyProgramProvider provider) {
    if (!provider.hasActiveProgram) {
      return const Center(child: Text("Henüz aktif bir programınız yok.\nTasarım Merkezi'nden program oluşturun."));
    }

    final endOfWeek = currentWeekStart.add(const Duration(days: 6));
    final weekRangeString = '${_formatDate(currentWeekStart)} - ${_formatDate(endOfWeek)}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeWeek(-1)),
                  Text(weekRangeString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeWeek(1)),
                ],
              ),
              ToggleButtons(
                isSelected: [!isWeeklyView, isWeeklyView],
                onPressed: (index) => setState(() => isWeeklyView = index == 1),
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Gün')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Hafta')),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        if (isWeeklyView)
          _buildWeeklyGridView(provider)
        else
          _buildDailyDetailedView(provider),

        if (!provider.isProgramSaved)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.saveProgram();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Program kilitlendi ve kaydedildi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text("PROGRAMI KAYDET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProgramProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: Builder(
              builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
            ),
            title: const Text('Çalışma Programım'),
          ),
          body: Column(
            children: [
              _buildTopBanner(provider),
              const SizedBox(height: 8),
              _buildSmartTopicSearch(context, provider),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 180,
                      margin: const EdgeInsets.fromLTRB(16, 0, 12, 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tabController.index == 0 ? Colors.blueAccent : Colors.blueGrey.shade100,
                              foregroundColor: _tabController.index == 0 ? Colors.white : Colors.black87,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onPressed: () => _tabController.animateTo(0),
                            icon: const Icon(Icons.dashboard_customize, size: 18),
                            label: const Text('Tasarım'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onPressed: () {
                              if (provider.basketSubjects.isEmpty && !provider.hasActiveProgram) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lütfen önce sepete konu ekleyin!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              _showHolidaySelectionDialog(context, provider);
                            },
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('Güncelle'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tabController.index == 1 ? Colors.blueAccent : Colors.blueGrey.shade100,
                              foregroundColor: _tabController.index == 1 ? Colors.white : Colors.black87,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onPressed: () => _tabController.animateTo(1),
                            icon: const Icon(Icons.event_note, size: 18),
                            label: const Text('Takvim'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16, bottom: 16),
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildProgramBuilderTab(provider),
                            _buildDailyCalendarTab(provider),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}