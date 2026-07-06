import 'package:flutter_test/flutter_test.dart';
import 'package:dstek/features/study_program/services/study_program_service.dart';

void main() {
  group('StudyProgramService', () {
    test('safe score uses the requested weighted formula', () {
      final score = StudyProgramService.calculateSafeScore(85, 70);
      expect(score, 80.5);
    });

    test('effective score uses last test when it is meaningfully higher', () {
      final score = StudyProgramService.calculateEffectiveScore(
        opticalSuccess: 80,
        manualSuccess: 70,
        lastTestScore: 95,
      );
      expect(score, 95.0);
    });

    test('completed column limit respects the exam countdown', () {
      final farFuture = StudyProgramService.canAcceptCompletedDrop(
        completedCount: 1,
        daysUntilExam: 180,
      );
      final nearFuture = StudyProgramService.canAcceptCompletedDrop(
        completedCount: 5,
        daysUntilExam: 90,
      );

      expect(farFuture, true);
      expect(nearFuture, false);
    });

    test('column hours follow the requested multipliers', () {
      expect(StudyProgramService.getColumnHours('column-1', baseHours: 4), 4);
      expect(StudyProgramService.getColumnHours('column-2', baseHours: 4), 4);
      expect(StudyProgramService.getColumnHours('column-3', baseHours: 4), 2);
      expect(StudyProgramService.getColumnHours('column-4', baseHours: 4), 1);
      expect(StudyProgramService.getColumnHours('column-5', baseHours: 4), 1);
    });
  });
}
