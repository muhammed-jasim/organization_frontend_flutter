import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../auth/services/token_manager.dart';
import '../models/site_model.dart';
import '../services/site_service.dart';
import '../../client/services/client_service.dart';
import '../../client/models/client_model.dart';
import '../../shared/models/location_models.dart';
import '../../shared/services/location_service.dart';

class SiteCreatePage extends StatefulWidget {
  final SiteModel? site;
  const SiteCreatePage({super.key, this.site});

  @override
  State<SiteCreatePage> createState() => _SiteCreatePageState();
}

class _SiteCreatePageState extends State<SiteCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final SiteService _service = SiteService();
  final LocationService _locationService = LocationService();
  final ClientService _clientService = ClientService();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  final _newClientNameController = TextEditingController();
  final _newClientCodeController = TextEditingController();
  
  // Client Contact & Multiple Addresses
  final List<Map<String, dynamic>> _clientEmailFields = [];
  final List<Map<String, dynamic>> _clientMobileFields = [];
  final List<Map<String, dynamic>> _clientAddressFields = [];
  
  // Address State (Site)
  final Map<String, dynamic> _siteAddress = {};
  bool _sameAsClientAddress = false;
  
  List<CountryModel> _countries = [];
  List<AddressTypeModel> _addressTypes = [];
  List<ContactTypeModel> _contactTypes = [];

  // Data
  DateTime? _expectedStartDate;
  DateTime? _expectedEndDate;
  List<SiteStatusModel> _statusModels = [];
  String? _selectedStatusId;
  List<ClientModel> _clients = [];
  String? _selectedClientId;
  bool _isNewClient = false;
  bool _isLoading = false;
  
  // Media
  final List<XFile> _newPhotos = [];
  final List<PlatformFile> _newAttachments = [];

  bool get _isEditing => widget.site != null;

  @override
  void initState() {
    super.initState();
    _initAddressField(_siteAddress);
    if (_clientEmailFields.isEmpty) _addClientEmailField();
    if (_clientMobileFields.isEmpty) _addClientMobileField();
    if (_clientAddressFields.isEmpty) _addClientAddressField();
    _loadInitialData();
    if (widget.site != null) {
      _nameController.text = widget.site!.name;
      _codeController.text = widget.site!.code;
      _budgetController.text = widget.site!.estimatedBudget?.toString() ?? '';
      _selectedStatusId = widget.site!.status.isNotEmpty ? widget.site!.status : null;
      _notesController.text = widget.site!.notes ?? '';
      _expectedStartDate = widget.site!.expectedStartDate;
      _expectedEndDate = widget.site!.expectedEndDate;
      _selectedClientId = widget.site!.clientLink?.clientId;
      
      // Load site address if exists
      if (widget.site!.addresses.isNotEmpty) {
        final addr = widget.site!.addresses.first;
        _siteAddress['line1'].text = addr.line1;
        _siteAddress['line2'].text = addr.line2;
        _siteAddress['city'].text = addr.city;
        _siteAddress['postalCode'].text = addr.postalCode;
        // Types and IDs will be matched in _loadInitialData
      }
    } else {
      _fetchNextCode();
    }
  }

  Future<void> _fetchNextCode() async {
    try {
      final code = await _service.getNextCode();
      if (mounted && code.isNotEmpty) {
        setState(() => _codeController.text = code);
      }
    } catch (e) {
      debugPrint("Error fetching next code: $e");
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _clientService.getClients(),
        _locationService.getCountries(),
        _locationService.getAddressTypes(),
        _locationService.getContactTypes(),
        _service.getSiteStatuses(),
      ]);

      setState(() {
        _clients = results[0] as List<ClientModel>;
        _countries = results[1] as List<CountryModel>;
        _addressTypes = results[2] as List<AddressTypeModel>;
        _contactTypes = results[3] as List<ContactTypeModel>;
        _statusModels = results[4] as List<SiteStatusModel>;
        
        // Initial status if creating new
        if (!_isEditing && _statusModels.isNotEmpty) {
          _selectedStatusId = _statusModels.firstWhere((s) => s.code == 'planning', orElse: () => _statusModels.first).id;
        }
        
        // Match contact types for existing fields
        for (var f in _clientEmailFields) {
          f['type'] = _contactTypes.firstOrNull;
        }
        for (var f in _clientMobileFields) {
          f['type'] = _contactTypes.firstOrNull;
        }
        
        _isLoading = false;
        
        // Match existing site address types/locations if editing
        if (_isEditing && widget.site!.addresses.isNotEmpty) {
          final addr = widget.site!.addresses.first;
          _siteAddress['selectedType'] = _addressTypes.where((t) => t.id == addr.addressTypeId).firstOrNull;
          _matchAddressLocations(_siteAddress, addr);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addClientEmailField() {
    setState(() {
      _clientEmailFields.add({
        'controller': TextEditingController(),
        'type': _contactTypes.firstOrNull,
      });
    });
  }

  void _addClientMobileField() {
    setState(() {
      _clientMobileFields.add({
        'controller': TextEditingController(),
        'type': _contactTypes.firstOrNull,
      });
    });
  }

  void _addClientAddressField() {
    setState(() {
      final addr = <String, dynamic>{};
      _initAddressField(addr);
      _clientAddressFields.add(addr);
    });
  }

  void _initAddressField(Map<String, dynamic> addr) {
    addr['line1'] = TextEditingController();
    addr['line2'] = TextEditingController();
    addr['city'] = TextEditingController();
    addr['postalCode'] = TextEditingController();
    addr['selectedType'] = null;
    addr['selectedCountry'] = null;
    addr['selectedState'] = null;
    addr['selectedDistrict'] = null;
    addr['states'] = <StateModel>[];
    addr['districts'] = <DistrictModel>[];
  }

  Future<void> _matchAddressLocations(Map<String, dynamic> addr, AddressModel? details) async {
    if (details == null) return;
    
    // Match Country
    if (_countries.isNotEmpty) {
      final country = _countries.where((c) => c.id == details.countryId).firstOrNull ?? _countries.first;
      setState(() => addr['selectedCountry'] = country);
      
      // Load States
      final states = await _locationService.getStates(country.id);
      if (!mounted) return;
      setState(() {
        addr['states'] = states;
        addr['selectedState'] = states.where((s) => s.id == details.stateId).firstOrNull ?? (states.isNotEmpty ? states.first : null);
      });
      
      // Load Districts
      if (addr['selectedState'] != null) {
        final districts = await _locationService.getDistricts(addr['selectedState']!.id);
        if (!mounted) return;
        setState(() {
          addr['districts'] = districts;
          addr['selectedDistrict'] = districts.where((d) => d.id == details.districtId).firstOrNull ?? (districts.isNotEmpty ? districts.first : null);
        });
      }
    }
  }

  Future<void> _onAddressCountryChanged(Map<String, dynamic> addr, CountryModel? country) async {
    setState(() {
      addr['selectedCountry'] = country;
      addr['selectedState'] = null;
      addr['selectedDistrict'] = null;
      addr['states'] = <StateModel>[];
      addr['districts'] = <DistrictModel>[];
    });
    if (country != null) {
      final states = await _locationService.getStates(country.id);
      if (mounted) setState(() => addr['states'] = states);
    }
    if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
  }

  Future<void> _onAddressStateChanged(Map<String, dynamic> addr, StateModel? state) async {
    setState(() {
      addr['selectedState'] = state;
      addr['selectedDistrict'] = null;
      addr['districts'] = <DistrictModel>[];
    });
    if (state != null) {
      final districts = await _locationService.getDistricts(state.id);
      if (mounted) setState(() => addr['districts'] = districts);
    }
    if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
  }

  void _syncSiteWithClient() async {
    if (!_sameAsClientAddress) return;

    if (_isNewClient) {
      if (_clientAddressFields.isNotEmpty) {
        final firstClientAddr = _clientAddressFields.first;
        setState(() {
          _siteAddress['line1'].text = firstClientAddr['line1'].text;
          _siteAddress['line2'].text = firstClientAddr['line2'].text;
          _siteAddress['city'].text = firstClientAddr['city'].text;
          _siteAddress['postalCode'].text = firstClientAddr['postalCode'].text;
          _siteAddress['selectedType'] = firstClientAddr['selectedType'];
          _siteAddress['selectedCountry'] = firstClientAddr['selectedCountry'];
          _siteAddress['states'] = firstClientAddr['states'];
          _siteAddress['selectedState'] = firstClientAddr['selectedState'];
          _siteAddress['districts'] = firstClientAddr['districts'];
          _siteAddress['selectedDistrict'] = firstClientAddr['selectedDistrict'];
        });
      }
    } else if (_selectedClientId != null) {
      final client = _clients.where((c) => c.id == _selectedClientId).firstOrNull;
      if (client != null && client.addresses.isNotEmpty && client.addresses.first.addressDetails != null) {
        final details = client.addresses.first.addressDetails!;
        _siteAddress['line1'].text = details.line1;
        _siteAddress['line2'].text = details.line2;
        _siteAddress['city'].text = details.city;
        _siteAddress['postalCode'].text = details.postalCode;
        
        setState(() {
          _siteAddress['selectedType'] = _addressTypes.where((t) => t.id == details.addressTypeId).firstOrNull;
          _siteAddress['selectedCountry'] = _countries.where((c) => c.id == details.countryId).firstOrNull;
        });

        if (_siteAddress['selectedCountry'] != null) {
          final states = await _locationService.getStates(_siteAddress['selectedCountry']!.id);
          if (mounted) {
            setState(() {
              _siteAddress['states'] = states;
              _siteAddress['selectedState'] = states.where((s) => s.id == details.stateId).firstOrNull;
            });
            if (_siteAddress['selectedState'] != null) {
              final districts = await _locationService.getDistricts(_siteAddress['selectedState']!.id);
              if (mounted) {
                setState(() {
                  _siteAddress['districts'] = districts;
                  _siteAddress['selectedDistrict'] = districts.where((d) => d.id == details.districtId).firstOrNull;
                });
              }
            }
          }
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final orgId = await TokenManager.getOrganizationId();
      
      Map<String, dynamic>? clientData;
      if (_isNewClient) {
        clientData = {
          "name": _newClientNameController.text.trim(),
          "code": _newClientCodeController.text.trim(),
          "email_input": _clientEmailFields
              .where((f) => f['controller'].text.isNotEmpty)
              .map((f) => {
                    'email': f['controller'].text.trim(),
                    'contact_type': (f['type'] as ContactTypeModel?)?.id,
                  })
              .toList(),
          "mobile_input": _clientMobileFields
              .where((f) => f['controller'].text.isNotEmpty)
              .map((f) => {
                    'number': f['controller'].text.trim(),
                    'contact_type': (f['type'] as ContactTypeModel?)?.id,
                  })
              .toList(),
          "address_input": _clientAddressFields
              .where((f) => f['line1'].text.isNotEmpty && f['selectedDistrict'] != null)
              .map((f) => {
                    'line_1': f['line1'].text.trim(),
                    'line_2': f['line2'].text.trim(),
                    'city': f['city'].text.trim(),
                    'postal_code': f['postalCode'].text.trim(),
                    'district': (f['selectedDistrict'] as DistrictModel).id,
                    'address_type': (f['selectedType'] as AddressTypeModel?)?.id,
                    'is_primary': _clientAddressFields.indexOf(f) == 0,
                  })
              .toList(),
        };
      } else if (_selectedClientId != null) {
        clientData = {
          "client_id": _selectedClientId,
        };
      }

      final List<Map<String, dynamic>> addresses = [];
      if (_siteAddress['line1'].text.isNotEmpty && _siteAddress['selectedDistrict'] != null) {
        addresses.add({
          'line_1': _siteAddress['line1'].text.trim(),
          'line_2': _siteAddress['line2'].text.trim(),
          'city': _siteAddress['city'].text.trim(),
          'postal_code': _siteAddress['postalCode'].text.trim(),
          'district': (_siteAddress['selectedDistrict'] as DistrictModel).id,
          'address_type': (_siteAddress['selectedType'] as AddressTypeModel?)?.id,
          'is_primary': true,
        });
      }

      if (_isEditing) {
        final Map<String, dynamic> payload = {
          "name": _nameController.text.trim(),
          "code": _codeController.text.trim(),
          "status": _selectedStatusId,
          "notes": _notesController.text.trim(),
          "estimated_budget": _budgetController.text.isNotEmpty ? double.tryParse(_budgetController.text) : null,
          "expected_start_date": _expectedStartDate?.toIso8601String().split('T')[0],
          "expected_end_date": _expectedEndDate?.toIso8601String().split('T')[0],
          "addresses": addresses,
          "client_data": clientData,
        };
        await _service.updateSite(
          widget.site!.id, 
          payload,
          newImages: _newPhotos,
          newAttachments: _newAttachments,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site updated successfully!"), backgroundColor: AppColors.success));
          Navigator.pop(context, true);
        }
      } else {
        await _service.onboardSite(
          name: _nameController.text.trim(),
          organizationId: orgId ?? "",
          status: _selectedStatusId,
          budget: double.tryParse(_budgetController.text),
          startDate: _expectedStartDate,
          endDate: _expectedEndDate,
          clientData: clientData,
          notes: _notesController.text.trim(),
          addresses: addresses,
          images: _newPhotos,
          attachments: _newAttachments,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site onboarding completed!"), backgroundColor: AppColors.success));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    _newClientNameController.dispose();
    _newClientCodeController.dispose();
    _disposeAddressField(_siteAddress);
    for (var f in _clientEmailFields) {
      f['controller']?.dispose();
    }
    for (var f in _clientMobileFields) {
      f['controller']?.dispose();
    }
    for (var f in _clientAddressFields) {
      _disposeAddressField(f);
    }
    super.dispose();
  }

  void _disposeAddressField(Map<String, dynamic> addr) {
    addr['line1']?.dispose();
    addr['line2']?.dispose();
    addr['city']?.dispose();
    addr['postalCode']?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEditing ? "Edit Site" : "New Site",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Site Information"),
                    const SizedBox(height: 16),
                    _buildIdentityFields(),

                    const SizedBox(height: 32),
                    _sectionHeader("Project Details"),
                    const SizedBox(height: 16),
                    _buildProjectDetails(),

                    const SizedBox(height: 32),
                    _sectionHeader("Client & Contract"),
                    const SizedBox(height: 16),
                    _buildClientSection(),

                    const SizedBox(height: 32),
                    _sectionHeader("Site Address"),
                    const SizedBox(height: 16),
                    _addressSection(),
                    
                    const SizedBox(height: 32),
                    _sectionHeader("Site Notes"),
                    const SizedBox(height: 16),
                    _field(_notesController, "General notes about the site", maxLines: 3),

                    const SizedBox(height: 32),
                    _sectionHeader("Media & Documents"),
                    const SizedBox(height: 16),
                    _label("PHOTOS"),
                    _buildPhotoPicker(),
                    const SizedBox(height: 24),
                    _label("ATTACHMENTS"),
                    _buildAttachmentSection(),

                    const SizedBox(height: 48),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIdentityFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label("SITE NAME *"),
      _field(_nameController, "e.g. Skyline Tower A", validator: (v) => v!.isEmpty ? "Required" : null),
      const SizedBox(height: 16),
      _label("SITE CODE"),
      _field(_codeController, "e.g. ST-001"),
    ]);
  }

  Widget _buildProjectDetails() {
    return Column(children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label("STATUS"),
          _dropdown<String>(
            value: _selectedStatusId, 
            hint: "Select Status", 
            items: _statusModels.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.toUpperCase()))).toList(), 
            onChanged: (v) => setState(() => _selectedStatusId = v)
          ),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label("ESTIMATED BUDGET"),
          _field(_budgetController, "0.00", keyboardType: TextInputType.number),
        ])),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label("START DATE"),
          _datePicker(selectedDate: _expectedStartDate, onSelect: (d) => setState(() => _expectedStartDate = d)),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label("END DATE"),
          _datePicker(selectedDate: _expectedEndDate, onSelect: (d) => setState(() => _expectedEndDate = d)),
        ])),
      ]),
    ]);
  }

  Widget _addressSection() {
    return _addressForm(_siteAddress, "SITE", isReadOnly: _sameAsClientAddress);
  }

  Widget _addressForm(Map<String, dynamic> addr, String label, {bool isReadOnly = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _label("$label ADDRESS"),
          if (isReadOnly) const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
        ]),
        const SizedBox(height: 8),
        _label("ADDRESS TYPE"),
        _dropdown<AddressTypeModel>(
          value: addr['selectedType'],
          hint: "Select Type",
          items: _addressTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
          onChanged: isReadOnly ? null : (v) {
            setState(() => addr['selectedType'] = v);
            if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
          },
          enabled: !isReadOnly,
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("COUNTRY"), _dropdown<CountryModel>(value: addr['selectedCountry'], hint: "Country", items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: isReadOnly ? null : (v) => _onAddressCountryChanged(addr, v), enabled: !isReadOnly)])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("STATE"), _dropdown<StateModel>(value: addr['selectedState'], hint: "State", items: (addr['states'] as List<StateModel>).map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (isReadOnly || addr['selectedCountry'] == null) ? null : (v) => _onAddressStateChanged(addr, v), enabled: !isReadOnly && addr['selectedCountry'] != null)]))
        ]),
        const SizedBox(height: 16),
        _label("DISTRICT"),
        _dropdown<DistrictModel>(value: addr['selectedDistrict'], hint: "District", items: (addr['districts'] as List<DistrictModel>).map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(), onChanged: (isReadOnly || addr['selectedState'] == null) ? null : (v) {
          setState(() => addr['selectedDistrict'] = v);
          if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
        }, enabled: !isReadOnly && addr['selectedState'] != null),
        const SizedBox(height: 16),
        _label("STREET ADDRESS (LINE 1)"),
        _field(addr['line1'], "Building No., Street Name", enabled: !isReadOnly, onChanged: (v) {
          if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
        }),
        const SizedBox(height: 16),
        _label("ADDRESS LINE 2"),
        _field(addr['line2'], "Suite, Floor, Landmark", enabled: !isReadOnly, onChanged: (v) {
          if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
        }),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("CITY"), _field(addr['city'], "City", enabled: !isReadOnly, onChanged: (v) {
            if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
          })])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("POSTAL CODE"), _field(addr['postalCode'], "Zip", enabled: !isReadOnly, onChanged: (v) {
            if (_sameAsClientAddress && _clientAddressFields.isNotEmpty && addr == _clientAddressFields.first) _syncSiteWithClient();
          })])),
        ]),
      ]),
    );
  }

  Widget _buildClientSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: ChoiceChip(label: const Text("EXISTING CLIENT"), selected: !_isNewClient, onSelected: (val) => setState(() => _isNewClient = !val), selectedColor: AppColors.primary.withValues(alpha: 0.1), labelStyle: TextStyle(color: !_isNewClient ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10))),
          const SizedBox(width: 8),
          Expanded(child: ChoiceChip(label: const Text("NEW CLIENT"), selected: _isNewClient, onSelected: (val) => setState(() => _isNewClient = val), selectedColor: AppColors.primary.withValues(alpha: 0.1), labelStyle: TextStyle(color: _isNewClient ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10))),
        ]),
        const SizedBox(height: 16),
        if (!_isNewClient) ...[
          _label("SELECT CLIENT"),
          _dropdown<String>(value: _selectedClientId, hint: "Choose an existing client", items: _clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(), onChanged: (val) {
            setState(() => _selectedClientId = val);
            if (_sameAsClientAddress) _syncSiteWithClient();
          }),
        ] else ...[
          _label("CLIENT NAME"),
          _field(_newClientNameController, "e.g. Acme Corp", validator: (v) => _isNewClient && (v == null || v.isEmpty) ? "Required" : null),
          const SizedBox(height: 16),
          _label("CLIENT CODE"),
          _field(_newClientCodeController, "e.g. CL-001"),
          const SizedBox(height: 24),
          _clientEmailSection(),
          const SizedBox(height: 24),
          _clientMobileSection(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label("CLIENT ADDRESSES"),
              TextButton.icon(
                onPressed: _addClientAddressField,
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: const Text("Add Address", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          _clientAddressSection(),
        ],
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _sameAsClientAddress,
          onChanged: (v) {
            setState(() => _sameAsClientAddress = v ?? false);
            if (_sameAsClientAddress) _syncSiteWithClient();
          },
          title: const Text("Site address same as client address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal, children: [
      InkWell(
        onTap: () async {
          final picker = ImagePicker();
          final selection = await picker.pickMultiImage();
          if (selection.isNotEmpty) setState(() => _newPhotos.addAll(selection));
        },
        child: Container(width: 100, height: 120, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28), SizedBox(height: 4), Text("Add", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])),
      ),
      ..._newPhotos.map((file) => _mediaThumbnail(file.path, () => setState(() => _newPhotos.remove(file)))),
      if (_isEditing)
        ...widget.site!.photos.map((photo) => _mediaThumbnail(photo.image, null)),
    ]));
  }

  Widget _mediaThumbnail(String path, VoidCallback? onDelete) {
    return Container(width: 100, margin: const EdgeInsets.only(right: 12), child: Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16), 
        child: (kIsWeb || path.startsWith('http'))
          ? Image.network(path, width: 100, height: 120, fit: BoxFit.cover)
          : Image.file(File(path), width: 100, height: 120, fit: BoxFit.cover)
      ),
      if (onDelete != null)
        Positioned(right: 4, top: 4, child: InkWell(onTap: onDelete, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
    ]));
  }

  Widget _buildAttachmentSection() {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: Column(children: [
      if (_isEditing)
        ...widget.site!.attachments.map((att) => ListTile(
          leading: const Icon(Icons.description, color: AppColors.accent),
          title: Text(att.caption, style: const TextStyle(fontSize: 13)),
          trailing: const Icon(Icons.check_circle, color: AppColors.success, size: 16),
        )),
      ..._newAttachments.map((f) => ListTile(leading: const Icon(Icons.upload_file, color: Colors.blue), title: Text(f.name, style: const TextStyle(fontSize: 13)), trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _newAttachments.remove(f))))),
      const Divider(height: 1),
      InkWell(onTap: () async {
        final res = await FilePicker.platform.pickFiles(allowMultiple: true);
        if (res != null) setState(() => _newAttachments.addAll(res.files));
      }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18), SizedBox(width: 8), Text("Upload Documents", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))]))),
    ]));
  }

  Widget _buildSaveButton() {
    return SizedBox(width: double.infinity, height: 58, child: ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? "Update Site" : "Confirm Onboarding", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
    ));
  }

  Widget _sectionHeader(String title, [Widget? action]) {
    return Row(children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(width: 12),
      const Expanded(child: Divider()),
      if (action != null) action,
    ]);
  }

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

  Widget _field(TextEditingController controller, String hint, {TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1, bool enabled = true, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.12))),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error)),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    // Ensure the value exists in items to avoid assertion error
    final bool valueExists = value != null && items.any((item) => item.value == value);
    final T? selectedValue = valueExists ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selectedValue,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          items: enabled ? items : null,
          onChanged: enabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _datePicker({required DateTime? selectedDate, required Function(DateTime) onSelect}) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) onSelect(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                selectedDate == null ? "Select Date" : "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                style: TextStyle(fontSize: 14, color: selectedDate == null ? AppColors.textMuted : AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientEmailSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label("EMAILS"),
        TextButton.icon(onPressed: _addClientEmailField, icon: const Icon(Icons.add, size: 16), label: const Text("Add Email", style: TextStyle(fontSize: 12)))
      ]),
      ..._clientEmailFields.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          Expanded(flex: 2, child: _dropdown<ContactTypeModel>(value: field['type'], hint: "Type", items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setState(() => _clientEmailFields[idx]['type'] = v))),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _field(field['controller'], "email@example.com", keyboardType: TextInputType.emailAddress)),
          if (_clientEmailFields.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => _clientEmailFields.removeAt(idx))),
        ]));
      }),
    ]);
  }

  Widget _clientMobileSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label("MOBILES"),
        TextButton.icon(onPressed: _addClientMobileField, icon: const Icon(Icons.add, size: 16), label: const Text("Add Mobile", style: TextStyle(fontSize: 12)))
      ]),
      ..._clientMobileFields.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          Expanded(flex: 2, child: _dropdown<ContactTypeModel>(value: field['type'], hint: "Type", items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setState(() => _clientMobileFields[idx]['type'] = v))),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _field(field['controller'], "+91 ...", keyboardType: TextInputType.phone)),
          if (_clientMobileFields.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => _clientMobileFields.removeAt(idx))),
        ]));
      }),
    ]);
  }

  Widget _clientAddressSection() {
    return Column(children: _clientAddressFields.asMap().entries.map((entry) {
      int idx = entry.key;
      var f = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _label("ADDRESS #${idx + 1}"),
            if (_clientAddressFields.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _clientAddressFields.removeAt(idx))),
          ]),
          const SizedBox(height: 8),
          _label("ADDRESS TYPE"),
          _dropdown<AddressTypeModel>(value: f['selectedType'], hint: "Select Type", items: _addressTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setState(() => f['selectedType'] = v)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("COUNTRY"), _dropdown<CountryModel>(value: f['selectedCountry'], hint: "Country", items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: (v) => _onAddressCountryChanged(f, v))])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("STATE"), _dropdown<StateModel>(value: f['selectedState'], hint: "State", items: (f['states'] as List<StateModel>).map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: f['selectedCountry'] != null ? (v) => _onAddressStateChanged(f, v) : null, enabled: f['selectedCountry'] != null)]))
          ]),
          const SizedBox(height: 16),
          _label("DISTRICT"),
          _dropdown<DistrictModel>(value: f['selectedDistrict'], hint: "District", items: (f['districts'] as List<DistrictModel>).map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(), onChanged: f['selectedState'] != null ? (v) => setState(() => f['selectedDistrict'] = v) : null, enabled: f['selectedState'] != null),
          const SizedBox(height: 16),
          _label("STREET ADDRESS (LINE 1)"),
          _field(f['line1'], "Building No., Street Name"),
          const SizedBox(height: 16),
          _label("ADDRESS LINE 2"),
          _field(f['line2'], "Suite, Floor, Landmark"),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("CITY"), _field(f['city'], "City")])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("POSTAL CODE"), _field(f['postalCode'], "Zip")])),
          ]),
        ]),
      );
    }).toList());
  }

}
