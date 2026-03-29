import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Global search delegate for the dashboard.
/// Add items to [_allItems] as new modules are implemented.
class DashboardSearchDelegate extends SearchDelegate<String> {
  final List<_SearchItem> _allItems = [
    _SearchItem(title: 'Vehicles', subtitle: 'Manage your fleet', icon: Icons.directions_car_rounded, route: '/vehicles'),
    _SearchItem(title: 'Warehouses', subtitle: 'View & edit warehouses', icon: Icons.warehouse_rounded, route: '/warehouses'),
    _SearchItem(title: 'Organization Settings', subtitle: 'Edit your organization', icon: Icons.business_rounded, route: '/settings/organization'),
    _SearchItem(title: 'Profile Settings', subtitle: 'Update your profile', icon: Icons.person_rounded, route: '/settings/profile'),
    _SearchItem(title: 'Security', subtitle: 'Change password', icon: Icons.lock_rounded, route: '/settings/security'),
    _SearchItem(title: 'Notifications', subtitle: 'View alerts', icon: Icons.notifications_rounded, route: '/notifications'),
    _SearchItem(title: 'Appearance', subtitle: 'Theme and colors', icon: Icons.palette_rounded, route: '/settings/appearance'),
  ];

  @override
  String get searchFieldLabel => 'Search anything...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = query.isEmpty
        ? _allItems
        : _allItems.where((item) {
            final q = query.toLowerCase();
            return item.title.toLowerCase().contains(q) || item.subtitle.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No results for "$query"', style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = filtered[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              close(context, item.route);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  _SearchItem({required this.title, required this.subtitle, required this.icon, required this.route});
}
