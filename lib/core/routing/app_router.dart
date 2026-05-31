import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/academic_study_room_screen.dart';
import '../../screens/study_program_screen.dart';
import '../../core/init/app_initializer.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../shared/widgets/main_shell.dart';

/// Uygulamanın yönlendirme (routing) yapılandırması.
///
/// Mimari:
/// - Auth rotaları (/, /login, /register) doğrudan kök seviyede yer alır.
/// - Ana uygulama rotaları (/home, /study-program, /academic-study-room)
///   bir [ShellRoute] içinde gruplandırılmıştır. Bu sayede bu ekranlar
///   aynı "kabuk"un (sandviç menü + uygulama kabuğu) parçası olarak
///   değerlendirilir ve context.go() ile geçiş yapıldığında yeni bir
///   navigation stack oluşturulmaz.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Auth rotaları (kabuk dışı) ---
    GoRoute(
      path: '/',
      builder: (context, state) => const AppInitializer(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // --- Ana uygulama kabuğu (ShellRoute) ---
    // Tüm bu rotalar aynı navigasyon grubundadır.
    // context.go() kullanıldığında stack temizlenir ve kabuk korunur.
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/study-program',
          builder: (context, state) => const StudyProgramScreen(),
        ),
        GoRoute(
          path: '/academic-study-room',
          builder: (context, state) => const AcademicStudyRoomScreen(),
        ),
      ],
    ),
  ],
);