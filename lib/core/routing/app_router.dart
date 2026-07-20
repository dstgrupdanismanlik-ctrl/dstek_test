import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dstek/features/academic_room/screens/academic_study_room_screen.dart';
import 'package:dstek/features/study_program/screens/study_program_screen.dart';
import 'package:dstek/core/init/app_initializer.dart';
import 'package:dstek/features/auth/screens/login_screen.dart';
import 'package:dstek/features/auth/screens/register_screen.dart';
import 'package:dstek/features/home/screens/home_screen.dart';
import 'package:dstek/shared/widgets/main_shell.dart';
import 'package:dstek/features/profile/screens/profile_screen.dart';
import 'package:dstek/features/exams/screens/exam_entry_screen.dart';
import 'package:dstek/features/guidance_counseling/screens/guidance_counseling_screen.dart';
import 'package:dstek/features/inventory_system/inventory_system_screen.dart';
import 'package:dstek/features/admin/screens/admin_settings_screen.dart';
import 'package:dstek/features/study_program/screens/analysis_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
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
          path: '/analysis',
          builder: (context, state) => const AnalysisScreen(),
        ),
        GoRoute(
          path: '/academic-study-room',
          builder: (context, state) => const AcademicStudyRoomScreen(),
        ),
        GoRoute(
          path: '/exams',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'];
            final examMode = mode == 'deneme' ? ExamMode.deneme : ExamMode.test;
            return ExamEntryScreen(mode: examMode);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/guidance-counseling',
          builder: (context, state) => GuidanceCounselingScreen(),
        ),
        GoRoute(
          path: '/inventory-system',
          builder: (context, state) => InventorySystemScreen(),
        ),
        GoRoute(
          path: '/admin-settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
      ],
    ),
  ],
);