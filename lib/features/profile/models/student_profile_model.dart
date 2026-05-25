class StudentProfileModel {
  final String uid;
  final String fullName;
  final String studentPhone;
  final String parentName;
  final String parentPhone;
  final String city;
  final String district;
  final String schoolName;
  final String educationLevel;
  final String targetExam;
  final String? targetField;
  final double? firstDiagnosticNet;
  final String? targetRanking;

  StudentProfileModel({
    required this.uid,
    required this.fullName,
    this.studentPhone = '',
    this.parentName = '',
    this.parentPhone = '',
    this.city = '',
    this.district = '',
    this.schoolName = '',
    this.educationLevel = '',
    this.targetExam = '',
    this.targetField,
    this.firstDiagnosticNet,
    this.targetRanking,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'studentPhone': studentPhone,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'city': city,
      'district': district,
      'schoolName': schoolName,
      'educationLevel': educationLevel,
      'targetExam': targetExam,
      'targetField': targetField,
      'firstDiagnosticNet': firstDiagnosticNet,
      'targetRanking': targetRanking,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory StudentProfileModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentProfileModel(
      uid: documentId,
      fullName: map['fullName'] ?? '',
      studentPhone: map['studentPhone'] ?? '',
      parentName: map['parentName'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      schoolName: map['schoolName'] ?? '',
      educationLevel: map['educationLevel'] ?? '',
      targetExam: map['targetExam'] ?? '',
      targetField: map['targetField'],
      firstDiagnosticNet: map['firstDiagnosticNet']?.toDouble(),
      targetRanking: map['targetRanking'],
    );
  }
}