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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kanbanScrollController.dispose();
    _weeklyScrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day} ${monthsTr[date.month]}';

  void _changeWeek(int delta) {
    setState(() {
      currentWeekStart = currentWeekStart.add(Duration(days: delta * 7));
    });
  }

  void _showHolidaySelectionDialog(StudyProgramProvider provider) {
    List<bool> selectedHolidays = [false, false, false, false, false, false, true];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tatil Günlerini Seçin"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  return CheckboxListTile(
                    title: Text(weekDaysTr[index]),
                    value: selectedHolidays[index],
                    onChanged: (val) {
                      setDialogState(() => selectedHolidays[index] = val!);
                    },
                  );
                }),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    List<int> activeDays = [];
                    for (int i = 0; i < 7; i++) {
                      if (!selectedHolidays[i]) activeDays.add(i);
                    }
                    provider.setActiveDayCount(activeDays.length);
                    provider.distributeProgram(activeDays);
                    
                    Navigator.pop(context);
                    _tabController.animateTo(1);
                  },
                  child: const Text("Dağıtımı Başlat"),
                )
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
          Expanded(
            child: ListView.builder(
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
          ),
        ],
      ),
    );
  }

  Widget _buildProgramBuilderTab(StudyProgramProvider provider) {
    bool isUpdateMode = provider.hasActiveProgram;
    bool isButtonEnabled = provider.basketSubjects.isNotEmpty || isUpdateMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Haftalık Toplam Bütçe: ${provider.weeklyBudgetHours} Saat", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: provider.budgetProgress,
                      minHeight: 10,
                      backgroundColor: provider.isOverBudget ? Colors.red.shade100 : Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(provider.isOverBudget ? Colors.red : Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Kalan süre: ${provider.remainingHours} saat', style: TextStyle(color: provider.isOverBudget ? Colors.red : Colors.blueGrey, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Scrollbar(
            thumbVisibility: true,
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
          flex: 4,
          child: DragTarget<StudySubject>(
            onAcceptWithDetails: (details) => provider.addSubjectToBasket(details.data),
            builder: (context, candidateData, rejectedData) {
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: [
                    const Padding(padding: EdgeInsets.all(8.0), child: Text("🛒 Programa Eklenecek Konular (Sepet)", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.basketSubjects.length,
                        itemBuilder: (context, index) {
                          final item = provider.basketSubjects[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              dense: true,
                              title: Text(item.name, style: const TextStyle(fontSize: 13)),
                              trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => provider.removeFromBasket(item)),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: isButtonEnabled ? () => _showHolidaySelectionDialog(provider) : null,
                          icon: Icon(isUpdateMode ? Icons.update : Icons.calendar_month),
                          label: Text(isUpdateMode ? "PROGRAMI GÜNCELLE" : "PROGRAMI YAP"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUpdateMode ? Colors.orange.shade600 : Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    )
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

  Widget _buildWeeklyGridView(StudyProgramProvider provider) {
    bool isSaved = provider.isProgramSaved;

    return Expanded(
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          thumbVisibility: true,
          controller: _weeklyScrollController,
          child: SingleChildScrollView(
            controller: _weeklyScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (dayIndex) {
                final loopDay = currentWeekStart.add(Duration(days: dayIndex));
                final dayTasks = provider.activeProgramSubjects.where((item) => item.assignedDayIndex == dayIndex).toList();

                return DragTarget<StudySubject>(
                  onWillAcceptWithDetails: (_) => !isSaved,
                  onAcceptWithDetails: (details) => provider.changeSubjectDay(details.data, dayIndex),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: candidateData.isNotEmpty ? Colors.blue : Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: loopDay.day == DateTime.now().day ? Colors.blueAccent : Colors.blueGrey.shade600,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                            ),
                            child: Column(
                              children: [
                                Text(weekDaysTr[dayIndex], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                Text(_formatDate(loopDay), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(6),
                              itemCount: dayTasks.length,
                              itemBuilder: (context, taskIndex) {
                                final task = dayTasks[taskIndex];
                                final cardUI = _buildTaskCardUI(task, provider, isCompact: true);
                                
                                if (isSaved) return cardUI;

                                return Draggable<StudySubject>(
                                  data: task,
                                  feedback: Material(elevation: 4, child: Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(task.name)))),
                                  childWhenDragging: const Opacity(opacity: 0.3, child: Card(child: ListTile(title: Text("Taşınıyor...")))),
                                  child: cardUI,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyDetailedView(StudyProgramProvider provider) {
    final dayTasks = provider.activeProgramSubjects.where((item) => item.assignedDayIndex == selectedDayIndex).toList();

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
      return const Center(child: Text("Henüz aktif bir programınız yok.\nTasarım Merkezi'nden program oluşturun.", textAlign: TextAlign.center));
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
        
        if (isWeeklyView) _buildWeeklyGridView(provider) else _buildDailyDetailedView(provider),

        if (!provider.isProgramSaved)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: ElevatedButton.icon(
              onPressed: () {
                provider.saveProgram();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Program başarıyla kalıcı olarak kaydedildi."), backgroundColor: Colors.green));
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("PROGRAMI KAYDET"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          )
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
            title: const Text('Çalışma Programım'),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.blueAccent,
              indicatorColor: Colors.blueAccent,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_customize), text: 'Tasarım'),
                Tab(icon: Icon(Icons.event_note), text: 'Takvim'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildProgramBuilderTab(provider),
              _buildDailyCalendarTab(provider),
            ],
          ),
        );
      },
    );
  }
}