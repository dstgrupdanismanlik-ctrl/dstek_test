import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileModel {
  final String kurumKodu;
  final String ogrenciId;
  final String veliAdi;
  final String veliTelefon;
  final String sehir;
  final String dogumTarihi;
  final String ogrenimDurumu;
  final String hazirlanilanSinav;
  final String alan;
  final String paketTuru;
  final bool kunduzAktifMi;
  final Map<String, dynamic> ilkBasariNetleri;
  final Map<String, dynamic> hedefNetler;
  final Map<String, dynamic> koclukBaremleri;
  final DateTime koclukBaslangicTarihi;

  StudentProfileModel({
    required this.kurumKodu,
    required this.ogrenciId,
    this.veliAdi = '',
    this.veliTelefon = '',
    this.sehir = '',
    this.dogumTarihi = '',
    this.ogrenimDurumu = '',
    this.hazirlanilanSinav = '',
    this.alan = '',
    this.paketTuru = '',
    this.kunduzAktifMi = false,
    this.ilkBasariNetleri = const {},
    this.hedefNetler = const {},
    this.koclukBaremleri = const {},
    required this.koclukBaslangicTarihi,
  });

  factory StudentProfileModel.fromMap(Map<String, dynamic> data) {
    return StudentProfileModel(
      kurumKodu: data['kurum_kodu'] ?? '',
      ogrenciId: data['ogrenci_id'] ?? '',
      veliAdi: data['veli_adi'] ?? '',
      veliTelefon: data['veli_telefon'] ?? '',
      sehir: data['sehir'] ?? '',
      dogumTarihi: data['dogum_tarihi'] ?? '',
      ogrenimDurumu: data['ogrenim_durumu'] ?? '',
      hazirlanilanSinav: data['hazirlanilan_sinav'] ?? '',
      alan: data['alan'] ?? '',
      paketTuru: data['paket_turu'] ?? '',
      kunduzAktifMi: data['kunduz_aktif_mi'] ?? false,
      ilkBasariNetleri: Map<String, dynamic>.from(
        data['ilk_basari_netleri'] ?? {},
      ),
      hedefNetler: Map<String, dynamic>.from(data['hedef_netler'] ?? {}),
      koclukBaremleri: Map<String, dynamic>.from(
        data['kocluk_baremleri'] ?? {},
      ),
      koclukBaslangicTarihi:
          (data['kocluk_baslangic_tarihi'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kurum_kodu': kurumKodu,
      'ogrenci_id': ogrenciId,
      'veli_adi': veliAdi,
      'veli_telefon': veliTelefon,
      'sehir': sehir,
      'dogum_tarihi': dogumTarihi,
      'ogrenim_durumu': ogrenimDurumu,
      'hazirlanilan_sinav': hazirlanilanSinav,
      'alan': alan,
      'paket_turu': paketTuru,
      'kunduz_aktif_mi': kunduzAktifMi,
      'ilk_basari_netleri': ilkBasariNetleri,
      'hedef_netler': hedefNetler,
      'kocluk_baremleri': koclukBaremleri,
      'kocluk_baslangic_tarihi': Timestamp.fromDate(koclukBaslangicTarihi),
    };
  }
}