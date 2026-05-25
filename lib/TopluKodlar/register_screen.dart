import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _institutionCodeController = TextEditingController();
  
  String _selectedRole = 'ogrenci'; // Varsayılan rol

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _institutionCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().signUp(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              role: _selectedRole,
              institutionCode: _institutionCodeController.text.trim(),
            );
        
        if (mounted) {
          // Kayıt başarılıysa kullanıcıyı bilgilendir ve Login'e geri at
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarılı! Lütfen giriş yapın (Hesabınızın onaylanması gerekebilir).'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kayıt başarısız: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0, right: 24.0, top: 24.0, bottom: bottomPadding + 24.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 64, color: Colors.blueAccent),
                const SizedBox(height: 24),
                
                // Ad Soyad
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Ad Soyad boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                // E-posta
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'E-posta boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                // Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Şifre (En az 6 karakter)', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                  validator: (value) => value!.length < 6 ? 'Şifre çok kısa' : null,
                ),
                const SizedBox(height: 16),

                // Rol Seçimi (Dropdown)
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Hesap Türü', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ogrenci', child: Text('Öğrenci')),
                    DropdownMenuItem(value: 'kurum', child: Text('Kurum / Koç')),
                    DropdownMenuItem(value: 'admin', child: Text('Sistem Admini')),
                  ],
                  onChanged: (value) {
                    setState(() { _selectedRole = value!; });
                  },
                ),
                const SizedBox(height: 16),

                // Kurum Kodu
                TextFormField(
                  controller: _institutionCodeController,
                  decoration: const InputDecoration(labelText: 'Kurum Kodu (Örn: DSTEK-1)', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Kurum kodu boş olamaz' : null,
                ),
                const SizedBox(height: 24),

                // Kayıt Ol Butonu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}