import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../services/organization_service.dart';
import '../models/organization_model.dart';

class OrganizationEditPage extends StatefulWidget {
  final OrganizationModel organization;

  const OrganizationEditPage({super.key, required this.organization});

  @override
  State<OrganizationEditPage> createState() => _OrganizationEditPageState();
}

class _OrganizationEditPageState extends State<OrganizationEditPage> {
  final _formKey = GlobalKey<FormState>();
  final OrganizationService _service = OrganizationService();

  // ── Details ──
  final _nameController = TextEditingController();
  List<OrganizationTypeModel> _types = [];
  OrganizationTypeModel? _selectedType;
  XFile? _newLogo;
  final _picker = ImagePicker();

  // ── Address ──
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  List<CountryModel> _countries = [];
  List<StateModel> _states = [];
  List<DistrictModel> _districts = [];
  List<AddressTypeModel> _addressTypes = [];
  CountryModel? _selectedCountry;
  StateModel? _selectedState;
  DistrictModel? _selectedDistrict;
  AddressTypeModel? _selectedAddressType;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.organization.name;
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _service.getOrganizationTypes(),
        _service.getCountries(),
        _service.getAddressTypes(),
      ]);

      final types = results[0] as List<OrganizationTypeModel>;
      final countries = results[1] as List<CountryModel>;
      final addrTypes = results[2] as List<AddressTypeModel>;

      // Get primary address if any
      final existingAddr = widget.organization.addresses
          .where((a) => a.isPrimary)
          .toList();
      final addr = existingAddr.isNotEmpty ? existingAddr.first : null;

      // Pre-select type
      OrganizationTypeModel? selType;
      if (widget.organization.type != null) {
        selType = types.firstWhere(
          (t) => t.id == widget.organization.type!.id,
          orElse: () => types.isNotEmpty ? types.first : OrganizationTypeModel(id: '', name: ''),
        );
      } else if (types.isNotEmpty) {
        selType = types.first;
      }

      // Pre-select country from existing address
      CountryModel? selCountry;
      List<StateModel> states = [];
      StateModel? selState;
      List<DistrictModel> districts = [];
      DistrictModel? selDistrict;
      AddressTypeModel? selAddrType;

      if (addr != null) {
        _line1Controller.text = addr.line1;
        _line2Controller.text = addr.line2;
        _cityController.text = addr.city;
        _postalCodeController.text = addr.postalCode;

        // Find country
        selCountry = countries.firstWhere(
          (c) => c.id == addr.countryId,
          orElse: () => CountryModel(id: addr.countryId, name: addr.countryName, code: ''),
        );

        // Load states for that country
        states = await _service.getStates(addr.countryId);
        selState = states.firstWhere(
          (s) => s.id == addr.stateId,
          orElse: () => StateModel(id: addr.stateId, name: addr.stateName, countryId: addr.countryId),
        );

        // Load districts for that state
        districts = await _service.getDistricts(addr.stateId);
        selDistrict = districts.firstWhere(
          (d) => d.id == addr.districtId,
          orElse: () => DistrictModel(id: addr.districtId, name: addr.districtName, stateId: addr.stateId),
        );

        // Pre-select address type
        if (addr.addressTypeId != null) {
          selAddrType = addrTypes.firstWhere(
            (a) => a.id == addr.addressTypeId,
            orElse: () => addrTypes.isNotEmpty ? addrTypes.first : AddressTypeModel(id: '', name: '', code: ''),
          );
        }
      }

      if (mounted) {
        setState(() {
          _types = types;
          _countries = countries;
          _addressTypes = addrTypes;
          _selectedType = selType;
          _selectedCountry = selCountry;
          _states = states;
          _selectedState = selState;
          _districts = districts;
          _selectedDistrict = selDistrict;
          _selectedAddressType = selAddrType;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to load data: $e");
      }
    }
  }

  Future<void> _onCountryChanged(CountryModel? country) async {
    if (country == null) return;
    setState(() {
      _selectedCountry = country;
      _selectedState = null;
      _selectedDistrict = null;
      _states = [];
      _districts = [];
    });
    final states = await _service.getStates(country.id);
    if (mounted) setState(() => _states = states);
  }

  Future<void> _onStateChanged(StateModel? state) async {
    if (state == null) return;
    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _districts = [];
    });
    final districts = await _service.getDistricts(state.id);
    if (mounted) setState(() => _districts = districts);
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _newLogo = image);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) { _showError("Please select an organization type."); return; }

    setState(() => _isSaving = true);
    try {
      // 1. Save details (name/type/logo)
      final updated = await _service.updateOrganization(
        widget.organization.id,
        name: _nameController.text.trim(),
        typeId: _selectedType!.id,
        logo: _newLogo,
      );

      // 2. Save address if district is selected
      if (_selectedDistrict != null && _line1Controller.text.trim().isNotEmpty) {
        await _service.updateOrgAddresses(widget.organization.id, [
          {
            'line_1': _line1Controller.text.trim(),
            'line_2': _line2Controller.text.trim(),
            'city': _cityController.text.trim(),
            'postal_code': _postalCodeController.text.trim(),
            'district': _selectedDistrict!.id,
            if (_selectedAddressType != null) 'address_type': _selectedAddressType!.id,
            'is_primary': true,
          }
        ]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Organization updated!"), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      _showError("Update failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Organization"),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section: Logo ──
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              backgroundImage: _newLogo != null
                                  ? (kIsWeb ? NetworkImage(_newLogo!.path) : FileImage(File(_newLogo!.path)) as ImageProvider)
                                  : (widget.organization.logo != null ? NetworkImage(widget.organization.logo!) : null),
                              child: (_newLogo == null && widget.organization.logo == null)
                                  ? Icon(Icons.add_a_photo_outlined, size: 36, color: theme.colorScheme.primary)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 4, right: 4,
                            child: GestureDetector(
                              onTap: _pickLogo,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(child: Text("Tap to change logo", style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                    const SizedBox(height: 32),

                    // ── Section: Details ──
                    _sectionHeader("Organization Details"),
                    const SizedBox(height: 16),
                    _label("NAME"),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: "e.g., Acme Construction", prefixIcon: Icon(Icons.business_rounded, size: 20)),
                      validator: (v) => v == null || v.isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 20),
                    _label("ORGANIZATION TYPE"),
                    _dropdown<OrganizationTypeModel>(
                      value: _selectedType,
                      hint: "Select Type",
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),
                    const SizedBox(height: 32),

                    // ── Section: Address ──
                    _sectionHeader("Registered Address"),
                    const SizedBox(height: 4),
                    Text(
                      widget.organization.addresses.isEmpty
                          ? "No address on file. Fill in below to add one."
                          : "Editing will replace the current address.",
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("COUNTRY"),
                        _dropdown<CountryModel>(
                          value: _selectedCountry,
                          hint: "Country",
                          items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                          onChanged: _onCountryChanged,
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("STATE"),
                        _dropdown<StateModel>(
                          value: _selectedState,
                          hint: "State",
                          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                          onChanged: _onStateChanged,
                          enabled: _selectedCountry != null,
                        ),
                      ])),
                    ]),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("DISTRICT"),
                        _dropdown<DistrictModel>(
                          value: _selectedDistrict,
                          hint: "District",
                          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                          onChanged: (v) => setState(() => _selectedDistrict = v),
                          enabled: _selectedState != null,
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("TYPE"),
                        _dropdown<AddressTypeModel>(
                          value: _selectedAddressType,
                          hint: "e.g., Office",
                          items: _addressTypes.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                          onChanged: (v) => setState(() => _selectedAddressType = v),
                        ),
                      ])),
                    ]),
                    const SizedBox(height: 16),

                    _label("STREET ADDRESS (LINE 1)"),
                    TextFormField(
                      controller: _line1Controller,
                      decoration: const InputDecoration(hintText: "Building No, Street Name"),
                    ),
                    const SizedBox(height: 16),

                    _label("ADDRESS LINE 2 (OPTIONAL)"),
                    TextFormField(
                      controller: _line2Controller,
                      decoration: const InputDecoration(hintText: "Suite, Floor, Landmark"),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("CITY"),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(hintText: "City"),
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("POSTAL CODE"),
                        TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(hintText: "Zip"),
                        ),
                      ])),
                    ]),
                    const SizedBox(height: 48),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Save All Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.2)),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          items: enabled ? items : null,
          onChanged: enabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
