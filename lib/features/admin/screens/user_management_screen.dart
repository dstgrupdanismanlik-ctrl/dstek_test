import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _institutionCodeController = TextEditingController();

  String _selectedRole = 'ogrenci';
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _institutionCodeController.dispose();
    super.dispose();
  }

  String _normalizeRole(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final currentRole = _normalizeRole(authProvider.currentUserData?['role']);
    final isAdmin = currentRole == 'admin' || currentRole == 'yönetici';
    final isKoc = currentRole == 'koc' || currentRole == 'koç';
    final selectedRole = isKoc ? 'ogrenci' : _selectedRole;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final institutionCode = _institutionCodeController.text.trim();

    FirebaseApp? secondaryApp;

    setState(() {
      _isSaving = true;
    });

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'Secondary',
        options: Firebase.app().options,
      );

      final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Kullanıcı oluşturulamadı.',
        );
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'institutionCode': institutionCode,
        'role': selectedRole,
        'isActive': true,
      });

      if (selectedRole == 'ogrenci') {
        await firestore.collection('student_profiles').doc(uid).set({
          'studentId': uid,
          'institutionCode': institutionCode,
        });
      }

      if (!mounted) {
        return;
      }

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      if (isAdmin) {
        _institutionCodeController.clear();
        _selectedRole = 'ogrenci';
      } else if (isKoc) {
        _selectedRole = 'ogrenci';
      }

      _showSnackBar('Kullanıcı başarıyla kaydedildi.', Colors.green);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showSnackBar(
          error.message ?? 'Kullanıcı kaydedilemedi.',
          Colors.red,
        );
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          'Kullanıcı kaydedilemedi: $error',
          Colors.red,
        );
      }
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentRole = _normalizeRole(authProvider.currentUserData?['role']);
    final isAdmin = currentRole == 'admin' || currentRole == 'yönetici';
    final isKoc = currentRole == 'koc' || currentRole == 'koç';
    final canEditInstitutionCode = true;
    final List<DropdownMenuItem<String>> roleItems = isKoc
        ? [
            const DropdownMenuItem<String>(
              value: 'ogrenci',
              child: Text('Öğrenci'),
            ),
          ]
        : [
            const DropdownMenuItem<String>(
              value: 'ogrenci',
              child: Text('Öğrenci'),
            ),
            if (isAdmin)
              const DropdownMenuItem<String>(
                value: 'koc',
                child: Text('Koç'),
              ),
            if (isAdmin)
              const DropdownMenuItem<String>(
                value: 'admin',
                child: Text('Admin'),
              ),
          ];

    if (isKoc && _selectedRole != 'ogrenci') {
      _selectedRole = 'ogrenci';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı İşlemleri')),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sisteme Kullanıcı Ekle',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isKoc
                              ? 'Koç hesabı için kurum kodu ve rol seçimi sistem tarafından sınırlandırılmıştır.'
                              : 'Admin hesabı kullanıcı oluştururken kurum kodu ve rol seçimini yönetebilir.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad Soyad boş bırakılamaz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-Posta',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'E-Posta zorunludur';
                            }
                            if (!value.contains('@')) {
                              return 'Geçerli bir E-Posta girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Giriş Şifresi',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Giriş şifresi zorunludur';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _institutionCodeController,
                          enabled: canEditInstitutionCode,
                          decoration: InputDecoration(
                            labelText: 'Kurum Kodu',
                            prefixIcon: const Icon(Icons.apartment_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Kurum kodu zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Rol Seçimi',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: roleItems,
                          onChanged: isKoc
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Rol seçimi zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: const Icon(Icons.save_outlined),
                            label: _isSaving
                                ? const Text('Kaydediliyor...')
                                : const Text('Kullanıcıyı Kaydet'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}