import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../organization/services/organization_service.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/pages/organization_create_page.dart';
import '../../organization/pages/organization_edit_page.dart';
import '../../auth/services/token_manager.dart';

class OrganizationSettingsPage extends StatefulWidget {
  const OrganizationSettingsPage({super.key});

  @override
  State<OrganizationSettingsPage> createState() => _OrganizationSettingsPageState();
}

class _OrganizationSettingsPageState extends State<OrganizationSettingsPage> {
  final OrganizationService _service = OrganizationService();
  OrganizationModel? _currentOrg;
  List<OrganizationModel> _allOrgs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final current = await _service.getCurrentOrganization();
      final all = await _service.getOrganizations();
      if (mounted) {
        setState(() {
          _currentOrg = current;
          _allOrgs = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _switchOrg(OrganizationModel org) async {
    if (org.id == _currentOrg?.id) return;

    setState(() => _isLoading = true);
    try {
      await _service.switchOrganization(org.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Switched to ${org.name}"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Switch failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Organization"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrganizationCreatePage()),
            ).then((_) => _loadData()),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_currentOrg != null) ...[
                    const _SectionHeader(title: "Current Context"),
                    const SizedBox(height: 16),
                    _CurrentOrgCard(org: _currentOrg!, onEdited: _loadData),
                    const SizedBox(height: 40),
                  ],
                  const _SectionHeader(title: "Your Organizations"),
                  const SizedBox(height: 16),
                  if (_allOrgs.isEmpty)
                    const Center(child: Text("No organizations found"))
                  else
                    ..._allOrgs.map((org) => _OrgListTile(
                          org: org,
                          isCurrent: org.id == _currentOrg?.id,
                          onTap: () => _switchOrg(org),
                        )),
                ],
              ),
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
    );
  }
}

class _CurrentOrgCard extends StatelessWidget {
  final OrganizationModel org;
  final Future<void> Function() onEdited;
  const _CurrentOrgCard({required this.org, required this.onEdited});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: org.logo != null ? NetworkImage(org.logo!) : null,
                child: org.logo == null ? Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 32) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(org.type?.name ?? "General Organization", style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          _InfoRow(label: "Status", value: org.isActive ? "Active" : "Inactive", isStatus: true),
          const SizedBox(height: 12),
          _InfoRow(label: "Organization ID", value: org.id.substring(0, 8).toUpperCase()),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrganizationEditPage(organization: org)),
                );
                if (updated != null) {
                  await onEdited();
                }
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text("Edit Details"),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _InfoRow({required this.label, required this.value, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
          )
        else
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _OrgListTile extends StatelessWidget {
  final OrganizationModel org;
  final bool isCurrent;
  final VoidCallback onTap;

  const _OrgListTile({required this.org, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrent ? theme.colorScheme.primary.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? theme.colorScheme.primary.withValues(alpha: 0.2) : AppColors.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.background,
          backgroundImage: org.logo != null ? NetworkImage(org.logo!) : null,
          child: org.logo == null ? const Icon(Icons.business_rounded, color: AppColors.textSecondary) : null,
        ),
        title: Text(org.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600)),
        subtitle: Text(org.type?.name ?? "Company", style: const TextStyle(fontSize: 12)),
        trailing: isCurrent
            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}
