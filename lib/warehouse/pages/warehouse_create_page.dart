import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../shared/models/location_models.dart';
import '../../shared/services/location_service.dart';
import '../services/warehouse_service.dart';
import '../models/warehouse_model.dart';

class WarehouseCreatePage extends StatefulWidget {
  final WarehouseModel? warehouse;
  const WarehouseCreatePage({super.key, this.warehouse});

  @override
  State<WarehouseCreatePage> createState() => _WarehouseCreatePageState();
}

class _WarehouseCreatePageState extends State<WarehouseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseService _service = WarehouseService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  bool _isSaving = false;

  // ── Warehouse fields ──
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isPrimary = false;
  bool _isActive = true;

  // ── Multiple Addresses ──
  final List<Map<String, dynamic>> _addressFields = [];
  List<CountryModel> _countries = [];
  List<AddressTypeModel> _addressTypes = [];

  // ── Multiple Contacts (Email/Mobile) ──
  List<ContactTypeModel> _contactTypes = [];
  final List<Map<String, dynamic>> _emailFields = [];
  final List<Map<String, dynamic>> _mobileFields = [];

  bool get _isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final w = widget.warehouse!;
      _nameController.text = w.name;
      _codeController.text = w.code;
      _isPrimary = w.isPrimary;
      _isActive = w.isActive;

      for (var addrObj in w.addressList) {
        final d = addrObj.addressDetails;
        if (d != null) {
          _addAddressField(
            initialLine1: d.line1,
            initialLine2: d.line2,
            initialCity: d.city,
            initialPostalCode: d.postalCode,
            initialTypeId: d.addressTypeId,
            initialCountryId: d.countryId,
            initialStateId: d.stateId,
            initialDistrictId: d.districtId,
          );
        }
      }

      for (var e in w.emails) {
        _addEmailField(initialValue: e.email, initialTypeId: e.contactTypeId);
      }
      for (var m in w.mobiles) {
        _addMobileField(initialValue: m.number, initialTypeId: m.contactTypeId);
      }
    }

    if (_addressFields.isEmpty) _addAddressField();
    if (_emailFields.isEmpty) _addEmailField();
    if (!_isEditing) {
      _fetchNextCode();
    }

    _initLocations();
  }

  Future<void> _fetchNextCode() async {
    try {
      final code = await _service.getNextCode();
      if (mounted) {
        setState(() => _codeController.text = code);
      }
    } catch (e) {
      debugPrint("Error fetching next code: $e");
    }
  }

  void _addAddressField({
    String initialLine1 = '',
    String initialLine2 = '',
    String initialCity = '',
    String initialPostalCode = '',
    String? initialTypeId,
    String? initialCountryId,
    String? initialStateId,
    String? initialDistrictId,
  }) {
    setState(() {
      _addressFields.add({
        'line1': TextEditingController(text: initialLine1),
        'line2': TextEditingController(text: initialLine2),
        'city': TextEditingController(text: initialCity),
        'postalCode': TextEditingController(text: initialPostalCode),
        'typeId': initialTypeId,
        'countryId': initialCountryId,
        'stateId': initialStateId,
        'districtId': initialDistrictId,
        'selectedType': null,
        'selectedCountry': null,
        'selectedState': null,
        'selectedDistrict': null,
        'states': <StateModel>[],
        'districts': <DistrictModel>[],
      });
    });
  }

  void _addEmailField({String initialValue = '', String? initialTypeId}) {
    setState(() {
      _emailFields.add({
        'controller': TextEditingController(text: initialValue),
        'typeId': initialTypeId,
        'type': null,
      });
    });
  }

  void _addMobileField({String initialValue = '', String? initialTypeId}) {
    setState(() {
      _mobileFields.add({
        'controller': TextEditingController(text: initialValue),
        'typeId': initialTypeId,
        'type': null,
      });
    });
  }

  Future<void> _initLocations() async {
    try {
      final countries = await _locationService.getCountries();
      final contactTypes = await _locationService.getContactTypes();
      final addressTypes = await _locationService.getAddressTypes();

      if (!mounted) return;

      setState(() {
        _countries = countries;
        _contactTypes = contactTypes;
        _addressTypes = addressTypes;
      });

      // Match types for emails/mobiles
      for (var f in _emailFields) {
        f['type'] = _contactTypes.where((t) => t.id == f['typeId']).firstOrNull ?? (_contactTypes.isNotEmpty ? _contactTypes.first : null);
      }
      for (var f in _mobileFields) {
        f['type'] = _contactTypes.where((t) => t.id == f['typeId']).firstOrNull ?? (_contactTypes.isNotEmpty ? _contactTypes.first : null);
      }

      // Match details for addresses
      for (var i = 0; i < _addressFields.length; i++) {
        var f = _addressFields[i];
        f['selectedType'] = _addressTypes.where((t) => t.id == f['typeId']).firstOrNull;
        f['selectedCountry'] = _countries.where((c) => c.id == f['countryId']).firstOrNull;

        if (f['selectedCountry'] != null) {
          final states = await _locationService.getStates(f['selectedCountry'].id);
          f['states'] = states;
          f['selectedState'] = states.where((s) => s.id == f['stateId']).firstOrNull;

          if (f['selectedState'] != null) {
            final districts = await _locationService.getDistricts(f['selectedState'].id);
            f['districts'] = districts;
            f['selectedDistrict'] = districts.where((d) => d.id == f['districtId']).firstOrNull;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddressCountryChanged(int idx, CountryModel? country) async {
    setState(() {
      _addressFields[idx]['selectedCountry'] = country;
      _addressFields[idx]['selectedState'] = null;
      _addressFields[idx]['selectedDistrict'] = null;
      _addressFields[idx]['states'] = <StateModel>[];
      _addressFields[idx]['districts'] = <DistrictModel>[];
    });
    if (country != null) {
      final states = await _locationService.getStates(country.id);
      if (mounted) setState(() => _addressFields[idx]['states'] = states);
    }
  }

  Future<void> _onAddressStateChanged(int idx, StateModel? state) async {
    setState(() {
      _addressFields[idx]['selectedState'] = state;
      _addressFields[idx]['selectedDistrict'] = null;
      _addressFields[idx]['districts'] = <DistrictModel>[];
    });
    if (state != null) {
      final districts = await _locationService.getDistricts(state.id);
      if (mounted) setState(() => _addressFields[idx]['districts'] = districts);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    for (var f in _addressFields) {
      f['line1']?.dispose();
      f['line2']?.dispose();
      f['city']?.dispose();
      f['postalCode']?.dispose();
    }
    for (var f in _emailFields) {
      f['controller']?.dispose();
    }
    for (var f in _mobileFields) {
      f['controller']?.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Build addresses list
      final addresses = _addressFields
          .where((f) => f['line1'].text.trim().isNotEmpty && f['selectedDistrict'] != null)
          .map((f) => {
                'line_1': f['line1'].text.trim(),
                'line_2': f['line2'].text.trim(),
                'city': f['city'].text.trim(),
                'postal_code': f['postalCode'].text.trim(),
                'district': (f['selectedDistrict'] as DistrictModel).id,
                'address_type': (f['selectedType'] as AddressTypeModel?)?.id,
                'is_primary': f['is_primary'] ?? false,
              })
          .toList();

      // Build emails list
      final emailsList = _emailFields
          .where((f) => f['controller'].text.trim().isNotEmpty)
          .map((f) => {
                'email': f['controller'].text.trim(),
                'contact_type': (f['type'] as ContactTypeModel?)?.id,
              })
          .toList();

      // Build mobiles list
      final mobilesList = _mobileFields
          .where((f) => f['controller'].text.trim().isNotEmpty)
          .map((f) => {
                'number': f['controller'].text.trim(),
                'contact_type': (f['type'] as ContactTypeModel?)?.id,
              })
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'is_primary': _isPrimary,
        'is_active': _isActive,
        'address_input': addresses,
        'email_input': emailsList,
        'mobile_input': mobilesList,
      };

      if (_isEditing) {
        await _service.updateWarehouse(widget.warehouse!.id, data);
      } else {
        await _service.createWarehouse(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? "Warehouse updated!" : "Warehouse created!"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        title: Text(_isEditing ? "Edit Warehouse" : "New Warehouse", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isSaving ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Warehouse Identity"),
              _card([
                _label("WAREHOUSE NAME *"),
                _field(_nameController, "e.g., Central Hub", validator: (v) => v == null || v.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("WAREHOUSE CODE"),
                    _field(_codeController, "e.g., WH-001"),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("STATUS"),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_isActive ? "Active" : "Inactive", style: TextStyle(color: _isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
                        Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: AppColors.success),
                      ]),
                    ),
                  ])),
                ]),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Primary Warehouse", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Set as main organizational hub", style: TextStyle(fontSize: 12)),
                  value: _isPrimary,
                  onChanged: (val) => setState(() => _isPrimary = val),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ]),

              const SizedBox(height: 32),
              _sectionTitle("Contact Info"),
              _card([
                _emailSection(),
                const SizedBox(height: 24),
                _mobileSection(),
              ]),

              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _sectionTitle("Addresses"),
                TextButton.icon(onPressed: () => _addAddressField(), icon: const Icon(Icons.add_location_alt_rounded, size: 16), label: const Text("Add", style: TextStyle(fontSize: 12))),
              ]),
              _addressSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(_isEditing ? "Update" : "Create", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.2)));

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );


  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.2)));

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? keyboardType, String? Function(String?)? validator}) => TextFormField(controller: ctrl, keyboardType: keyboardType, validator: validator, decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppColors.background.withValues(alpha: 0.3), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.1))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error))));

  Widget _dropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?>? onChanged, bool enabled = true}) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: enabled ? AppColors.background.withValues(alpha: 0.3) : AppColors.background.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)), items: enabled ? items : null, onChanged: enabled ? onChanged : null, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary))));

  Widget _emailSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label("EMAILS"),
        TextButton.icon(
          onPressed: _addEmailField,
          icon: const Icon(Icons.add, size: 16),
          label: const Text("Add", style: TextStyle(fontSize: 12)),
        ),
      ]),
      ..._emailFields.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: _dropdown<ContactTypeModel>(
                value: field['type'],
                hint: "Type",
                items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _emailFields[idx]['type'] = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _field(field['controller'] as TextEditingController, "email@example.com", keyboardType: TextInputType.emailAddress),
            ),
            if (_emailFields.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                onPressed: () => setState(() => _emailFields.removeAt(idx)),
              ),
          ]),
        );
      }),
    ]);
  }

  Widget _mobileSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label("MOBILES"),
        TextButton.icon(
          onPressed: _addMobileField,
          icon: const Icon(Icons.add, size: 16),
          label: const Text("Add", style: TextStyle(fontSize: 12)),
        ),
      ]),
      ..._mobileFields.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: _dropdown<ContactTypeModel>(
                value: field['type'],
                hint: "Type",
                items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _mobileFields[idx]['type'] = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _field(field['controller'] as TextEditingController, "+91 ...", keyboardType: TextInputType.phone),
            ),
            if (_mobileFields.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                onPressed: () => setState(() => _mobileFields.removeAt(idx)),
              ),
          ]),
        );
      }),
    ]);
  }

  Widget _addressSection() {
    return Column(children: _addressFields.asMap().entries.map((entry) {
      int idx = entry.key;
      var f = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _label("ADDRESS #${idx + 1}"),
            if (_addressFields.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => setState(() => _addressFields.removeAt(idx))),
          ]),
            const SizedBox(height: 8),
            _label("ADDRESS TYPE"),
            _dropdown<AddressTypeModel>(
              value: f['selectedType'],
              hint: "Select Type",
              items: _addressTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => f['selectedType'] = v),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label("COUNTRY"),
                _dropdown<CountryModel>(
                  value: f['selectedCountry'],
                  hint: "Country",
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) => _onAddressCountryChanged(idx, v),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label("STATE"),
                _dropdown<StateModel>(
                  value: f['selectedState'],
                  hint: "State",
                  items: (f['states'] as List<StateModel>).map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: f['selectedCountry'] != null ? (v) => _onAddressStateChanged(idx, v) : null,
                  enabled: f['selectedCountry'] != null,
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            _label("DISTRICT"),
            _dropdown<DistrictModel>(
              value: f['selectedDistrict'],
              hint: "District",
              items: (f['districts'] as List<DistrictModel>).map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
              onChanged: f['selectedState'] != null ? (v) => setState(() => f['selectedDistrict'] = v) : null,
              enabled: f['selectedState'] != null,
            ),
            const SizedBox(height: 16),
            _label("STREET ADDRESS (LINE 1)"),
            _field(f['line1'], "Building No., Street Name"),
            const SizedBox(height: 16),
            _label("ADDRESS LINE 2"),
            _field(f['line2'], "Suite, Floor, Landmark"),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label("CITY"),
                _field(f['city'], "City"),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label("POSTAL CODE"),
                _field(f['postalCode'], "Zip"),
              ])),
            ]),
          ]),
        );
      }).toList());
  }
}
