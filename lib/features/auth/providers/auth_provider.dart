import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dstek/features/auth/models/user_model.dart';
import 'package:dstek/features/profile/models/student_profile_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? get currentUser => _auth.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String kullaniciAdi,
    required String telefonNumarasi,
    required String kurumKodu,
    required String rol,
  }) async {
    try {
      _setLoading(true);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userModel = UserModel(
        uid: uid,
        kurumKodu: kurumKodu,
        adSoyad: name,
        kullaniciAdi: kullaniciAdi,
        ePosta: email,
        telefonNumarasi: telefonNumarasi,
        rol: rol,
        kayitTarihi: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      if (rol == 'ogrenci') {
        final studentProfile = StudentProfileModel(
          kurumKodu: kurumKodu,
          ogrenciId: uid,
          koclukBaslangicTarihi: DateTime.now(),
        );

        await _firestore
            .collection('student_profiles')
            .doc(uid)
            .set(studentProfile.toMap());
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}