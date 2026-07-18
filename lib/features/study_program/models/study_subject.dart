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
    double? repeatStudyHours,
    double? questionSolveHours,
    this.inCoursePrerequisite,
    this.outOfCoursePrerequisite,
    this.lastTestScore,
    this.placementCount = 0,
    this.columnId = 'column-1',
    List<int>? completedDays,
  }) : repeatStudyHours = repeatStudyHours ?? estimatedStudyHours.toDouble(),
       completedDays = List<int>.from(completedDays ?? const <int>[]),
       questionSolveHours =
           questionSolveHours ?? estimatedStudyHours.toDouble();

  final String id;
  final String name;
  final String courseName;
  final int programOrder;
  final double opticalSuccess;
  final double manualSuccess;
  final int estimatedStudyHours;
  final int recommendedDays;
  final double repeatStudyHours;
  final double questionSolveHours;
  final String? inCoursePrerequisite;
  final String? outOfCoursePrerequisite;
  final double? lastTestScore;
  final List<int> completedDays;
  int placementCount;
  String columnId;
  List<int> assignedDays = [];

  StudySubject copyWith({
    String? id,
    String? name,
    String? courseName,
    int? programOrder,
    double? opticalSuccess,
    double? manualSuccess,
    int? estimatedStudyHours,
    int? recommendedDays,
    double? repeatStudyHours,
    double? questionSolveHours,
    String? inCoursePrerequisite,
    String? outOfCoursePrerequisite,
    double? lastTestScore,
    int? placementCount,
    String? columnId,
    List<int>? assignedDays,
    List<int>? completedDays,
  }) {
    final updated = StudySubject(
      id: id ?? this.id,
      name: name ?? this.name,
      courseName: courseName ?? this.courseName,
      programOrder: programOrder ?? this.programOrder,
      opticalSuccess: opticalSuccess ?? this.opticalSuccess,
      manualSuccess: manualSuccess ?? this.manualSuccess,
      estimatedStudyHours: estimatedStudyHours ?? this.estimatedStudyHours,
      recommendedDays: recommendedDays ?? this.recommendedDays,
      repeatStudyHours: repeatStudyHours ?? this.repeatStudyHours,
      questionSolveHours: questionSolveHours ?? this.questionSolveHours,
      inCoursePrerequisite: inCoursePrerequisite ?? this.inCoursePrerequisite,
      outOfCoursePrerequisite:
          outOfCoursePrerequisite ?? this.outOfCoursePrerequisite,
      lastTestScore: lastTestScore ?? this.lastTestScore,
      placementCount: placementCount ?? this.placementCount,
      columnId: columnId ?? this.columnId,
      completedDays: completedDays ?? this.completedDays,
    );
    updated.assignedDays = List<int>.from(assignedDays ?? this.assignedDays);
    return updated;
  }

  static double _toDoubleOrDefault(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  factory StudySubject.fromJson(Map<String, dynamic> json) {
    final estimated = (json['estimatedStudyHours'] is num)
        ? (json['estimatedStudyHours'] as num).toInt()
        : int.tryParse(json['estimatedStudyHours']?.toString() ?? '4') ?? 4;
    final defaultHours = estimated.toDouble();

    return StudySubject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      programOrder: (json['programOrder'] is num)
          ? (json['programOrder'] as num).toInt()
          : int.tryParse(json['programOrder']?.toString() ?? '9999') ?? 9999,
      opticalSuccess: _toDoubleOrDefault(json['opticalSuccess'], 0),
      manualSuccess: _toDoubleOrDefault(json['manualSuccess'], 0),
      estimatedStudyHours: estimated,
      recommendedDays: (json['recommendedDays'] is num)
          ? (json['recommendedDays'] as num).toInt()
          : int.tryParse(json['recommendedDays']?.toString() ?? '1') ?? 1,
      repeatStudyHours: _toDoubleOrDefault(
        json['tekrar_calisma_saati'],
        defaultHours,
      ),
      questionSolveHours: _toDoubleOrDefault(
        json['soru_cozme_saati'],
        defaultHours,
      ),
      inCoursePrerequisite: json['ders_ici_on_kosul']?.toString(),
      outOfCoursePrerequisite: json['ders_disi_on_kosul']?.toString(),
      lastTestScore: json['lastTestScore'] == null
          ? null
          : _toDoubleOrDefault(json['lastTestScore'], 0),
      placementCount: (json['placementCount'] is num)
          ? (json['placementCount'] as num).toInt()
          : int.tryParse(json['placementCount']?.toString() ?? '0') ?? 0,
      columnId: json['columnId']?.toString() ?? 'column-1',
        completedDays: (json['completedDays'] as List<dynamic>? ?? const [])
          .map((day) => day is num ? day.toInt() : int.tryParse(day.toString()) ?? 0)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'courseName': courseName,
      'programOrder': programOrder,
      'opticalSuccess': opticalSuccess,
      'manualSuccess': manualSuccess,
      'estimatedStudyHours': estimatedStudyHours,
      'recommendedDays': recommendedDays,
      'tekrar_calisma_saati': repeatStudyHours,
      'soru_cozme_saati': questionSolveHours,
      'ders_ici_on_kosul': inCoursePrerequisite,
      'ders_disi_on_kosul': outOfCoursePrerequisite,
      'lastTestScore': lastTestScore,
      'placementCount': placementCount,
      'columnId': columnId,
      'completedDays': completedDays,
    };
  }

  double get safeScore => ((opticalSuccess * 0.70) + (manualSuccess * 0.30));

  double get effectiveScore {
    final last = lastTestScore ?? opticalSuccess;
    final accelerationThreshold = safeScore * 1.15;
    return last > accelerationThreshold ? last : safeScore;
  }
}