export '../../shared/models/location_models.dart';

class OrganizationTypeModel {
  final String id;
  final String name;

  OrganizationTypeModel({
    required this.id,
    required this.name,
  });

  factory OrganizationTypeModel.fromJson(Map<String, dynamic> json) {
    return OrganizationTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizationTypeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserOrganizationRoleModel {
  final String id;
  final String name;
  final String code;

  UserOrganizationRoleModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory UserOrganizationRoleModel.fromJson(Map<String, dynamic> json) {
    return UserOrganizationRoleModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserOrganizationRoleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents the nested address object returned by the backend
class OrgAddressModel {
  final String orgAddressId; // OrganizationAddress.id
  final String? addressId;
  final String line1;
  final String line2;
  final String city;
  final String postalCode;
  final String districtId;
  final String districtName;
  final String stateId;
  final String stateName;
  final String countryId;
  final String countryName;
  final String? addressTypeId;
  final String? addressTypeName;
  final bool isPrimary;

  OrgAddressModel({
    required this.orgAddressId,
    this.addressId,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.postalCode,
    required this.districtId,
    required this.districtName,
    required this.stateId,
    required this.stateName,
    required this.countryId,
    required this.countryName,
    this.addressTypeId,
    this.addressTypeName,
    this.isPrimary = false,
  });

  factory OrgAddressModel.fromJson(Map<String, dynamic> json) {
    // Backend returns: { id, address: { line_1, line_2, city, postal_code, district: { id, name, state: { id, name, country: { id, name } } }, address_type: {...}, is_primary } }
    final addr = json['address'] as Map<String, dynamic>? ?? {};
    final district = addr['district'];
    final districtMap = district is Map<String, dynamic> ? district : <String, dynamic>{};
    final state = districtMap['state'];
    final stateMap = state is Map<String, dynamic> ? state : <String, dynamic>{};
    final country = stateMap['country'];
    final countryMap = country is Map<String, dynamic> ? country : <String, dynamic>{};
    final addrType = addr['address_type'];
    final addrTypeMap = addrType is Map<String, dynamic> ? addrType : null;

    return OrgAddressModel(
      orgAddressId: json['id']?.toString() ?? '',
      addressId: addr['id']?.toString(),
      line1: addr['line_1'] ?? '',
      line2: addr['line_2'] ?? '',
      city: addr['city'] ?? '',
      postalCode: addr['postal_code'] ?? '',
      districtId: districtMap['id']?.toString() ?? '',
      districtName: districtMap['name'] ?? '',
      stateId: stateMap['id']?.toString() ?? '',
      stateName: stateMap['name'] ?? '',
      countryId: countryMap['id']?.toString() ?? '',
      countryName: countryMap['name'] ?? '',
      addressTypeId: addrTypeMap?['id']?.toString(),
      addressTypeName: addrTypeMap?['name'],
      isPrimary: addr['is_primary'] ?? false,
    );
  }
}

class OrganizationModel {
  final String id;
  final String name;
  final OrganizationTypeModel? type;
  final String? logo;
  final bool isActive;
  final List<OrgAddressModel> addresses;

  OrganizationModel({
    required this.id,
    required this.name,
    this.type,
    this.logo,
    this.isActive = true,
    this.addresses = const [],
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    OrganizationTypeModel? typeModel;
    if (json['type'] != null) {
      if (json['type'] is Map<String, dynamic>) {
        typeModel = OrganizationTypeModel.fromJson(json['type']);
      } else {
        // Handle case where it's a String ID
        typeModel = OrganizationTypeModel(
          id: json['type'].toString(),
          name: '', // Placeholder name
        );
      }
    }

    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: typeModel,
      logo: json['logo']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((a) => OrgAddressModel.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type?.id,
      'logo': logo,
      'is_active': isActive,
      'addresses': addresses.map((a) => a.districtId).toList(),
    };
  }
}
