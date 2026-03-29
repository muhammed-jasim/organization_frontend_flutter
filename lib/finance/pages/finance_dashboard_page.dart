import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../services/finance_service.dart';
import '../models/transaction_model.dart';
import '../models/finance_category.dart';
import 'transaction_form_page.dart';

class FinanceDashboardPage extends StatefulWidget {
  const FinanceDashboardPage({super.key});

  @override
  State<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends State<FinanceDashboardPage> {
  final FinanceService _financeService = FinanceService();
  bool _isLoading = true;
  double _totalBalance = 0.0;
  double _totalEarnings = 0.0;
  double _totalExpenses = 0.0;
  List<TransactionModel> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _financeService.getFinanceSummary();
      final transactions = await _financeService.getTransactions();
      
      if (mounted) {
        setState(() {
          _totalBalance = (summary['total_balance'] ?? 0.0).toDouble();
          _totalEarnings = (summary['total_earnings'] ?? 0.0).toDouble();
          _totalExpenses = (summary['total_expenses'] ?? 0.0).toDouble();
          _recentTransactions = transactions.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Error handling or fallback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadFinanceData,
        child: CustomScrollView(
          slivers: [
            /// ───────────── Modern Header ─────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: AppColors.background,
              surfaceTintColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  "Finance Hub",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            /// ───────────── Content ─────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  /// Total Balance Card
                  _MainBalanceCard(balance: _totalBalance),
                  const SizedBox(height: 24),

                  /// Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: "Earnings",
                          value: "₹${_totalEarnings.toStringAsFixed(0)}",
                          icon: Icons.trending_up_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: "Expenses",
                          value: "₹${_totalExpenses.toStringAsFixed(0)}",
                          icon: Icons.trending_down_rounded,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// Quick Actions
                  const _SectionHeader(title: "Quick Actions"),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FinanceAction(
                        icon: Icons.add_card_rounded,
                        label: "Payment",
                        color: AppColors.primary,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionFormPage(isPayment: true),
                            ),
                          );
                          _loadFinanceData();
                        },
                      ),
                      _FinanceAction(
                        icon: Icons.receipt_long_rounded,
                        label: "Receipt",
                        color: AppColors.accent,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionFormPage(isPayment: false),
                            ),
                          );
                          _loadFinanceData();
                        },
                      ),
                      _FinanceAction(
                        icon: Icons.pie_chart_rounded,
                        label: "Reports",
                        color: Colors.deepPurple,
                        onTap: () {}, // Future logic
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// Categories Bento
                  const _SectionHeader(title: "By Category"),
                  const SizedBox(height: 16),
                  _CategoryGrid(),

                  const SizedBox(height: 32),

                  /// Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(title: "Recent Activity"),
                      TextButton(
                        onPressed: () {},
                        child: const Text("View All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_recentTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          "No transactions yet.",
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ..._recentTransactions.map((tx) => _TransactionTile(tx: tx)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainBalanceCard extends StatelessWidget {
  final double balance;
  const _MainBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white24, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₹${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Updated just now",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FinanceAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FinanceAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _CategoryTile(
          icon: Icons.groups_rounded,
          label: "Staff Pay",
          color: Colors.indigo,
          category: FinanceCategory.employeePayment,
        ),
        _CategoryTile(
          icon: Icons.architecture_rounded,
          label: "Earnings",
          color: Colors.teal,
          category: FinanceCategory.siteEarning,
        ),
        _CategoryTile(
          icon: Icons.construction_rounded,
          label: "Rentals",
          color: Colors.orange,
          category: FinanceCategory.equipmentRental,
        ),
        _CategoryTile(
          icon: Icons.inventory_2_rounded,
          label: "Materials",
          color: Colors.blueGrey,
          category: FinanceCategory.materialExpense,
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final FinanceCategory category;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.transactionType == 'Credit'; // Simplified logic: outgoing is credit in some systems, depends on implementation
    final color = isExpense ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : tx.category.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "${isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
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
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }
}
