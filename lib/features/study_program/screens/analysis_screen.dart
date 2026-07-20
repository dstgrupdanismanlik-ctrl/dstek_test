import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  final List<String> _risingMomentum = const [
    'Matematik - Fonksiyonlar (+%12)',
    'Kimya - Organik Tepkimeler (+%9)',
    'Biyoloji - Sistemler (+%7)',
  ];

  final List<String> _fallingMomentum = const [
    'Fizik - Vektörler (-%8)',
    'Geometri - Çember (-%6)',
    'Tarih - İnkilaplar (-%4)',
  ];

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
                onTap: () => setState(() => _selectedPeriod = period),
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

  Widget _buildProgramFitChart() {
    final assignedSpots = _assignedTasksMock
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble() + 1, entry.value))
        .toList();
    final completedSpots = _completedTasksMock
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble() + 1, entry.value))
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Program Uyum İstatistiği',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Verilen görev ve tamamlanan görev karşılaştırması', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(enabled: true),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
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
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text('%${value.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.black54));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 1 || value > 6) return const SizedBox.shrink();
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
                _LegendDot(color: Color(0xFF5E35B1), label: 'Verilen Görev'),
                _LegendDot(color: Color(0xFF00897B), label: 'Tamamlanan Görev'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentumRadar() {
    Widget buildColumn({
      required String title,
      required String icon,
      required List<String> items,
      required Color accent,
    }) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$icon $title', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(item, style: const TextStyle(fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Momentum Radar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildColumn(
                  title: 'Yükselenler',
                  icon: '🚀',
                  items: _risingMomentum,
                  accent: const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 12),
                buildColumn(
                  title: 'Düşenler',
                  icon: '⚠️',
                  items: _fallingMomentum,
                  accent: const Color(0xFFEF6C00),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProgramProvider>(
      builder: (context, provider, _) {
        final usedHours = _calculateUsedHours(provider);
        final weeklyBudget = provider.weeklyBudgetHours;
        final reachedPercent =
            weeklyBudget <= 0 ? 0.0 : ((usedHours / weeklyBudget) * 100).clamp(0.0, 100.0);

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
                _buildGoalGauge(reachedPercent),
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
                          value: '2s 40d',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniStatCard(
                          icon: Icons.task_alt,
                          color: const Color(0xFF00897B),
                          title: 'Günlük Soru',
                          value: '145',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniStatCard(
                          icon: Icons.stacked_line_chart,
                          color: const Color(0xFFEF6C00),
                          title: 'Toplam Soru',
                          value: '4250',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDominanceChart(notStartedCount, inProgressCount, completedCount),
                const SizedBox(height: 16),
                _buildProgramFitChart(),
                const SizedBox(height: 16),
                _buildMomentumRadar(),
              ],
            ),
          ),
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