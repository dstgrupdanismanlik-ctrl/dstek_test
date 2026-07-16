import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dstek/features/study_program/models/study_subject.dart';
import 'package:dstek/features/study_program/providers/study_program_provider.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

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
  
  DateTime currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  bool isWeeklyView = true;
  int selectedDayIndex = DateTime.now().weekday - 1;

  final List<String> weekDaysTr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final List<String> monthsTr = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  final Map<String, Map<String, dynamic>> columnConfigs = {
    'column-1': {'title': 'Hiç Çalışılmamış', 'color': Colors.grey},
    'column-2': {'title': '%70 Altı / Destek Al', 'color': Colors.orange},
    'column-3': {'title': '%70-79 / Tekrar Et', 'color': Colors.blue},
    'column-4': {'title': '%80-89 / Soru Çöz', 'color': Colors.green},
    'column-5': {'title': '%90 Üzeri / Tamamlandı', 'color': Colors.purple},
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
              content: Column(
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
              actions: [
                ElevatedButton(
                  onPressed: () {
                    final activeDays = <int>[];
                    for (int i = 0; i < selectedHolidays.length; i++) {
                      if (!selectedHolidays[i]) activeDays.add(i);
                    }

                    final totalScheduledHours = provider.basketSubjects.fold<int>(0, (sum, item) => sum + item.estimatedStudyHours) +
                                                provider.activeProgramSubjects.fold<int>(0, (sum, item) => sum + item.estimatedStudyHours);

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

  Widget _buildSubjectColumn(String columnId, StudyProgramProvider provider) {
    final config = columnConfigs[columnId]!;
    final String title = config['title'];
    final Color color = config['color'];
    final items = provider.getSubjectsForColumn(columnId);

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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Center(child: Text('$title (${items.length})', style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.9), fontSize: 14))),
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
                            subtitle: Text('Saf skor: ${item.safeScore.toStringAsFixed(0)} • Süre: ${item.estimatedStudyHours} saat', style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 20), onPressed: () => provider.addSubjectToBasket(item)),
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
            onAcceptWithDetails: (details) => provider.addSubjectToBasket(details.data),
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

  Widget _buildTaskCardUI(StudySubject task, StudyProgramProvider provider, {bool isCompact = false}) {
    bool isSaved = provider.isProgramSaved;

    return Card(
      elevation: isCompact ? 1 : 2,
      color: task.isCompleted ? Colors.green.shade50 : Colors.white,
      margin: EdgeInsets.only(bottom: isCompact ? 6 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 16, vertical: 0),
            leading: Checkbox(
              value: task.isCompleted,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => task.isCompleted = val ?? false),
            ),
            title: Text(
              task.name, 
              style: TextStyle(fontSize: isCompact ? 11 : 14, fontWeight: FontWeight.bold, decoration: task.isCompleted ? TextDecoration.lineThrough : null),
              maxLines: isCompact ? 2 : null, overflow: isCompact ? TextOverflow.ellipsis : null,
            ),
            subtitle: isCompact ? null : Text('Durum: ${task.effectiveScore.toStringAsFixed(0)} puan'),
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

  Widget _buildDailyTaskCard(StudySubject task) {
    final provider = context.read<StudyProgramProvider>();
    return _buildTaskCardUI(task, provider, isCompact: true);
  }

  Widget _buildWeeklyGridView(StudyProgramProvider provider) {
    return Expanded(
      child: Container(
        color: Colors.grey.shade50,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(7, (dayIndex) {
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
                        itemBuilder: (context, taskIndex) => _buildDailyTaskCard(dayTasks[taskIndex]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
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
                  itemBuilder: (context, index) => _buildTaskCardUI(dayTasks[index], provider, isCompact: false),
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
                    const SnackBar(content: Text('Program kilitlendi ve kaydedildi!')),
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
            title: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SOL SEKME: TASARIM
                    InkWell(
                      onTap: () => _tabController.animateTo(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabController.index == 0 ? Colors.blueAccent : Colors.transparent, width: 3))),
                        child: Row(children: [Icon(Icons.dashboard_customize, size: 16, color: _tabController.index == 0 ? Colors.blueAccent : Colors.grey), const SizedBox(width: 4), Text('Tasarım', style: TextStyle(fontSize: 14, color: _tabController.index == 0 ? Colors.blueAccent : Colors.grey, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ORTA BUTON: GÜNCELLE
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        if (provider.basketSubjects.isEmpty && !provider.hasActiveProgram) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce sepete konu ekleyin!')));
                          return;
                        }
                        _showHolidaySelectionDialog(context, provider);
                      },
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text("GÜNCELLE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    // SAĞ SEKME: TAKVİM
                    InkWell(
                      onTap: () => _tabController.animateTo(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabController.index == 1 ? Colors.blueAccent : Colors.transparent, width: 3))),
                        child: Row(children: [Icon(Icons.event_note, size: 16, color: _tabController.index == 1 ? Colors.blueAccent : Colors.grey), const SizedBox(width: 4), Text('Takvim', style: TextStyle(fontSize: 14, color: _tabController.index == 1 ? Colors.blueAccent : Colors.grey, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildProgramBuilderTab(provider),
                    _buildDailyCalendarTab(provider),
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