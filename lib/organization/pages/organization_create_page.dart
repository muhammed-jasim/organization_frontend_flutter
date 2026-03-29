import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../services/organization_service.dart';
import '../models/organization_model.dart';

class OrganizationCreatePage extends StatefulWidget {
  const OrganizationCreatePage({super.key});

  @override
  State<OrganizationCreatePage> createState() => _OrganizationCreatePageState();
}

class _OrganizationCreatePageState extends State<OrganizationCreatePage> {
  final _formKeyDetails = GlobalKey<FormState>();
  final _formKeyAddress = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  // Step 1: Details
  final _nameController = TextEditingController();
  
  // Step 2: Address
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  int _currentStep = 0;
  XFile? _logo;
  final _picker = ImagePicker();
  
  final OrganizationService _organizationService = OrganizationService();
  
  bool _isLoading = false;
  
  // Data lists
  List<OrganizationTypeModel> _types = [];
  List<CountryModel> _countries = [];
  List<StateModel> _states = [];
  List<DistrictModel> _districts = [];
  List<AddressTypeModel> _addressTypes = [];

  // Selections
  OrganizationTypeModel? _selectedType;
  CountryModel? _selectedCountry;
  StateModel? _selectedState;
  DistrictModel? _selectedDistrict;
  AddressTypeModel? _selectedAddressType;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _organizationService.getOrganizationTypes(),
        _organizationService.getCountries(),
        _organizationService.getAddressTypes(),
      ]);

      if (mounted) {
        setState(() {
          _types = results[0] as List<OrganizationTypeModel>;
          _countries = results[1] as List<CountryModel>;
          _addressTypes = results[2] as List<AddressTypeModel>;
          
          if (_types.isNotEmpty) _selectedType = _types.first;
          if (_addressTypes.isNotEmpty) _selectedAddressType = _addressTypes.first;
        });
      }
    } catch (e) {
      _showError('Failed to load initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      _isLoading = true;
    });

    try {
      final states = await _organizationService.getStates(country.id);
      if (mounted) {
        setState(() => _states = states);
      }
    } catch (e) {
      _showError('Failed to load states: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onStateChanged(StateModel? state) async {
    if (state == null) return;
    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _districts = [];
      _isLoading = true;
    });

    try {
      final districts = await _organizationService.getDistricts(state.id);
      if (mounted) {
        setState(() => _districts = districts);
      }
    } catch (e) {
      _showError('Failed to load districts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logo = image);
    }
  }

  Future<void> _createOrganization() async {
    if (!_formKeyAddress.currentState!.validate()) return;
    
    if (_selectedDistrict == null) {
      _showError('Please select a district');
      return;
    }

    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> addresses = [
      {
        'line_1': _addressLine1Controller.text.trim(),
        'line_2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'district': _selectedDistrict!.id,
        'address_type': _selectedAddressType?.id,
        'is_primary': true,
      }
    ];

    try {
      await _organizationService.createOrganization(
        _nameController.text.trim(),
        _selectedType!.id,
        addresses: addresses,
        logo: _logo,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKeyDetails.currentState!.validate() && _selectedType != null) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      } else if (_selectedType == null) {
        _showError('Please select an organization type');
      }
    } else {
      _createOrganization();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: _previousStep,
        ),
        title: _buildStepIndicator(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading && _types.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                _buildDetailsStep(),
                _buildAddressStep(),
              ],
            ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        bool isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: index == _currentStep ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildDetailsStep() {
    return _stepWrapper(
      title: "Organization Basics",
      subtitle: "Provide the core information about your company.",
      fields: [
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surface,
                  backgroundImage: _logo != null 
                    ? (kIsWeb ? NetworkImage(_logo!.path) : FileImage(File(_logo!.path)) as ImageProvider)
                    : null,
                  child: _logo == null ? const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.textMuted) : null,
                ),
              ),
              if (_logo != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _logo = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildFieldLabel("ORGANIZATION NAME"),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: "e.g., Acme Construction",
            prefixIcon: Icon(Icons.business, size: 20),
          ),
          validator: (v) => v!.isEmpty ? "Name is required" : null,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel("ORGANIZATION TYPE"),
        _buildDropdown<OrganizationTypeModel>(
          value: _selectedType,
          hint: "Select Type",
          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
          onChanged: (v) => setState(() => _selectedType = v),
        ),
      ],
      onNext: _nextStep,
      nextLabel: "Continue to Address",
    );
  }

  Widget _buildAddressStep() {
    return _stepWrapper(
      title: "Registered Address",
      subtitle: "This information is required for tax and legal identification.",
      fields: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel("COUNTRY"),
                  _buildDropdown<CountryModel>(
                    value: _selectedCountry,
                    hint: "Select Country",
                    items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: _onCountryChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel("STATE"),
                  _buildDropdown<StateModel>(
                    value: _selectedState,
                    hint: "Select State",
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                    onChanged: _onStateChanged,
                    enabled: _selectedCountry != null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel("DISTRICT"),
                  _buildDropdown<DistrictModel>(
                    value: _selectedDistrict,
                    hint: "Select District",
                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                    onChanged: (v) => setState(() => _selectedDistrict = v),
                    enabled: _selectedState != null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel("ADDRESS TYPE"),
                  _buildDropdown<AddressTypeModel>(
                    value: _selectedAddressType,
                    hint: "e.g., Head Office",
                    items: _addressTypes.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                    onChanged: (v) => setState(() => _selectedAddressType = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildFieldLabel("STREET ADDRESS (LINE 1)"),
        TextFormField(
          controller: _addressLine1Controller,
          decoration: const InputDecoration(hintText: "Building No, Street Name"),
          validator: (v) => v!.isEmpty ? "Address Line 1 is required" : null,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel("ADDRESS LINE 2 (OPTIONAL)"),
        TextFormField(
          controller: _addressLine2Controller,
          decoration: const InputDecoration(hintText: "Suite, Floor, Landmark"),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel("CITY"),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(hintText: "City"),
                    validator: (v) => v!.isEmpty ? "City is required" : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel("POSTAL CODE"),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(hintText: "Zip"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      onNext: _nextStep,
      nextLabel: "Create Organization",
      formKey: _formKeyAddress,
    );
  }

  Widget _stepWrapper({
    required String title,
    required String subtitle,
    required List<Widget> fields,
    required VoidCallback onNext,
    required String nextLabel,
    GlobalKey<FormState>? formKey,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Form(
                key: formKey ?? _formKeyDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    const SizedBox(height: 32),
                    ...fields,
                    const Spacer(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : onNext,
                        child: _isLoading && _currentStep == 1
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(nextLabel),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.2)),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: enabled ? items : null,
          onChanged: enabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
