class CountryModel {
  final String id;
  final String name;
  final String code;

  CountryModel({
    required this.id,
    required this.name,
    this.code = '',
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is CountryModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class StateModel {
  final String id;
  final String name;
  final String code;
  final String countryId;

  StateModel({
    required this.id,
    required this.name,
    this.code = '',
    required this.countryId,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      // Sometimes it might come back as a nested object, so handle both ID or nested object
      countryId: (json['country'] is Map) 
          ? json['country']['id']?.toString() ?? ''
          : json['country']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is StateModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class DistrictModel {
  final String id;
  final String name;
  final String code;
  final String stateId;

  DistrictModel({
    required this.id,
    required this.name,
    this.code = '',
    required this.stateId,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      stateId: (json['state'] is Map) 
          ? json['state']['id']?.toString() ?? ''
          : json['state']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is DistrictModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class AddressTypeModel {
  final String id;
  final String name;
  final String code;

  AddressTypeModel({
    required this.id,
    required this.name,
    this.code = '',
  });

  factory AddressTypeModel.fromJson(Map<String, dynamic> json) {
    return AddressTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is AddressTypeModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class ContactTypeModel {
  final String id;
  final String name;

  ContactTypeModel({
    required this.id,
    required this.name,
  });

  factory ContactTypeModel.fromJson(Map<String, dynamic> json) {
    return ContactTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is ContactTypeModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class EmailModel {
  final String id;
  final String email;
  final String? contactTypeId;
  final String? contactTypeName;

  EmailModel({
    required this.id,
    required this.email,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    return EmailModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      contactTypeId: (json['contact_type'] is Map) 
          ? json['contact_type']['id']?.toString() 
          : json['contact_type']?.toString(),
      contactTypeName: (json['contact_type'] is Map)
          ? json['contact_type']['name']?.toString()
          : null,
    );
  }
}

class MobileModel {
  final String id;
  final String number;
  final String? contactTypeId;
  final String? contactTypeName;

  MobileModel({
    required this.id,
    required this.number,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory MobileModel.fromJson(Map<String, dynamic> json) {
    return MobileModel(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? '',
      contactTypeId: (json['contact_type'] is Map) 
          ? json['contact_type']['id']?.toString() 
          : json['contact_type']?.toString(),
      contactTypeName: (json['contact_type'] is Map)
          ? json['contact_type']['name']?.toString()
          : null,
    );
  }
}

class AddressModel {
  final String id;
  final String line1;
  final String line2;
  final String districtId;
  final String? districtName;
  final String city;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final String? addressTypeId;
  final String? addressTypeName;
  final String? stateId;
  final String? stateName;
  final String? countryId;
  final String? countryName;
  final bool isPrimary;

  AddressModel({
    required this.id,
    required this.line1,
    required this.line2,
    required this.districtId,
    this.districtName,
    required this.city,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.addressTypeId,
    this.addressTypeName,
    this.stateId,
    this.stateName,
    this.countryId,
    this.countryName,
    this.isPrimary = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? districtMap = json['district'] is Map ? json['district'] as Map<String, dynamic> : null;
    Map<String, dynamic>? stateMap = districtMap?['state'] is Map ? districtMap!['state'] as Map<String, dynamic> : null;
    Map<String, dynamic>? countryMap = stateMap?['country'] is Map ? stateMap!['country'] as Map<String, dynamic> : null;

    return AddressModel(
      id: json['id']?.toString() ?? '',
      line1: json['line_1'] ?? '',
      line2: json['line_2'] ?? '',
      districtId: districtMap?['id']?.toString() ?? json['district']?.toString() ?? '',
      districtName: districtMap?['name']?.toString(),
      city: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      addressTypeId: (json['address_type'] is Map) 
          ? json['address_type']['id']?.toString() 
          : json['address_type']?.toString(),
      addressTypeName: (json['address_type'] is Map)
          ? json['address_type']['name']?.toString()
          : null,
      stateId: stateMap?['id']?.toString() ?? json['state_id']?.toString(),
      stateName: stateMap?['name']?.toString(),
      countryId: countryMap?['id']?.toString() ?? json['country_id']?.toString(),
      countryName: countryMap?['name']?.toString(),
      isPrimary: json['is_primary'] ?? false,
    );
  }
}
