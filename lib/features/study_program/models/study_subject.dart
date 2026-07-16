class StudySubject {
  StudySubject({
    required this.id,
    required this.name,
    required this.courseName,
    required this.programOrder,
    required this.opticalSuccess,
    required this.manualSuccess,
    required this.estimatedStudyHours,
    required this.recommendedDays,
    this.lastTestScore,
    this.placementCount = 0,
    this.columnId = 'column-1',
    this.isCompleted = false,
  });

  final String id;
  final String name;
  final String courseName;
  final int programOrder;
  final double opticalSuccess;
  final double manualSuccess;
  final int estimatedStudyHours;
  final int recommendedDays;
  final double? lastTestScore;
  int placementCount;
  String columnId;
  bool isCompleted;
  List<int> assignedDays = [];

  double get safeScore => ((opticalSuccess * 0.70) + (manualSuccess * 0.30));

  double get effectiveScore {
    final last = lastTestScore ?? opticalSuccess;
    final accelerationThreshold = safeScore * 1.15;
    return last > accelerationThreshold ? last : safeScore;
  }
}