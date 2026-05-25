import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/models/student_profile_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Arayüzün aradığı Yükleniyor durumu (Dönen çark için)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? get currentUser => _auth.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Kayıt Ol (Arayüz signUp olarak arıyor)
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String institutionCode,
  }) async {
    try {
      _setLoading(true);
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 1. Ana Kimlik Kartı (users tablosu)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'institutionCode': institutionCode,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. Öğrenciyse Detaylı Profil Aç (student_profiles tablosu)
      if (role == 'Öğrenci') {
        StudentProfileModel newStudentProfile = StudentProfileModel(
          uid: userCredential.user!.uid,
          fullName: name,
        );
        
        await _firestore.collection('student_profiles')
            .doc(userCredential.user!.uid)
            .set(newStudentProfile.toMap());
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Giriş Yap (Arayüz signIn olarak arıyor)
  Future<void> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}