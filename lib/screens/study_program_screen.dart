import 'package:flutter/material.dart';

// --- 1. Veri Modeli ---
class SubjectItem {
  final String id;
  final String name;
  final double successRate;
  final int solvedQuestions;
  bool isCompleted;
  DateTime? assignedDate; // Takvime dağıtıldığında atanacak tarih

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

  // 1. Bölüm: State (Durum) Listeleri
  List<SubjectItem> excellentSubjects = []; // %90 Üzeri
  List<SubjectItem> goodSubjects = [];      // %80 - 90 Arası
  List<SubjectItem> averageSubjects = [];   // %70 - 80 Arası
  List<SubjectItem> poorSubjects = [];      // %70 Altı
  List<SubjectItem> untouchedSubjects = []; // %0 (Hiç dokunulmamış)
  List<SubjectItem> basketSubjects = [];    // Seçilenler (Sepet)

  // 2. Bölüm: Takvim ve Görünüm State'leri
  DateTime currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  int selectedDayIndex = DateTime.now().weekday - 1;
  bool isWeeklyView = false; // Günlük mü, Haftalık mı?

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

  // --- Sahte Veri Yükleme ---
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

  // --- Yardımcı Metodlar ---
  String _formatDate(DateTime date) {
    return "${date.day} ${monthsTr[date.month]}";
  }

  void _changeWeek(int delta) {
    setState(() {
      currentWeekStart = currentWeekStart.add(Duration(days: delta * 7));
    });
  }

  // --- Sepet İşlemleri ---
  void _addToBasket(SubjectItem item, List<SubjectItem> sourceList) {
    setState(() {
      sourceList.remove(item);
      basketSubjects.add(item);
    });
  }

  void _removeFromBasket(SubjectItem item) {
    setState(() {
      basketSubjects.remove(item);
      // Geri iade mantığı
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
    
    // Sepetteki konuları bulunduğumuz haftanın günlerine dağıtma (Basit Dağıtım Algoritması)
    setState(() {
      for (int i = 0; i < basketSubjects.length; i++) {
        basketSubjects[i].assignedDate = currentWeekStart.add(Duration(days: i % 7));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${basketSubjects.length} konu haftaya dağıtıldı!"),
        backgroundColor: Colors.green,
      ),
    );
    _tabController.animateTo(1);
  }

  // --- BÖLÜM 1 UI: KANBAN SÜTUNLARI ---
  Widget _buildSubjectColumn(String title, Color color, List<SubjectItem> items) {
    return Container(
      width: 280,
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(
              "$title (${items.length})",
              style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.9), fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded( // Sütun içi kaydırma (Scroll) garantisi
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    title: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      item.solvedQuestions == 0 ? "Hiç Çalışılmadı" : "Başarı: %${item.successRate} | Soru: ${item.solvedQuestions}", 
                      style: const TextStyle(fontSize: 11)
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                      onPressed: () => _addToBasket(item, items),
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
                  _buildSubjectColumn("Dokunulmamış", Colors.grey, untouchedSubjects),
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
                    const Text("🛒 Programa Eklenecek Konular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Chip(label: Text("${basketSubjects.length} Seçildi"), backgroundColor: Colors.blue.shade100)
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: basketSubjects.isEmpty
                      ? Center(child: Text("Sütunlardan programlanacak konuları (+) ile ekleyin.", style: TextStyle(color: Colors.grey.shade600)))
                      : ListView.builder(
                          itemCount: basketSubjects.length,
                          itemBuilder: (context, index) {
                            final item = basketSubjects[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(item.name),
                                subtitle: Text(item.solvedQuestions == 0 ? "Yeni Konu" : "Başarı: %${item.successRate}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removeFromBasket(item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _createProgram,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text("PROGRAMI YAP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- BÖLÜM 2 UI: GÜNLÜK VE HAFTALIK TAKVİM ---
  
  // Günlük veya Haftalık görünüme göre şekil alan Görev Kartı
  Widget _buildTaskCard(SubjectItem item, {required bool isWeekly}) {
    final titleWidget = Text(
      item.name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
        color: item.isCompleted ? Colors.grey : Colors.black87,
      ),
    );
    final subtitleWidget = Text(
      item.solvedQuestions == 0 ? "Durum: Yeni Konu Çalışılacak" : "Durum: %${item.successRate} Başarı (${item.solvedQuestions} Soru)",
      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
    );
    
    final noteContent = Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Koçun Notu & Analiz:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
          const SizedBox(height: 8),
          Text(
            item.solvedQuestions == 0 
            ? "Bu konu senin için yepyeni! Temel kavramları çok iyi oturtmalı ve en az 50 kavrama sorusu çözmelisin."
            : "Bu konuda ${item.solvedQuestions} soru çözdün. Eksik kazanımlarına odaklanarak test çözmen yeterli olacaktır.",
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );

    if (isWeekly) {
      // Haftalık Görünüm: Az yer kaplaması için Açılır/Kapanır Kart (ExpansionTile)
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          leading: Checkbox(
            value: item.isCompleted,
            activeColor: Colors.green,
            onChanged: (val) => setState(() => item.isCompleted = val ?? false),
          ),
          title: titleWidget,
          subtitle: subtitleWidget,
          children: [noteContent],
        ),
      );
    } else {
      // Günlük Görünüm: Notun her zaman göz önünde olduğu Sabit Kart
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias, // İçeriğin kart dışına taşmamasını sağlar
        child: Column(
          children: [
            ListTile(
              leading: Checkbox(
                value: item.isCompleted,
                activeColor: Colors.green,
                onChanged: (val) => setState(() => item.isCompleted = val ?? false),
              ),
              title: titleWidget,
              subtitle: subtitleWidget,
            ),
            const Divider(height: 1),
            noteContent,
          ],
        ),
      );
    }
  }

  Widget _buildDailyCalendarTab() {
    DateTime endOfWeek = currentWeekStart.add(const Duration(days: 6));
    String weekRangeString = "${_formatDate(currentWeekStart)} - ${_formatDate(endOfWeek)}";

    return Column(
      children: [
        // Üst Kontrol Barı (Hafta Değiştirme ve Görünüm Seçici)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeWeek(-1)),
                  Text(weekRangeString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeWeek(1)),
                ],
              ),
              ToggleButtons(
                isSelected: [!isWeeklyView, isWeeklyView],
                onPressed: (index) {
                  setState(() {
                    isWeeklyView = index == 1;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 70),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Günlük")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Haftalık")),
                ],
              ),
            ],
          ),
        ),
        
        // Eğer Günlük görünümdeysek, yatay gün şeridini göster
        if (!isWeeklyView) ...[
          const Divider(height: 1),
          Container(
            height: 85,
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
                    width: 65,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.blue.shade800, width: 2) : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekDaysTr[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentDay.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const Divider(height: 1, thickness: 2),

        // Görevlerin Listelendiği Alan
        Expanded(
          child: Builder(
            builder: (context) {
              if (isWeeklyView) {
                // HAFTALIK GÖRÜNÜM: Tüm haftanın günlerini ve içindeki görevleri listele
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 7,
                  itemBuilder: (context, dayIndex) {
                    DateTime loopDay = currentWeekStart.add(Duration(days: dayIndex));
                    List<SubjectItem> dayTasks = basketSubjects.where((item) => 
                      item.assignedDate != null && 
                      item.assignedDate!.year == loopDay.year &&
                      item.assignedDate!.month == loopDay.month &&
                      item.assignedDate!.day == loopDay.day
                    ).toList();

                    if (dayTasks.isEmpty) return const SizedBox.shrink(); // Görev yoksa günü gösterme (opsiyonel)

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                          child: Text("${weekDaysTr[dayIndex]}, ${_formatDate(loopDay)}", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 16)),
                        ),
                        ...dayTasks.map((task) => _buildTaskCard(task, isWeekly: true)).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              } else {
                // GÜNLÜK GÖRÜNÜM: Sadece seçili günün görevlerini listele
                DateTime selectedFullDate = currentWeekStart.add(Duration(days: selectedDayIndex));
                List<SubjectItem> todaysTasks = basketSubjects.where((item) => 
                  item.assignedDate != null && 
                  item.assignedDate!.year == selectedFullDate.year &&
                  item.assignedDate!.month == selectedFullDate.month &&
                  item.assignedDate!.day == selectedFullDate.day
                ).toList();

                if (todaysTasks.isEmpty) {
                  return const Center(
                    child: Text("Bu güne ait planlanmış bir konu bulunmuyor.\nTasarımdan 'Programı Yap' butonunu kullandınız mı?", 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16))
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todaysTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(todaysTasks[index], isWeekly: false);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çalışma Programım"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize), text: "Tasarım Merkezi"),
            Tab(icon: Icon(Icons.event_note), text: "Takvim"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgramBuilderTab(), // 1. Bölüm
          _buildDailyCalendarTab(),  // 2. Bölüm
        ],
      ),
    );
  }
}