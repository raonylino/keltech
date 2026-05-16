import 'package:desafio/scr/controlers/auth_controller.dart';
import 'package:desafio/scr/controlers/get_documents_controller.dart';
import 'package:desafio/scr/controlers/post_documents_controller.dart';
import 'package:desafio/scr/views/auth/email_verification_page.dart';
import 'package:desafio/scr/views/auth/login_page.dart';
import 'package:desafio/scr/views/dashboard/dashboard_page.dart';
import 'package:desafio/scr/views/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesafioApp extends StatelessWidget {
  const DesafioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthController>(create: (_) => AuthController()),
        BlocProvider<PostDocumentsController>(
          create: (_) => PostDocumentsController(),
        ),
        BlocProvider<GetDocumentsController>(
          create: (_) => GetDocumentsController(),
        ),
      ],
      child: MaterialApp(
        title: 'Desafio App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthController, AuthState>(
          builder: (context, state) {
            if (state.status == AuthStatus.initial) {
              return const _SplashScreen();
            }
            if (state.status == AuthStatus.emailNotVerified) {
              return const EmailVerificationPage();
            }
            if (state.isAuthenticated) {
              return const MainShell();
            }
            return const LoginPage();
          },
        ),
        routes: {'/dashboard': (context) => const DashboardPage()},
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F766E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
