import 'package:flutter/material.dart';
import 'package:organization_frontend_app/dashboard/pages/quick_menu_page.dart';
import 'package:organization_frontend_app/employee/pages/employee_list_page.dart';
import 'package:organization_frontend_app/settings/pages/settings_page.dart';
import 'package:organization_frontend_app/equipment/pages/equipment_list_page.dart';
import '../../theme/app_theme.dart';
import 'dashboard_page.dart';
import '../../site/pages/site_list_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(
        onViewAllManagement: () => setState(() => _currentIndex = 2),
        onViewAllSites: () => setState(() => _currentIndex = 1),
      ),
      const SiteListPage(),
      QuickMenuPage(onNavigateToTab: (index) {
        setState(() => _currentIndex = index);
      }),
      const EmployeeListPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted.withValues(alpha: 0.6),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            elevation: 0,
            items: [
              _buildBarItem(Icons.grid_view_rounded, 'Home'),
              _buildBarItem(Icons.architecture_rounded, 'Sites'),
              _buildBarItem(Icons.apps_rounded, 'Menu'),
              _buildBarItem(Icons.groups_rounded, 'Employees'),
              _buildBarItem(Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBarItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon), activeIcon: Icon(icon, color: AppColors.primary), label: label);
  }


}
