class StudyProgramService {
  static double calculateSafeScore(double opticalSuccess, double manualSuccess) {
    return (opticalSuccess * 0.70) + (manualSuccess * 0.30);
  }

  static double calculateEffectiveScore({
    required double opticalSuccess,
    required double manualSuccess,
    required double lastTestScore,
  }) {
    final safeScore = calculateSafeScore(opticalSuccess, manualSuccess);
    final accelerationThreshold = safeScore * 1.15;

    return lastTestScore > accelerationThreshold ? lastTestScore : safeScore;
  }

  static int getColumnHours(String columnId, {required int baseHours}) {
    switch (columnId) {
      case 'column-1':
        return (baseHours * 1.0).round();
      case 'column-2':
        return (baseHours * 1.0).round();
      case 'column-3':
        return (baseHours * 0.50).round();
      case 'column-4':
      case 'column-5':
        return (baseHours * 0.25).round();
      default:
        return baseHours;
    }
  }

  static bool canAcceptCompletedDrop({
    required int completedCount,
    required int daysUntilExam,
  }) {
    if (daysUntilExam > 120) {
      return completedCount < 2;
    }

    return completedCount < 5;
  }

  static String getColumnTitle(String columnId) {
    switch (columnId) {
      case 'column-1':
        return 'Hiç Çalışılmamış';
      case 'column-2':
        return '%70 Altı / Destek Al';
      case 'column-3':
        return '%70-79 / Tekrar Et';
      case 'column-4':
        return '%80-89 / Soru Çöz';
      case 'column-5':
        return '%90 Üzeri / Tamamlandı';
      default:
        return 'Konu Havuzu';
    }
  }

  static String? getRecommendedColumnId({
    required double opticalSuccess,
    required double manualSuccess,
    required double lastTestScore,
    required int placementCount,
  }) {
    final effective = calculateEffectiveScore(
      opticalSuccess: opticalSuccess,
      manualSuccess: manualSuccess,
      lastTestScore: lastTestScore,
    );

    if (placementCount >= 3 && effective < 70) {
      return 'column-2';
    }

    if (effective >= 90) {
      return 'column-5';
    }
    if (effective >= 80) {
      return 'column-4';
    }
    if (effective >= 70) {
      return 'column-3';
    }
    if (effective < 70) {
      return 'column-1';
    }

    return null;
  }
}
