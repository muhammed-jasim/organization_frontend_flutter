import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';
import 'client_create_page.dart';
import 'client_details_page.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  bool _isGridView = false;
  final ClientService _service = ClientService();
  late Future<List<ClientModel>> _clientsFuture;
  List<ClientModel> _allClients = [];
  List<ClientModel> _displayClients = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadClients() {
    setState(() {
      _clientsFuture = _fetchClients();
    });
  }

  Future<List<ClientModel>> _fetchClients() async {
    final clients = await _service.getClients();
    if (mounted) {
      setState(() {
        _allClients = clients;
        _applyFilters();
      });
    }
    return clients;
  }

  void _applyFilters() {
    setState(() {
      _displayClients = _allClients.where((c) {
        final q = _searchController.text.toLowerCase();
        final matchesSearch = c.name.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q) ||
            c.primaryEmail.toLowerCase().contains(q);
        final matchesStatus = _filterStatus == 'All' ||
            (_filterStatus == 'Active' && c.isActive) ||
            (_filterStatus == 'Inactive' && !c.isActive);
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteClient(ClientModel client) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Client"),
        content: Text("Are you sure you want to delete ${client.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await _service.deleteClient(client.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Client deleted"), backgroundColor: AppColors.success),
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch $url"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _callClient(String phone) => _launchUrl("tel:$phone");
  void _smsClient(String phone) => _launchUrl("sms:$phone");
  void _whatsappClient(String phone) {
    // Basic number cleaning (remove non-digits except +)
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    _launchUrl("https://wa.me/$cleanPhone");
  }

  void _editClient(ClientModel client) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientCreatePage(client: client)),
    );
    if (result == true) _loadClients();
  }

  void _showClientDetails(ClientModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailPage(client: client)),
    ).then((_) => _loadClients());
  }

  Widget _buildSummaryCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: AppColors.background,
            scrolledUnderElevation: 0,
            title: Text("Clients", style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.format_list_bulleted_rounded : Icons.grid_view_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildSummaryCard("Total Clients", _allClients.length.toString(), AppColors.primary),
                      const SizedBox(width: 12),
                      _buildSummaryCard("Active", _allClients.where((c) => c.isActive).length.toString(), AppColors.success),
                      const SizedBox(width: 12),
                      _buildSummaryCard("Inactive", _allClients.where((c) => !c.isActive).length.toString(), AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name or code...",
                        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                          onPressed: _showFiltersBottomSheet,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          FutureBuilder<List<ClientModel>>(
            future: _clientsFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _allClients.isEmpty) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (_displayClients.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.handshake_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text("No clients found", style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    ]),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: _isGridView ? _buildGrid() : _buildList(),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          heroTag: 'client_list_fab',
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCreatePage()));
            if (result == true) _loadClients();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.add_rounded),
          label: const Text("Create", style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filter Clients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Client Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['All', 'Active', 'Inactive'].map((status) {
                  final isSelected = _filterStatus == status;
                  return FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (v) {
                      setModalState(() => _filterStatus = status);
                      setState(() { _filterStatus = status; _applyFilters(); });
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildClientListTile(_displayClients[i]),
        ),
        childCount: _displayClients.length,
      ),
    );
  }

  Widget _buildClientListTile(ClientModel client) {
    return GestureDetector(
      onTap: () => _showClientDetails(client),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(client.code, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusDot(client.isActive),
                const SizedBox(height: 4),
                Text(client.isActive ? "Active" : "Inactive", style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _buildClientCard(_displayClients[i]),
        childCount: _displayClients.length,
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return GestureDetector(
      onTap: () => _showClientDetails(client),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 20),
                ),
                _statusBadge(client.isActive),
              ],
            ),
            const Spacer(),
            Text(client.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(client.code, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(bool isActive) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.success : AppColors.error,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? "ACTIVE" : "INACTIVE",
        style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
