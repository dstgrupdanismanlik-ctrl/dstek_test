import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String kurumKodu;
  final String adSoyad;
  final String kullaniciAdi;
  final String ePosta;
  final String telefonNumarasi;
  final String rol;
  final bool isActive;
  final bool kvkkOnayDurumu;
  final DateTime kayitTarihi;

  UserModel({
    required this.uid,
    required this.kurumKodu,
    required this.adSoyad,
    required this.kullaniciAdi,
    required this.ePosta,
    required this.telefonNumarasi,
    required this.rol,
    this.isActive = true,
    this.kvkkOnayDurumu = false,
    required this.kayitTarihi,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      kurumKodu: data['kurum_kodu'] ?? '',
      adSoyad: data['ad_soyad'] ?? '',
      kullaniciAdi: data['kullanici_adi'] ?? '',
      ePosta: data['e_posta'] ?? '',
      telefonNumarasi: data['telefon_numarasi'] ?? '',
      rol: data['rol'] ?? 'ogrenci',
      isActive: data['is_active'] ?? false,
      kvkkOnayDurumu: data['kvkk_onay_durumu'] ?? false,
      kayitTarihi:
          (data['kayit_tarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'kurum_kodu': kurumKodu,
      'ad_soyad': adSoyad,
      'kullanici_adi': kullaniciAdi,
      'e_posta': ePosta,
      'telefon_numarasi': telefonNumarasi,
      'rol': rol,
      'is_active': isActive,
      'kvkk_onay_durumu': kvkkOnayDurumu,
      'kayit_tarihi': Timestamp.fromDate(kayitTarihi),
    };
  }
}