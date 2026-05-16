import 'package:desafio/scr/controlers/auth_controller.dart';
import 'package:desafio/scr/views/dashboard/dashboard_page.dart';
import 'package:desafio/scr/views/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _pages = [HomePage(), DashboardPage()];

  void _onTabChange(int index) {
    if (index == 2) {
      _showLogoutDialog();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sair do aplicativo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF134E4A),
          ),
        ),
        content: const Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthController>().signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GNav(
              rippleColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
              hoverColor: const Color(0xFF0F766E).withValues(alpha: 0.08),
              gap: 8,
              activeColor: Colors.white,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              duration: const Duration(milliseconds: 350),
              tabBackgroundColor: const Color(0xFF0F766E),
              color: const Color(0xFF6B7280),
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
              tabs: const [
                GButton(icon: Icons.upload_file_rounded, text: 'Enviar'),
                GButton(icon: Icons.description_rounded, text: 'Documentos'),
                GButton(icon: Icons.logout_rounded, text: 'Sair'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
