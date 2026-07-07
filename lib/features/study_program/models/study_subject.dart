class StudySubject {
  StudySubject({
    required this.id,
    required this.name,
    required this.courseName,
    required this.programOrder,
    required this.opticalSuccess,
    required this.manualSuccess,
    required this.estimatedStudyHours,
    this.lastTestScore,
    this.placementCount = 0,
    this.columnId = 'column-1',
    this.isCompleted = false,
    this.assignedDayIndex, // YENİ EKLENEN: Takvimde hangi günde olduğunu hatırlar
  });

  final String id;
  final String name;
  final String courseName;
  final int programOrder;
  final double opticalSuccess;
  final double manualSuccess;
  final int estimatedStudyHours;
  final double? lastTestScore;
  int placementCount;
  String columnId;
  bool isCompleted;
  int? assignedDayIndex; // YENİ EKLENEN

  double get safeScore => ((opticalSuccess * 0.70) + (manualSuccess * 0.30));

  double get effectiveScore {
    final last = lastTestScore ?? opticalSuccess;
    final accelerationThreshold = safeScore * 1.15;
    return last > accelerationThreshold ? last : safeScore;
  }
}