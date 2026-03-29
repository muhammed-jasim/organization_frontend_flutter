import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  // Currently mock state. In a real app, bind this to a ThemeProvider + SharedPreferences
  bool _isDarkMode = false;
  String _selectedColor = 'Blue';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text("Theme Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildThemeOption(
            title: "Light Mode",
            icon: Icons.light_mode_outlined,
            isSelected: !_isDarkMode,
            onTap: () {
              setState(() => _isDarkMode = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Light mode selected.")));
            },
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            title: "Dark Mode",
            icon: Icons.dark_mode_outlined,
            isSelected: _isDarkMode,
            onTap: () {
              setState(() => _isDarkMode = true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dark mode selected.")));
            },
          ),
          const SizedBox(height: 32),
          const Text("Primary Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildColorOption('Blue', Colors.blue, _selectedColor == 'Blue'),
              _buildColorOption('Teal', Colors.teal, _selectedColor == 'Teal'),
              _buildColorOption('Orange', Colors.orange, _selectedColor == 'Orange'),
              _buildColorOption('Purple', Colors.purple, _selectedColor == 'Purple'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String name, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedColor = name);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: AppColors.textPrimary, width: 3) : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
