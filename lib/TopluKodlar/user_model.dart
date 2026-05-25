class UserModel {
  final String uid; // Kullanici_Kimligi
  final String name; // Ad_Soyad
  final String email; // E_Posta
  final String role; // Rol: 'ogrenci', 'kurum', 'admin'
  final String institutionCode; // Kurum_Kodu
  final bool isActive; // Hesap_Aktif_Mi
  final DateTime? kvkkApprovalDate; // KVKK_Onay_Tarihi

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.institutionCode,
    required this.isActive,
    this.kvkkApprovalDate,
  });

  // Veritabanından (Firestore) gelen veriyi Flutter objesine çevirir
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'ogrenci', // Varsayılan rol öğrenci
      institutionCode: json['institutionCode'] ?? '',
      isActive: json['isActive'] ?? false, // Yeni kayıtlar varsayılan olarak pasif başlar
      kvkkApprovalDate: json['kvkkApprovalDate'] != null
          ? DateTime.parse(json['kvkkApprovalDate'])
          : null,
    );
  }

  // Flutter objesini veritabanına (Firestore) yazmak için formata çevirir
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'institutionCode': institutionCode,
      'isActive': isActive,
      'kvkkApprovalDate': kvkkApprovalDate?.toIso8601String(),
    };
  }
}