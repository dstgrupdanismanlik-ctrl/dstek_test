import 'package:go_router/go_router.dart';
import '../../screens/academic_study_room_screen.dart';
import '../../screens/study_program_screen.dart';
import '../../core/init/app_initializer.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart'; // Yeni ekran eklendi
import '../../features/home/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppInitializer(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register', // Yeni Rota
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/academic-study-room',
      builder: (context, state) => const AcademicStudyRoomScreen(),
    ),
    GoRoute(
      path: '/study-program',
      builder: (context, state) => const StudyProgramScreen(),
    ),
  ],
);