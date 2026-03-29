import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/material_models.dart';
import '../services/material_service.dart';

class MaterialCreatePage extends StatefulWidget {
  final MaterialModel? material;
  const MaterialCreatePage({super.key, this.material});

  @override
  State<MaterialCreatePage> createState() => _MaterialCreatePageState();
}

class _MaterialCreatePageState extends State<MaterialCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _service = MaterialService();
  
  bool _isLoading = false;
  bool _isActive = true;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  int? _selectedCategory;
  List<MaterialCategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.material != null) {
      _nameController.text = widget.material!.name;
      _codeController.text = widget.material!.code;
      _unitController.text = widget.material!.unit;
      _descriptionController.text = widget.material!.description;
      _priceController.text = widget.material!.basePrice.toString();
      _selectedCategory = widget.material!.category;
      _isActive = widget.material!.isActive;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _service.getMaterialCategories();
      setState(() => _categories = categories);
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'code': _codeController.text,
      'unit': _unitController.text,
      'description': _descriptionController.text,
      'base_price': double.tryParse(_priceController.text) ?? 0.0,
      'category': _selectedCategory,
      'is_active': _isActive,
    };

    try {
      if (widget.material != null) {
        await _service.updateMaterial(widget.material!.id, data);
      } else {
        await _service.createMaterial(data);
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Material ${widget.material != null ? 'updated' : 'created'} successfully")),
        );
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

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.material == null ? "Create Material" : "Edit Material", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Basic Information"),
              _card([
                _fieldWidget("Material Name", _nameController, Icons.layers_rounded, validator: (v) => v!.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                _fieldWidget("Code", _codeController, Icons.qr_code_rounded, validator: (v) => v!.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                _fieldWidget("Unit (e.g. Kg, Mtr, Nos)", _unitController, Icons.straighten_rounded, validator: (v) => v!.isEmpty ? "Required" : null),
              ]),

              _sectionTitle("Pricing & Description"),
              _card([
                _fieldWidget("Base Price", _priceController, Icons.payments_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined, size: 18, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _fieldWidget("Description", _descriptionController, Icons.description_outlined, maxLines: 3),
              ]),

              _sectionTitle("Status"),
              _card([
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    const Text("Active Status", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const Spacer(),
                    Switch.adaptive(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
    child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.2)),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _fieldWidget(String label, TextEditingController controller, IconData icon, {String? Function(String?)? validator, TextInputType? keyboardType, int maxLines = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background.withValues(alpha: 0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    ],
  );

  Widget _buildBottomAction() => Container(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
    ),
    child: Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.material == null ? "Create" : "Update", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}
