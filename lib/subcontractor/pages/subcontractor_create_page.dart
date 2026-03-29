import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/subcontractor_model.dart';
import '../services/subcontractor_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/models/location_models.dart';

class SubcontractorCreatePage extends StatefulWidget {
  final SubcontractorModel? subcontractor;
  const SubcontractorCreatePage({super.key, this.subcontractor});

  @override
  State<SubcontractorCreatePage> createState() => _SubcontractorCreatePageState();
}

class _SubcontractorCreatePageState extends State<SubcontractorCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final SubcontractorService _service = SubcontractorService();
  final LocationService _locationService = LocationService();
  
  bool _isLoading = false;
  bool _isActive = true;
  bool _isEditing = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();

  List<Map<String, dynamic>> _emails = [];
  List<Map<String, dynamic>> _mobiles = [];
  List<Map<String, dynamic>> _addresses = [];

  List<CountryModel> _countries = [];
  List<StateModel> _states = [];
  List<DistrictModel> _districts = [];
  List<AddressTypeModel> _addressTypes = [];
  List<ContactTypeModel> _contactTypes = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.subcontractor != null;
    _loadLookups().then((_) {
      if (_emails.isEmpty) _addEmailField();
      if (_mobiles.isEmpty) _addMobileField();
      if (_addresses.isEmpty) _addAddressField();
    });
    if (widget.subcontractor != null) {
      _nameController.text = widget.subcontractor!.name;
      _specializationController.text = widget.subcontractor!.specialization;
      _isActive = widget.subcontractor!.isActive;
      
      _emails = widget.subcontractor!.emails.map((e) {
        final currentType = _contactTypes.where((t) => t.id == e.contactTypeId).firstOrNull ?? 
                      (_contactTypes.isNotEmpty ? _contactTypes.first : null);
        return {
          'id': e.id,
          'controller': TextEditingController(text: e.email),
          'type': currentType,
        };
      }).toList();
      
      _mobiles = widget.subcontractor!.mobiles.map((m) {
        final currentType = _contactTypes.where((t) => t.id == m.contactTypeId).firstOrNull ?? 
                      (_contactTypes.isNotEmpty ? _contactTypes.first : null);
        return {
          'id': m.id,
          'controller': TextEditingController(text: m.number),
          'type': currentType,
        };
      }).toList();
      
      _addresses = widget.subcontractor!.addresses.map((a) {
        final d = a.addressDetails;
        final selectedType = d != null ? (_addressTypes.where((t) => t.id == d.addressTypeId).firstOrNull ?? (_addressTypes.isNotEmpty ? _addressTypes.first : null)) : (_addressTypes.isNotEmpty ? _addressTypes.first : null);
        final selectedCountry = d != null ? (_countries.where((t) => t.id == d.countryId).firstOrNull) : null;
        
        return {
          'id': a.id,
          'line1': TextEditingController(text: d?.line1 ?? ''),
          'line2': TextEditingController(text: d?.line2 ?? ''),
          'city': TextEditingController(text: d?.city ?? ''),
          'postalCode': TextEditingController(text: d?.postalCode ?? ''),
          'selectedType': selectedType,
          'selectedCountry': selectedCountry,
          'selectedState': null, // Need to load state manually later if editing
          'selectedDistrict': null, 
          'states': <StateModel>[],
          'districts': <DistrictModel>[],
          'originalStateId': d?.stateId,
          'originalDistrictId': d?.districtId,
        };
      }).toList();
    }
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _locationService.getCountries(),
        _locationService.getAddressTypes(),
        _locationService.getContactTypes(),
      ]);
      setState(() {
        _countries = results[0] as List<CountryModel>;
        _addressTypes = results[1] as List<AddressTypeModel>;
        _contactTypes = results[2] as List<ContactTypeModel>;
      });
      
      if (_isEditing) {
        for (var addr in _addresses) {
            if (addr['selectedCountry'] != null) {
                final states = await _locationService.getStates((addr['selectedCountry'] as CountryModel).id);
                addr['states'] = states;
                addr['selectedState'] = states.where((s) => s.id == addr['originalStateId']).firstOrNull;
                
                if (addr['selectedState'] != null) {
                    final districts = await _locationService.getDistricts((addr['selectedState'] as StateModel).id);
                    addr['districts'] = districts;
                    addr['selectedDistrict'] = districts.where((d) => d.id == addr['originalDistrictId']).firstOrNull;
                }
            }
        }
        setState((){});
      }
    } catch (e) {
      debugPrint("Error loading lookups: $e");
    }
  }

  void _addEmailField() {
    setState(() {
      _emails.add({
        'id': null,
        'controller': TextEditingController(),
        'type': _contactTypes.isNotEmpty ? _contactTypes.first : null,
      });
    });
  }

  void _addMobileField() {
    setState(() {
      _mobiles.add({
        'id': null,
        'controller': TextEditingController(),
        'type': _contactTypes.isNotEmpty ? _contactTypes.first : null,
      });
    });
  }

  void _addAddressField() {
    setState(() {
      _addresses.add({
        'id': null,
        'line1': TextEditingController(),
        'line2': TextEditingController(),
        'city': TextEditingController(),
        'postalCode': TextEditingController(),
        'selectedType': _addressTypes.isNotEmpty ? _addressTypes.first : null,
        'selectedCountry': null,
        'selectedState': null,
        'selectedDistrict': null,
        'states': <StateModel>[],
        'districts': <DistrictModel>[],
      });
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> emailsToSend = [];
    for (var e in _emails) {
      if (e['controller'].text.isNotEmpty) {
        emailsToSend.add({
            if (e['id'] != null) 'id': e['id'],
            'email': e['controller'].text,
            'contact_type_id': (e['type'] as ContactTypeModel?)?.id,
        });
      }
    }

    List<Map<String, dynamic>> mobilesToSend = [];
    for (var m in _mobiles) {
      if (m['controller'].text.isNotEmpty) {
        mobilesToSend.add({
            if (m['id'] != null) 'id': m['id'],
            'number': m['controller'].text,
            'contact_type_id': (m['type'] as ContactTypeModel?)?.id,
        });
      }
    }

    List<Map<String, dynamic>> addressesToSend = [];
    for (var a in _addresses) {
      if (a['line1'].text.isNotEmpty || a['city'].text.isNotEmpty) {
        addressesToSend.add({
            if (a['id'] != null) 'id': a['id'],
            'address_details': {
                'line1': a['line1'].text,
                'line2': a['line2'].text,
                'city': a['city'].text,
                'postal_code': a['postalCode'].text,
                'address_type_id': (a['selectedType'] as AddressTypeModel?)?.id,
                'country_id': (a['selectedCountry'] as CountryModel?)?.id,
                'state_id': (a['selectedState'] as StateModel?)?.id,
                'district_id': (a['selectedDistrict'] as DistrictModel?)?.id,
            }
        });
      }
    }

    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'specialization': _specializationController.text,
      'is_active': _isActive,
      'emails': emailsToSend,
      'mobiles': mobilesToSend,
      'addresses': addressesToSend,
    };

    try {
      if (widget.subcontractor != null) {
        await _service.updateSubcontractor(widget.subcontractor!.id, data);
      } else {
        await _service.createSubcontractor(data);
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subcontractor ${widget.subcontractor != null ? 'updated' : 'created'} successfully")),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Subcontractor" : "Create Subcontractor", 
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
                _fieldWidget("Company Name", _nameController, Icons.business_rounded, validator: (v) => v!.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                _fieldWidget("Specialization", _specializationController, Icons.star_outline_rounded),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    const Text("Active Status", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const Spacer(),
                    Switch.adaptive(
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
              ]),
              
              _sectionTitle("Contact Info"),
              _emailSection(),
              const SizedBox(height: 16),
              _mobileSection(),
              
              _sectionTitle("Addresses"),
              _addressSection(),
              
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

  Widget _fieldWidget(String label, TextEditingController controller, IconData icon, {String? Function(String?)? validator, TextInputType? keyboardType}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
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
              : Text(_isEditing ? "Update" : "Create", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1.2)),
    );
  }

  Widget _baseField(TextEditingController controller, String hint, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _dropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?>? onChanged, bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? AppColors.background.withValues(alpha: 0.3) : AppColors.background.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          items: enabled ? items : null,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _emailSection() {
    return _card([
       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label("EMAILS"),
        TextButton.icon(onPressed: _addEmailField, icon: const Icon(Icons.add, size: 16), label: const Text("Add", style: TextStyle(fontSize: 12))),
      ]),
      const SizedBox(height: 8),
      ..._emails.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(flex: 2, child: _dropdown<ContactTypeModel>(value: field['type'], hint: "Type", 
              items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => _emails[idx]['type'] = v))),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _baseField(field['controller'], "email@example.com", keyboardType: TextInputType.emailAddress)),
            if (_emails.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => setState(() => _emails.removeAt(idx))),
          ]),
        );
      }),
    ]);
  }

  Widget _mobileSection() {
    return _card([
       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label("MOBILES"),
        TextButton.icon(onPressed: _addMobileField, icon: const Icon(Icons.add, size: 16), label: const Text("Add", style: TextStyle(fontSize: 12))),
      ]),
      const SizedBox(height: 8),
      ..._mobiles.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(flex: 2, child: _dropdown<ContactTypeModel>(value: field['type'], hint: "Type", 
              items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => _mobiles[idx]['type'] = v))),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _baseField(field['controller'], "+91 ...", keyboardType: TextInputType.phone)),
            if (_mobiles.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => setState(() => _mobiles.removeAt(idx))),
          ]),
        );
      }),
    ]);
  }

  Widget _addressSection() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton.icon(onPressed: _addAddressField, icon: const Icon(Icons.add_location_alt_rounded, size: 16), label: const Text("Add Address", style: TextStyle(fontSize: 12))),
      ]),
      ..._addresses.asMap().entries.map((entry) {
        int idx = entry.key;
        var f = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _label("ADDRESS #${idx + 1}"),
              if (_addresses.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => setState(() => _addresses.removeAt(idx))),
            ]),
            const SizedBox(height: 8),
            _label("ADDRESS TYPE"),
            _dropdown<AddressTypeModel>(value: f['selectedType'], hint: "Select Type", 
              items: _addressTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => f['selectedType'] = v)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label("COUNTRY"),
                _dropdown<CountryModel>(value: f['selectedCountry'], hint: "Country", items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) async {
                    setState(() { f['selectedCountry'] = v; f['selectedState'] = null; f['selectedDistrict'] = null; f['states'] = []; f['districts'] = []; });
                    if (v != null) { final states = await _locationService.getStates(v.id); setState(() => f['states'] = states); }
                  }),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label("STATE"),
                _dropdown<StateModel>(value: f['selectedState'], hint: "State", items: (f['states'] as List<StateModel>).map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: f['selectedCountry'] != null ? (v) async {
                    setState(() { f['selectedState'] = v; f['selectedDistrict'] = null; f['districts'] = []; });
                    if (v != null) { final districts = await _locationService.getDistricts(v.id); setState(() => f['districts'] = districts); }
                  } : null, enabled: f['selectedCountry'] != null),
              ])),
            ]),
            const SizedBox(height: 16),
            _label("DISTRICT"),
            _dropdown<DistrictModel>(value: f['selectedDistrict'], hint: "District", items: (f['districts'] as List<DistrictModel>).map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
              onChanged: f['selectedState'] != null ? (v) => setState(() => f['selectedDistrict'] = v) : null, enabled: f['selectedState'] != null),
            const SizedBox(height: 16),
            _label("STREET ADDRESS (LINE 1)"),
            _baseField(f['line1'], "Building No., Street Name"),
            const SizedBox(height: 16),
            _label("ADDRESS LINE 2"),
            _baseField(f['line2'], "Suite, Floor, Landmark"),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _label("CITY"), _baseField(f['city'], "City") ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _label("POSTAL CODE"), _baseField(f['postalCode'], "Zip") ])),
            ]),
          ]),
        );
      }),
    ]);
  }
}
