import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../services/equipment_service.dart';
import '../../theme/app_theme.dart';

class EquipmentMultiSelectDialog extends StatefulWidget {
  final List<String> initialSelectedIds;

  const EquipmentMultiSelectDialog({
    super.key,
    this.initialSelectedIds = const [],
  });

  @override
  State<EquipmentMultiSelectDialog> createState() => _EquipmentMultiSelectDialogState();
}

class _EquipmentMultiSelectDialogState extends State<EquipmentMultiSelectDialog> {
  final EquipmentService _equipmentService = EquipmentService();
  List<EquipmentModel> _equipments = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    setState(() => _isLoading = true);
    try {
      final equipments = await _equipmentService.getEquipments();
      setState(() {
        _equipments = equipments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching equipment: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<EquipmentModel> get _filteredEquipments {
    if (_searchQuery.isEmpty) return _equipments;
    return _equipments.where((e) {
      final name = e.name.toLowerCase();
      final code = e.code.toLowerCase();
      final category = e.categoryDetail?.name.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || 
             code.contains(_searchQuery.toLowerCase()) ||
             category.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Equipment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search name, code or category...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_filteredEquipments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No equipment found.")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredEquipments.length,
                  itemBuilder: (context, index) {
                    final equipment = _filteredEquipments[index];
                    final isSelected = _selectedIds.contains(equipment.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(equipment.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${equipment.code} • ${equipment.categoryDetail?.name ?? 'No Category'}", style: const TextStyle(fontSize: 12)),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(equipment.id);
                          } else {
                            _selectedIds.remove(equipment.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : () => Navigator.pop(context, _selectedIds.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Assign (${_selectedIds.length})"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
