import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dstek/features/academic_room/screens/academic_study_room_screen.dart';
import 'package:dstek/features/exams/providers/exam_provider.dart';
import 'package:dstek/features/study_program/models/study_subject.dart';
import 'package:dstek/features/study_program/providers/study_program_provider.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

enum AnalysisPeriod { gun, hafta, ay, yil }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisPeriod _selectedPeriod = AnalysisPeriod.hafta;

  final List<double> _assignedTasksMock = [72, 74, 79, 84, 87, 92];
  final List<double> _completedTasksMock = [60, 66, 69, 78, 80, 88];

  double _calculateUsedHours(StudyProgramProvider provider) {
    final allPlanned = [...provider.basketSubjects, ...provider.activeProgramSubjects];
    return allPlanned.fold<double>(
      0.0,
      (sum, item) => sum + provider.getEffectiveDuration(item, item.columnId),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: AnalysisPeriod.values.map((period) {
          final selected = _selectedPeriod == period;
          final labels = {
            AnalysisPeriod.gun: 'Gün',
            AnalysisPeriod.hafta: 'Hafta',
            AnalysisPeriod.ay: 'Ay',
            AnalysisPeriod.yil: 'Yıl',
          };
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.blueAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() => _selectedPeriod = period);
                  context.read<ExamProvider>().setTimeFilter(labels[period]!);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    labels[period]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalGauge(double reachedPercent) {
    final clampedPercent = reachedPercent.clamp(0, 100);
    final remaining = 100 - clampedPercent;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hedefe Kalan Mesafe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: 74,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(enabled: false),
                      sections: [
                        PieChartSectionData(
                          value: clampedPercent.toDouble(),
                          color: Colors.blueAccent,
                          radius: 24,
                          title: '',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF26C6DA)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        PieChartSectionData(
                          value: remaining.toDouble(),
                          color: Colors.blueGrey.withValues(alpha: 0.14),
                          radius: 24,
                          title: '',
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '%${clampedPercent.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text('Genel Başarı', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(
                        'Hedefe Kalan: %${remaining.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.16), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDominanceChart(int notStarted, int inProgress, int completed) {
    final maxValue = math.max(1, math.max(notStarted, math.max(inProgress, completed))).toDouble();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konu Hakimiyet Hunisi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxValue + 2,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 2,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.blueGrey.withValues(alpha: 0.12), strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Hiç', 'Süreçte', 'Halledildi'];
                          if (value < 0 || value > 2) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: notStarted.toDouble(),
                          width: 24,
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(colors: [Color(0xFF90A4AE), Color(0xFF78909C)]),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: inProgress.toDouble(),
                          width: 24,
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: completed.toDouble(),
                          width: 24,
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
                        ),
                      ],
                    ),
                  ],
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItem: (group, _, rod, __) {
                        const labels = ['Hiç', 'Süreçte', 'Halledildi'];
                        return BarTooltipItem(
                          '${labels[group.x]}\n${rod.toY.toInt()} konu',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramFitChart(List<double> weeklyData) {
    final assignedSpots = _assignedTasksMock
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble() + 1, entry.value))
        .toList();
    final completedSpots = weeklyData
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble() + 1, entry.value))
        .toList();

    // Max Y değerini bulup grafiğin tavanını dinamik ayarlayalım
    final maxY = weeklyData.isEmpty ? 100.0 : weeklyData.reduce(math.max) + 50.0;
    final double yInterval = (maxY / 5).ceilToDouble() > 0 ? (maxY / 5).ceilToDouble() : 20.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Çözüm İstatistiği',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Zaman içindeki soru çözüm performansı', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(enabled: true),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.blueGrey.withValues(alpha: 0.12), strokeWidth: 1);
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          // 1000'den büyük sayıları kısaltmak için 1K gibi gösterebiliriz
                          final displayValue = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toInt().toString();
                          return Text(displayValue, style: const TextStyle(fontSize: 11, color: Colors.black54));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value < 1 || value > 6 || value % 1 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${value.toInt()}. Hafta', style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: assignedSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF5E35B1),
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5E35B1).withValues(alpha: 0.30),
                            const Color(0xFF5E35B1).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: completedSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF00897B),
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00897B).withValues(alpha: 0.26),
                            const Color(0xFF00897B).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: const [
                _LegendDot(color: Color(0xFF5E35B1), label: 'Hedeflenen'),
                _LegendDot(color: Color(0xFF00897B), label: 'Çözülen Soru'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentumRadar(BuildContext context, ExamProvider provider) {
    final momentumData = provider.getMomentumData();

    if (momentumData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.radar, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text('Momentum Radarı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Henüz son test verileriyle röntgen arasında bir kıyaslama oluşmadı. Test çözdükçe burası canlanacak! 💖', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.radar, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Momentum Radarı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...momentumData.map((m) {
          final isRising = m['durum'] == 'yukseliste';
          final color = isRising ? Colors.green : Colors.red;
          final icon = isRising ? Icons.trending_up : Icons.trending_down;
          final diff = (m['fark'] as double).abs().toInt();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(m['konu'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${m['ders']} • Eski: %${(m['eski'] as double).toInt()} ➔ Yeni: %${(m['yeni'] as double).toInt()}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${isRising ? '+' : '-'}$diff',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_circle_right, color: Colors.blueAccent, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AcademicStudyRoomScreen(
                            initialDers: m['ders'],
                            initialKonu: m['konu'],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudyProgramProvider, ExamProvider>(
      builder: (context, provider, examProvider, _) {
        final usedHours = _calculateUsedHours(provider);
        final formattedUsedHours = '${usedHours.toInt()}s ${((usedHours % 1) * 60).toInt()}d';

        final List<StudySubject> allSubjects = [
          ...provider.subjects,
          ...provider.basketSubjects,
          ...provider.activeProgramSubjects,
        ];

        final int notStartedCount = allSubjects.where((s) => s.columnId == 'column-1').length;
        final int inProgressCount = allSubjects
            .where((s) => s.columnId == 'column-2' || s.columnId == 'column-3' || s.columnId == 'column-4')
            .length;
        final int completedCount = allSubjects.where((s) => s.columnId == 'column-5').length;

        return Scaffold(
          appBar: AppBar(title: const Text('Durum Analizi')),
          drawer: const AppDrawer(),
          backgroundColor: const Color(0xFFF5F8FC),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodToggle(),
                const SizedBox(height: 16),
                _buildGoalGauge(examProvider.filteredGenelBasari),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMiniStatCard(
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF5E35B1),
                          title: 'Ort. Çalışma',
                          value: usedHours > 0 ? formattedUsedHours : '0s 0d',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniStatCard(
                          icon: Icons.task_alt,
                          color: const Color(0xFF00897B),
                          title: 'Günlük Soru',
                          value: examProvider.gunlukSoru.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniStatCard(
                          icon: Icons.stacked_line_chart,
                          color: const Color(0xFFEF6C00),
                          title: 'Toplam Soru',
                          value: examProvider.filteredToplamSoru.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDominanceChart(notStartedCount, inProgressCount, completedCount),
                const SizedBox(height: 16),
                _buildProgramFitChart(examProvider.altiHaftalikDagilim),
                const SizedBox(height: 24),
                _buildSubjectXrayList(context, examProvider),
                const SizedBox(height: 24),
                _buildMomentumRadar(context, examProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectXrayList(BuildContext context, ExamProvider provider) {
    String? localSelectedDers;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('curriculum').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final Map<String, List<Map<String, dynamic>>> dersKonulari = {};

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ders = data['ders'] as String? ?? data['ders_adi'] as String? ?? data['lesson'] as String? ?? 'Bilinmeyen Ders';
          dersKonulari.putIfAbsent(ders, () => []);
          dersKonulari[ders]!.add(data);
        }

        final dersListesi = dersKonulari.keys.toList()..sort();
        if (dersListesi.isEmpty) return const SizedBox.shrink();

        return StatefulBuilder(
          builder: (context, setState) {
            if (localSelectedDers == null || !dersListesi.contains(localSelectedDers)) {
              localSelectedDers = dersListesi.first;
            }

            List<Widget> konuBarlari = [];
            for (var konuData in dersKonulari[localSelectedDers]!) {
              final konuAdi = konuData['konu'] as String? ?? konuData['konu_adi'] as String? ?? konuData['topic'] as String? ?? 'İsimsiz Konu';
              final konuKodu = konuData['konu_kodu'] as String? ?? '';
              final kocNotu = konuData['koc_tavsiyesi'] as String? ?? '';
              
              double score = 0.0;
              int totalQ = 0;
              final normalizedKonu = konuAdi.toLowerCase().replaceAll(' ', '');
              final normalizedNot = kocNotu.toLowerCase().replaceAll(' ', '');
              
              for (var xray in provider.xrayData) {
                final kKodu = (xray['konu_kodu'] as String? ?? '').toLowerCase().replaceAll(' ', '');
                if (kKodu.isNotEmpty) {
                  if (konuKodu.toLowerCase().replaceAll(' ', '') == kKodu || 
                      normalizedKonu.contains(kKodu) || 
                      kKodu.contains(normalizedKonu) ||
                      (normalizedNot.isNotEmpty && normalizedNot.contains(kKodu))) {
                    
                    score = ((xray['guvenilir_basari_skoru'] ?? 0.0) as num).toDouble();
                    
                    final optik = xray['optik_test_d_y_b'] as Map<String, dynamic>? ?? {};
                    final manuel = xray['manuel_d_y_b'] as Map<String, dynamic>? ?? {};
                    int tD = ((optik['D'] ?? 0) as num).toInt() + ((manuel['D'] ?? 0) as num).toInt();
                    int tY = ((optik['Y'] ?? 0) as num).toInt() + ((manuel['Y'] ?? 0) as num).toInt();
                    int tB = ((optik['B'] ?? 0) as num).toInt() + ((manuel['B'] ?? 0) as num).toInt();
                    totalQ = tD + tY + tB;
                    
                    if (score <= 0.0 && totalQ > 0) {
                       score = (tD / totalQ) * 100;
                    }
                    break;
                  }
                }
              }
              
              final hasData = score > 0 || totalQ > 0;
              
              konuBarlari.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(konuAdi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: hasData ? score / 100 : 1.0,
                                      minHeight: 12,
                                      backgroundColor: Colors.grey.shade200,
                                      color: hasData 
                                          ? (score >= 70 ? Colors.green.shade500 : (score >= 40 ? Colors.orange.shade500 : Colors.red.shade500))
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    hasData ? '%${score.toInt()}' : 'Yok', 
                                    style: TextStyle(
                                      fontSize: 13, 
                                      fontWeight: FontWeight.bold,
                                      color: hasData ? Colors.black87 : Colors.grey.shade500
                                    )
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_circle_right, color: Colors.blueAccent, size: 30),
                        tooltip: 'Akademik Odada Çalış',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcademicStudyRoomScreen(
                                initialDers: localSelectedDers,
                                initialKonu: konuAdi,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.pinkAccent),
                        SizedBox(width: 8),
                        Text('Tüm Derslerin Başarı Röntgeni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: localSelectedDers,
                          items: dersListesi
                              .map((ders) => DropdownMenuItem<String>(
                                    value: ders,
                                    child: Text(ders, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              localSelectedDers = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (konuBarlari.isEmpty)
                      const Text('Bu ders için henüz yeterli röntgen verisi yok. 💖', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      ...konuBarlari,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}