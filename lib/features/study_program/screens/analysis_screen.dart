import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dstek/features/study_program/models/study_subject.dart';
import 'package:dstek/features/study_program/providers/study_program_provider.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  double _calculateUsedHours(StudyProgramProvider provider) {
    final allPlanned = [...provider.basketSubjects, ...provider.activeProgramSubjects];
    return allPlanned.fold<double>(
      0.0,
      (sum, item) => sum + provider.getEffectiveDuration(item, item.columnId),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProgramProvider>(
      builder: (context, provider, _) {
        final usedHours = _calculateUsedHours(provider);
        final weeklyBudget = provider.weeklyBudgetHours;
        final usagePercent = weeklyBudget <= 0 ? 0.0 : (usedHours / weeklyBudget) * 100;

        // Bütün konuları 3 havuzdan birleştiriyoruz ki grafikte eksik çıkmasın
        final List<StudySubject> allSubjects = [
          ...provider.subjects,
          ...provider.basketSubjects,
          ...provider.activeProgramSubjects
        ];

        final int notStartedCount = allSubjects.where((s) => s.columnId == 'column-1').length;
        final int inProgressCount = allSubjects
            .where((s) => s.columnId == 'column-2' || s.columnId == 'column-3' || s.columnId == 'column-4')
            .length;
        final int completedCount = allSubjects.where((s) => s.columnId == 'column-5').length;

        final sections = <PieChartSectionData>[];
        if (notStartedCount > 0) {
          sections.add(
            PieChartSectionData(
              color: Colors.grey,
              value: notStartedCount.toDouble(),
              title: '$notStartedCount',
              radius: 62,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }
        if (inProgressCount > 0) {
          sections.add(
            PieChartSectionData(
              color: Colors.blue,
              value: inProgressCount.toDouble(),
              title: '$inProgressCount',
              radius: 62,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }
        if (completedCount > 0) {
          sections.add(
            PieChartSectionData(
              color: Colors.green,
              value: completedCount.toDouble(),
              title: '$completedCount',
              radius: 62,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Detaylı Analiz')),
          drawer: const AppDrawer(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Özeti',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 360,
                      child: _buildStatCard(
                        icon: Icons.speed,
                        color: Colors.deepPurple,
                        title: 'Kapasite Kullanımı',
                        value:
                            '${usedHours.toStringAsFixed(usedHours % 1 == 0 ? 0 : 1)} / ${weeklyBudget.toStringAsFixed(weeklyBudget % 1 == 0 ? 0 : 1)} saat',
                        subtitle: '%${usagePercent.toStringAsFixed(1)} dolu',
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: _buildStatCard(
                        icon: Icons.support_agent,
                        color: Colors.orange,
                        title: 'Öğretmen Desteği',
                        value: '${provider.teacherSupportList.length} konu',
                        subtitle: 'Öğretmen Desteği Bekleyen Konular',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Müfredat Hakimiyet Grafiği',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 16,
                          spacing: 16,
                          children: [
                            SizedBox(
                              width: 280,
                              height: 240,
                              child: sections.isEmpty
                                  ? const Center(child: Text('Grafik için veri bulunamadı.'))
                                  : PieChart(
                                      PieChartData(
                                        sections: sections,
                                        centerSpaceRadius: 42,
                                        sectionsSpace: 2,
                                      ),
                                    ),
                            ),
                            SizedBox(
                              width: 280,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegendItem(Colors.grey, 'Hiç Çalışılmamışlar (column-1)', notStartedCount),
                                  _buildLegendItem(Colors.blue, 'Süreçte Olanlar (column-2/3/4)', inProgressCount),
                                  _buildLegendItem(Colors.green, 'Halledilenler (column-5)', completedCount),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}