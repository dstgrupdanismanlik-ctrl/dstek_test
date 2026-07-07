import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Arayüz Değişkenleri
  String _selectedRole = 'ogrenci'; // ogrenci, koc, admin
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _kvkkAccepted = false;

  // Kontrolcüler (Email yerine arayüze uygun olarak identifier ismini kullandık)
  final TextEditingController _kurumKoduController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _kurumKoduController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // KVKK Onay Kontrolü
      if (!_kvkkAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sisteme giriş yapmak için KVKK metnini onaylamalısınız.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      try {
        // Şu anki AuthProvider email beklediği için identifier verisini oraya paslıyoruz.
        await context.read<AuthProvider>().signIn(
              email: _identifierController.text.trim(),
              password: _passwordController.text.trim(),
            );
            
        // Giriş başarılıysa ana sayfaya geç!
        if (mounted) {
          context.go('/'); 
        }
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auth sağlayıcısından yüklenme durumunu dinliyoruz
    final isLoading = context.watch<AuthProvider>().isLoading;
    final Color backgroundColor = const Color(0xFFF5F7FA); 

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo ve Başlık Alanı
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'DSTEK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'LÜTFEN GİRİŞ YAPIN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Form Kartı
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- Rol Seçimi (Radio Buttons) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildRadioOption('Öğrenci', 'ogrenci'),
                              _buildRadioOption('Koç', 'koc'),
                              _buildRadioOption('Admin', 'admin'),
                            ],
                          ),
                          const Divider(height: 32),

                          // --- Kurum Kodu ---
                          TextFormField(
                            controller: _kurumKoduController,
                            decoration: InputDecoration(
                              labelText: 'Kurum Kodu (Örn: 16GUR...)',
                              prefixIcon: const Icon(Icons.domain),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Kurum kodu boş bırakılamaz' : null,
                          ),
                          const SizedBox(height: 16),

                          // --- Kullanıcı Adı / Öğrenci Numarası / E-Posta ---
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: _selectedRole == 'ogrenci' ? 'E-Posta / Öğrenci No' : 'E-Posta / Kullanıcı Adı',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                          ),
                          const SizedBox(height: 16),

                          // --- Şifre ---
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Şifre boş bırakılamaz' : null,
                          ),
                          const SizedBox(height: 16),

                          // --- Beni Hatırla ---
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Beni Hatırla',
                                style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // --- KVKK Onay Kutusu ---
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9D2),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                left: BorderSide(color: Colors.amber, width: 4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _kvkkAccepted,
                                    activeColor: Colors.orange,
                                    onChanged: (val) {
                                      setState(() {
                                        _kvkkAccepted = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Verilerimin okul iklimini geliştirmek üzere KVKK kapsamında işlenmesini ve tüm hukuki sorumluluğu kabul ediyorum.',
                                    style: TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- Sistemi Başlat Butonu ---
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF27AE60),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Sistemi Başlat',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // --- Kayıt Ol Bağlantısı ---
                          TextButton(
                            onPressed: isLoading ? null : () => context.push('/register'),
                            child: const Text('Hesabın yok mu? Kayıt Ol'),
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
      ),
    );
  }

  // Arayüzü temiz tutmak için yardımcı Radio Button metodu
  Widget _buildRadioOption(String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedRole,
          activeColor: Colors.blueAccent,
          onChanged: (String? newValue) {
            setState(() {
              _selectedRole = newValue!;
            });
          },
        ),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}