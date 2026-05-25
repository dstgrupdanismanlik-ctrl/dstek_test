import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeSystemConstants(BuildContext context) async {
    try {
      // 1. PROFIL SEÇENEKLERİ (T-1 Genel Tanım Tablosundan)
      final profileOptionsRef = _firestore.collection('system_constants').doc('profile_options');

      final profileData = {
        'cities': {
          'Adana': ['Aladağ', 'Ceyhan', 'Çukurova', 'Seyhan', 'Yüreğir'],
          'Ankara': ['Çankaya', 'Etimesgut', 'Keçiören', 'Mamak', 'Yenimahalle'],
          'Bursa': ['Gemlik', 'Mudanya', 'Nilüfer', 'Osmangazi', 'Yıldırım'],
          'İstanbul': ['Beşiktaş', 'Kadıköy', 'Maltepe', 'Şişli', 'Üsküdar'],
          'İzmir': ['Bornova', 'Buca', 'Çiğli', 'Karşıyaka', 'Konak'],
          // Not: 81 ilin tamamı kolayca buraya eklenebilir, test için en yoğun iller eklendi.
        },
        'education_levels': [
          'Okul Öncesi',
          'İlkokul 1. Sınıf', 'İlkokul 2. Sınıf', 'İlkokul 3. Sınıf', 'İlkokul 4. Sınıf',
          'Ortaokul 5. Sınıf', 'Ortaokul 6. Sınıf', 'Ortaokul 7. Sınıf', 'Ortaokul 8. Sınıf',
          'Lise 9. Sınıf', 'Lise 10. Sınıf', 'Lise 11. Sınıf', 'Lise 12. Sınıf',
          'Mezun', 'Önlisans', 'Lisans', 'Yüksek Lisans'
        ],
        'exams': [
          'YKS', 'LGS', 'KPSS', 'ALES', 'YDS', 'BİLSEM', 'IB', 'Sınava Hazırlanmıyorum'
        ]
      };

      await profileOptionsRef.set(profileData);

      // 2. SINAV-SINIF-ALAN HİYERARŞİSİ (Açılır menülerin birbirini tetiklemesi için)
      final examMatrixRef = _firestore.collection('system_constants').doc('exam_matrix');
      final examMatrixData = {
        'YKS': {
          'allowed_grades': ['Lise 9. Sınıf', 'Lise 10. Sınıf', 'Lise 11. Sınıf', 'Lise 12. Sınıf', 'Mezun'],
          'fields': ['SAY (MF)', 'EA (TM)', 'SÖZ (TS)', 'DİL', 'Alan Yok']
        },
        'LGS': {
          'allowed_grades': ['Ortaokul 5. Sınıf', 'Ortaokul 6. Sınıf', 'Ortaokul 7. Sınıf', 'Ortaokul 8. Sınıf'],
          'fields': ['Alan Yok']
        },
        'KPSS': {
          'allowed_grades': ['Önlisans', 'Lisans', 'Mezun'],
          'fields': ['Genel Kültür - Genel Yetenek', 'Eğitim Bilimleri', 'ÖABT', 'Alan Yok']
        }
      };

      await examMatrixRef.set(examMatrixData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('T-1 Sabitleri ve Sınav Matrisi Firestore\'a başarıyla yüklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme Hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}