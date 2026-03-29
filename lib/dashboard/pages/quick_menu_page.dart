import 'package:flutter/material.dart';
import 'package:organization_frontend_app/settings/pages/settings_page.dart';
import 'package:organization_frontend_app/warehouse/pages/warehouse_list_page.dart';
import 'package:organization_frontend_app/site/pages/site_create_page.dart';
import 'package:organization_frontend_app/employee/pages/employee_create_page.dart';
import 'package:organization_frontend_app/client/pages/client_list_page.dart';
import '../../vehicle/pages/vehicle_list_page.dart';
import '../../subcontractor/pages/subcontractor_list_page.dart';
import '../../material/pages/material_list_page.dart';
import '../../finance/pages/finance_dashboard_page.dart';
import '../../finance/pages/transaction_form_page.dart';
import '../../vendor/pages/vendor_list_page.dart';
import '../../equipment/pages/equipment_list_page.dart';
import '../../theme/app_theme.dart';

class QuickMenuPage extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const QuickMenuPage({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          /// ───────────── Modern Header ─────────────
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            title: Text(
              "Quick Access",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          /// ───────────── Content ─────────────
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                /// Navigation Grid
                const _SectionHeader(title: "Main Navigation"),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _QuickMenuIcon(
                          icon: Icons.grid_view_rounded,
                          label: "Home",
                          onTap: () => onNavigateToTab(0),
                        ),
                        _QuickMenuIcon(
                          icon: Icons.architecture_rounded,
                          label: "Sites",
                          onTap: () => onNavigateToTab(1),
                        ),
                        _QuickMenuIcon(
                          icon: Icons.groups_rounded,
                          label: "Employees",
                          onTap: () => onNavigateToTab(3),
                        ),
                        _QuickMenuIcon(
                          icon: Icons.construction_rounded,
                          label: "Gear",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EquipmentListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.warehouse_rounded,
                          label: "Warehouse",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const WarehouseListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.local_shipping_rounded,
                          label: "Vehicles",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.people_alt_rounded,
                          label: "Clients",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.handshake_rounded,
                          label: "Subcon",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SubcontractorListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.storefront_rounded,
                          label: "Vendors",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.inventory_2_rounded,
                          label: "Materials",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const MaterialListPage()));
                          },
                        ),
                        _QuickMenuIcon(
                          icon: Icons.account_balance_wallet_rounded,
                          label: "Finance",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FinanceDashboardPage()));
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                /// Projects & People Bento
                const _SectionHeader(title: "Projects & People"),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _GridBentoShortcut(
                      icon: Icons.add_business_rounded,
                      title: "New Project",
                      subtitle: "Register site",
                      color: AppColors.primary.withValues(alpha: 0.05),
                      iconColor: AppColors.primary,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SiteCreatePage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.person_add_alt_1_rounded,
                      title: "Create Employee",
                      subtitle: "Add new staff",
                      color: Colors.teal.withValues(alpha: 0.05),
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeCreatePage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.people_alt_rounded,
                      title: "Clients",
                      subtitle: "Manage clients",
                      color: Colors.brown.withValues(alpha: 0.05),
                      iconColor: Colors.brown,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientListPage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.handshake_rounded,
                      title: "Subcontractors",
                      subtitle: "External teams",
                      color: AppColors.accent.withValues(alpha: 0.05),
                      iconColor: AppColors.accent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SubcontractorListPage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.storefront_rounded,
                      title: "Vendors",
                      subtitle: "Manage vendors",
                      color: Colors.deepPurple.withValues(alpha: 0.05),
                      iconColor: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorListPage()));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// Assets & Logistics Bento
                const _SectionHeader(title: "Assets & Logistics"),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _GridBentoShortcut(
                      icon: Icons.assignment_rounded,
                      title: "Equipment",
                      subtitle: "Audit machinery",
                      color: Colors.amber.withValues(alpha: 0.05),
                      iconColor: Colors.amber,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EquipmentListPage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.warehouse_rounded,
                      title: "Warehouses",
                      subtitle: "Inventory hubs",
                      color: Colors.indigo.withValues(alpha: 0.05),
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WarehouseListPage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.local_shipping_rounded,
                      title: "Vehicles",
                      subtitle: "Company fleet",
                      color: AppColors.primary.withValues(alpha: 0.05),
                      iconColor: AppColors.primary,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleListPage()));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.inventory_2_rounded,
                      title: "Materials",
                      subtitle: "Manage inventory",
                      color: AppColors.warning.withValues(alpha: 0.05),
                      iconColor: AppColors.warning,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MaterialListPage()));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// Finance & Reports
                const _SectionHeader(title: "Finance & Reports"),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _GridBentoShortcut(
                      icon: Icons.add_card_rounded,
                      title: "Payment",
                      subtitle: "Record outgoing",
                      color: AppColors.error.withValues(alpha: 0.05),
                      iconColor: AppColors.error,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormPage(isPayment: true)));
                      },
                    ),
                    _GridBentoShortcut(
                      icon: Icons.receipt_long_rounded,
                      title: "Receipt",
                      subtitle: "Record incoming",
                      color: AppColors.success.withValues(alpha: 0.05),
                      iconColor: AppColors.success,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormPage(isPayment: false)));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _UtilityTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: "Finance Dashboard",
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceDashboardPage()));
                        },
                      ),
                      Divider(height: 1, color: AppColors.textMuted.withValues(alpha: 0.05), indent: 56),
                      _UtilityTile(
                        icon: Icons.analytics_rounded,
                        title: "Profit & Loss Reports",
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceDashboardPage()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _QuickMenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickMenuIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBentoShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _GridBentoShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1222).withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _UtilityTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
      ),
      trailing: Icon(Icons.north_east_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
