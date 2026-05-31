import 'package:flutter/material.dart';

// --- 1. Veri Modeli ---
class SubjectItem {
  final String id;
  final String name;
  final double successRate;
  final int solvedQuestions;
  bool isCompleted;
  DateTime? assignedDate;

  SubjectItem({
    required this.id,
    required this.name,
    required this.successRate,
    required this.solvedQuestions,
    this.isCompleted = false,
    this.assignedDate,
  });
}

class StudyProgramScreen extends StatefulWidget {
  const StudyProgramScreen({Key? key}) : super(key: key);

  @override
  State<StudyProgramScreen> createState() => _StudyProgramScreenState();
}

class _StudyProgramScreenState extends State<StudyProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Bölüm: State Listeleri (5 Sütun)
  List<SubjectItem> excellentSubjects = []; 
  List<SubjectItem> goodSubjects = [];      
  List<SubjectItem> averageSubjects = [];   
  List<SubjectItem> poorSubjects = [];      
  List<SubjectItem> untouchedSubjects = []; 
  List<SubjectItem> basketSubjects = [];    

  // 2. Bölüm: Takvim State'leri
  DateTime currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  int selectedDayIndex = DateTime.now().weekday - 1;
  bool isWeeklyView = false; 

  final List<String> weekDaysTr = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
  final List<String> monthsTr = ["", "Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    final allMockData = [
      SubjectItem(id: '1', name: 'T-TR-1-Sözcükte Anlam', successRate: 94.0, solvedQuestions: 280),
      SubjectItem(id: '2', name: 'T-TR-3-Paragraf', successRate: 92.0, solvedQuestions: 2975),
      SubjectItem(id: '3', name: 'T-M-3-Temel Kavramlar', successRate: 87.0, solvedQuestions: 218),
      SubjectItem(id: '4', name: 'T-M-7-Rasyonel Sayılar', successRate: 86.0, solvedQuestions: 245),
      SubjectItem(id: '5', name: 'A-Fİ-6-Enerji ve Hareket', successRate: 79.0, solvedQuestions: 167),
      SubjectItem(id: '6', name: 'A-M-16-İntegral', successRate: 79.0, solvedQuestions: 149),
      SubjectItem(id: '7', name: 'A-M-3-Eşitsizlikler', successRate: 68.0, solvedQuestions: 345),
      SubjectItem(id: '8', name: 'A-TR-15-Tiyatro', successRate: 61.0, solvedQuestions: 91),
      SubjectItem(id: '9', name: 'A-K-10-Kimyasal Tepkimelerde Denge', successRate: 0.0, solvedQuestions: 0),
      SubjectItem(id: '10', name: 'A-B-11-Popülasyon Ekolojisi', successRate: 0.0, solvedQuestions: 0),
    ];

    for (var item in allMockData) {
      if (item.solvedQuestions == 0 && item.successRate == 0) {
        untouchedSubjects.add(item);
      } else if (item.successRate >= 90) {
        excellentSubjects.add(item);
      } else if (item.successRate >= 80) {
        goodSubjects.add(item);
      } else if (item.successRate >= 70) {
        averageSubjects.add(item);
      } else {
        poorSubjects.add(item);
      }
    }
  }

  String _formatDate(DateTime date) => "${date.day} ${monthsTr[date.month]}";

  void _changeWeek(int delta) {
    setState(() {
      currentWeekStart = currentWeekStart.add(Duration(days: delta * 7));
    });
  }

  void _addToBasket(SubjectItem item, List<SubjectItem> sourceList) {
    setState(() {
      sourceList.remove(item);
      basketSubjects.add(item);
    });
  }

  void _removeFromBasket(SubjectItem item) {
    setState(() {
      basketSubjects.remove(item);
      if (item.solvedQuestions == 0 && item.successRate == 0) {
        untouchedSubjects.add(item);
      } else if (item.successRate >= 90) {
        excellentSubjects.add(item);
      } else if (item.successRate >= 80) {
        goodSubjects.add(item);
      } else if (item.successRate >= 70) {
        averageSubjects.add(item);
      } else {
        poorSubjects.add(item);
      }
    });
  }

  void _createProgram() {
    if (basketSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce sepete konu ekleyin!")),
      );
      return;
    }
    setState(() {
      for (int i = 0; i < basketSubjects.length; i++) {
        basketSubjects[i].assignedDate = currentWeekStart.add(Duration(days: i % 7));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${basketSubjects.length} konu haftaya dağıtıldı!"), backgroundColor: Colors.green),
    );
    _tabController.animateTo(1);
  }

  // --- BÖLÜM 1: PROGRAM TASARIM MERKEZİ ---
  Widget _buildSubjectColumn(String title, Color color, List<SubjectItem> items) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Text("$title (${items.length})", style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.9), fontSize: 14), textAlign: TextAlign.center),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    title: Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(item.solvedQuestions == 0 ? "Yeni Konu" : "Başarı: %${item.successRate}", style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.blueAccent), onPressed: () => _addToBasket(item, items)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramBuilderTab() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildSubjectColumn("Pekiyi (%90+)", Colors.green, excellentSubjects),
                  _buildSubjectColumn("İyi (%80-90)", Colors.blue, goodSubjects),
                  _buildSubjectColumn("Orta (%70-80)", Colors.orange, averageSubjects),
                  _buildSubjectColumn("Geliştirilmeli (<%70)", Colors.red, poorSubjects),
                  _buildSubjectColumn("Hiç Çalışılmamış", Colors.grey, untouchedSubjects),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 2),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("🛒 Programa Eklenecek Konular", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Chip(label: Text("${basketSubjects.length} Seçildi"))
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: basketSubjects.length,
                    itemBuilder: (context, index) {
                      final item = basketSubjects[index];
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(item.name, style: const TextStyle(fontSize: 13)),
                          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeFromBasket(item)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _createProgram,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("PROGRAMI YAP", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- BÖLÜM 2: TAKVİM GÖRÜNÜMLERİ ---
  Widget _buildDailyTaskCard(SubjectItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(value: item.isCompleted, activeColor: Colors.green, onChanged: (val) => setState(() => item.isCompleted = val ?? false)),
            title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
            subtitle: Text(item.solvedQuestions == 0 ? "Durum: Yeni Konu" : "Durum: %${item.successRate} Başarı"),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blue.shade50,
            child: Text("Koçun Notu: ${item.solvedQuestions == 0 ? "Temel kavramları iyi oturtmalısın." : "Eksik kazanımlara odaklanarak 2 test çöz."}"),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyGridView() {
    return Expanded(
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (dayIndex) {
                DateTime loopDay = currentWeekStart.add(Duration(days: dayIndex));
                List<SubjectItem> dayTasks = basketSubjects.where((item) => 
                  item.assignedDate != null && 
                  item.assignedDate!.day == loopDay.day &&
                  item.assignedDate!.month == loopDay.month
                ).toList();

                return Container(
                  width: 180, 
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
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
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(4),
                          itemCount: dayTasks.length,
                          itemBuilder: (context, taskIndex) {
                            final task = dayTasks[taskIndex];
                            return Card(
                              elevation: 1,
                              color: task.isCompleted ? Colors.green.shade50 : Colors.white,
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: task.isCompleted,
                                        activeColor: Colors.green,
                                        onChanged: (val) => setState(() => task.isCompleted = val ?? false),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        task.name,
                                        style: TextStyle(fontSize: 11, decoration: task.isCompleted ? TextDecoration.lineThrough : null),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCalendarTab() {
    DateTime endOfWeek = currentWeekStart.add(const Duration(days: 6));
    String weekRangeString = "${_formatDate(currentWeekStart)} - ${_formatDate(endOfWeek)}";

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
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Gün")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Hafta")),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        if (isWeeklyView) 
          _buildWeeklyGridView()
        else ...[
          Container(
            height: 70,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                bool isSelected = selectedDayIndex == index;
                DateTime currentDay = currentWeekStart.add(Duration(days: index));
                return GestureDetector(
                  onTap: () => setState(() => selectedDayIndex = index),
                  child: Container(
                    width: 55,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.blue.shade800, width: 2) : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(weekDaysTr[index], style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontSize: 12)),
                        Text(currentDay.day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                DateTime selectedFullDate = currentWeekStart.add(Duration(days: selectedDayIndex));
                List<SubjectItem> todaysTasks = basketSubjects.where((item) => 
                  item.assignedDate != null && item.assignedDate!.day == selectedFullDate.day && item.assignedDate!.month == selectedFullDate.month
                ).toList();

                if (todaysTasks.isEmpty) {
                  return const Center(child: Text("Bu güne ait görev yok.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todaysTasks.length,
                  itemBuilder: (context, index) => _buildDailyTaskCard(todaysTasks[index]),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çalışma Programım"),
        centerTitle: true,
        automaticallyImplyLeading: false, 
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize), text: "Tasarım"),
            Tab(icon: Icon(Icons.event_note), text: "Takvim"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgramBuilderTab(),
          _buildDailyCalendarTab(), 
        ],
      ),
    );
  }
}