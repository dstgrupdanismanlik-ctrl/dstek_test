import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Provider paketini içe aktardık
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'features/auth/providers/auth_provider.dart'; // Yazdığımız sınıf

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // MultiProvider ile uygulamamızı sarmalıyoruz ki ileride yeni provider'lar ekleyebilelim
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const DstekApp(),
    ),
  );
}

class DstekApp extends StatelessWidget {
  const DstekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DSTEK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}