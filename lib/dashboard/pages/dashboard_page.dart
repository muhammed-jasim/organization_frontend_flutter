import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../auth/services/token_manager.dart';
import '../../organization/services/organization_service.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/pages/organization_create_page.dart';
import '../../notifications/pages/notifications_inbox_page.dart';
import '../widgets/dashboard_search_delegate.dart';
import '../../employee/pages/employee_create_page.dart';
import '../../site/pages/site_list_page.dart';
import '../../vehicle/pages/vehicle_list_page.dart';
import '../../warehouse/pages/warehouse_list_page.dart';
import '../../subcontractor/pages/subcontractor_list_page.dart';
import '../../material/pages/material_list_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onViewAllManagement;
  final VoidCallback? onViewAllSites;

  const DashboardPage({
    super.key, 
    this.onViewAllManagement,
    this.onViewAllSites,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _orgName = "Loading...";
  String? _orgLogo;
  final OrganizationService _orgService = OrganizationService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadOrgData();
  }

  Future<void> _loadOrgData() async {
    setState(() => _isLoading = true);
    final name = await TokenManager.getOrganizationName();
    final logo = await TokenManager.getOrganizationLogo();
    
    if (mounted) {
      setState(() {
        _orgName = name ?? "No Organization";
        _orgLogo = logo;
        _isLoading = false;
      });
    }

    // Refresh from server to be sure & fetch stats
    try {
      final currentOrg = await _orgService.getCurrentOrganization();
      final stats = await _orgService.getDashboardStats();
      if (mounted) {
        setState(() {
          if (currentOrg != null) {
            _orgName = currentOrg.name;
            _orgLogo = currentOrg.logo;
          }
          _stats = stats;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing org or stats: $e");
    }
  }

  void _showOrganizationMenu() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrganizationBottomSheet(
        currentOrgName: _orgName,
        onOrgSwitched: () => _loadOrgData(),
      ),
    );
  }

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
            title: InkWell(
              onTap: _showOrganizationMenu,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: (_orgLogo != null && _orgLogo!.isNotEmpty) ? NetworkImage(_orgLogo!) : null,
                      child: (_orgLogo == null || _orgLogo!.isEmpty) ? Icon(Icons.business_rounded, color: colorScheme.primary, size: 20) : null,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _orgName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => showSearch(
                  context: context,
                  delegate: DashboardSearchDelegate(),
                ),
                icon: const Icon(Icons.search_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsInboxPage()),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),

          /// ───────────── Dashboard Content ─────────────
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                /// Bento Grid Row 1: Major Stats
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _BentoCard(
                        title: "Active Staff",
                        value: _stats?['active_staff']?.toString() ?? "...",
                        subtitle: "Current active employees",
                        color: colorScheme.primary,
                        textColor: Colors.white,
                        icon: Icons.people_alt_rounded,
                        height: 200,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _BentoCard(
                            title: "Sites",
                            value: _stats?['sites']?.toString() ?? "...",
                            icon: Icons.business_center_rounded,
                            height: 92,
                            mini: true,
                          ),
                          const SizedBox(height: 16),
                          _BentoCard(
                            title: "Alerts",
                            value: _stats?['alerts']?.toString() ?? "...",
                            icon: Icons.warning_amber_rounded,
                            height: 92,
                            mini: true,
                            color: AppColors.warning.withValues(alpha: 0.1),
                            iconColor: AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Bento Grid Row 2: Secondary Stats
                Row(
                  children: [
                    Expanded(
                      child: _BentoCard(
                        title: "Equipment",
                        value: _stats?['equipment']?.toString() ?? "...",
                        subtitle: "Total machinery",
                        icon: Icons.build_rounded,
                        height: 150,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _BentoCard(
                        title: "Attendance",
                        value: _stats?['attendance_percentage']?.toString() ?? "...",
                        subtitle: "Today's log",
                        icon: Icons.check_circle_outline_rounded,
                        height: 150,
                        color: AppColors.success.withValues(alpha: 0.15),
                        iconColor: AppColors.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// Quick Navigation Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionHeader(title: "Management"),
                    if (widget.onViewAllManagement != null)
                      TextButton(
                        onPressed: widget.onViewAllManagement,
                        child: const Text("View All"),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickAction(
                        icon: Icons.person_add_rounded, 
                        label: "Add Staff",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeCreatePage())),
                      ),
                      _QuickAction(
                        icon: Icons.location_on_rounded, 
                        label: "Sites",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SiteListPage())),
                      ),
                      _QuickAction(
                        icon: Icons.directions_car_rounded, 
                        label: "Vehicles",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleListPage())),
                      ),
                      _QuickAction(
                        icon: Icons.warehouse_rounded, 
                        label: "Warehouses",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehouseListPage())),
                      ),
                      _QuickAction(
                        icon: Icons.engineering_rounded, 
                        label: "Subcontractors",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubcontractorListPage())),
                      ),
                      _QuickAction(
                        icon: Icons.category_rounded, 
                        label: "Materials",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialListPage())),
                      ),
                      _QuickAction(icon: Icons.assignment_rounded, label: "Work Logs"),
                      _QuickAction(icon: Icons.account_balance_rounded, label: "Payments"),
                      _QuickAction(icon: Icons.analytics_rounded, label: "Reports"),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                /// Site Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionHeader(title: "Site Progress"),
                    TextButton(
                      onPressed: widget.onViewAllSites ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SiteListPage())),
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_stats?['site_progress'] != null && (_stats!['site_progress'] as List).isNotEmpty)
                  ...(_stats!['site_progress'] as List).map((site) => _ProgressTile(
                        title: site['name'] ?? "Unknown Site",
                        subtitle: site['subtitle'] ?? "",
                        progress: (site['progress'] as num?)?.toDouble() ?? 0.0,
                      ))
                else if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No active sites", style: TextStyle(color: AppColors.textMuted))),
                  ),

                const SizedBox(height: 32),

                /// Activity Feed
                const _SectionHeader(title: "Recent Activity"),
                const SizedBox(height: 16),
                if (_stats?['recent_activities'] != null && (_stats!['recent_activities'] as List).isNotEmpty)
                  ...(_stats!['recent_activities'] as List).map((activity) => _ActivityItem(activity: activity))
                else if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No recent activity", style: TextStyle(color: AppColors.textMuted))),
                  ),

                const SizedBox(height: 40),
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

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final double height;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final bool mini;

  const _BentoCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.height,
    this.color,
    this.textColor,
    this.iconColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBackground = color != null && color != Colors.transparent;
    
    return Container(
      height: height,
      padding: EdgeInsets.all(mini ? 12 : 20),
      decoration: BoxDecoration(
        color: hasBackground ? null : theme.colorScheme.surface,
        gradient: hasBackground 
            ? LinearGradient(
                colors: [
                  color!,
                  color!.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(32),
        border: !hasBackground ? Border.all(color: AppColors.textMuted.withValues(alpha: 0.08)) : null,
        boxShadow: !hasBackground ? [
          BoxShadow(
            color: const Color(0xFF0B1222).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF0B1222).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : [
          if (color == theme.colorScheme.primary)
            BoxShadow(
              color: color!.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: mini ? 18 : 22, // Slightly smaller icons
                color: iconColor ?? (textColor?.withValues(alpha: 0.8) ?? AppColors.textSecondary),
              ),
              if (!mini && subtitle != null)
                Icon(Icons.north_east_rounded, size: 14, color: textColor?.withValues(alpha: 0.5) ?? AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: mini ? 20 : 32,
                        fontWeight: FontWeight.w800,
                        color: textColor ?? AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: mini ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: textColor?.withValues(alpha: 0.7) ?? AppColors.textSecondary,
                    ),
                  ),
                ),
                if (!mini && subtitle != null) ...[
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: textColor?.withValues(alpha: 0.5) ?? AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon, 
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.08)),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;

  const _ProgressTile({required this.title, required this.subtitle, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1222).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle, 
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    // Helper to format date roughly (e.g. "2 hours ago")
    // For now we'll just show the site name or description
    final siteName = activity['site_name'] ?? "General";
    final description = activity['description'] ?? activity['action'] ?? "Activity";
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_edu_rounded, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  "$siteName",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationBottomSheet extends StatefulWidget {
  final String currentOrgName;
  final VoidCallback onOrgSwitched;

  const _OrganizationBottomSheet({
    required this.currentOrgName,
    required this.onOrgSwitched,
  });

  @override
  State<_OrganizationBottomSheet> createState() => _OrganizationBottomSheetState();
}

class _OrganizationBottomSheetState extends State<_OrganizationBottomSheet> {
  final OrganizationService _service = OrganizationService();
  List<OrganizationModel> _organizations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  Future<void> _fetchOrganizations() async {
    try {
      final orgs = await _service.getOrganizations();
      if (mounted) {
        setState(() {
          _organizations = orgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching organizations: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _switchOrg(OrganizationModel org) async {
    if (org.name == widget.currentOrgName) {
      Navigator.pop(context);
      return;
    }

    try {
      await _service.switchOrganization(org.id);
      if (mounted) {
        widget.onOrgSwitched();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Switched to ${org.name}"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error switching organization: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Organizations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationCreatePage()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Create"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
          else if (_organizations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("No organizations found.", style: TextStyle(color: AppColors.textMuted))),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _organizations.length,
                itemBuilder: (context, index) {
                  final org = _organizations[index];
                  final isCurrent = org.name == widget.currentOrgName;
                  return _OrgItem(
                    org: org,
                    isCurrent: isCurrent,
                    onTap: () => _switchOrg(org),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OrgItem extends StatelessWidget {
  final OrganizationModel org;
  final bool isCurrent;
  final VoidCallback onTap;

  const _OrgItem({required this.org, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? theme.colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCurrent ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          backgroundImage: org.logo != null ? NetworkImage(org.logo!) : null,
          child: org.logo == null ? const Icon(Icons.business_rounded, color: AppColors.textSecondary) : null,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              org.name,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? theme.colorScheme.primary : AppColors.textPrimary,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Active",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(org.type?.name ?? "Company", style: const TextStyle(fontSize: 11)),
        trailing: isCurrent ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
      ),
    );
  }
}
