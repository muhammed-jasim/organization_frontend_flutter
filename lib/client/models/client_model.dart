import '../../shared/models/location_models.dart';


class ClientEmailModel {
  final String id;
  final String emailId;
  final String email;
  final String? contactTypeId;
  final String? contactTypeName;

  ClientEmailModel({
    required this.id,
    required this.emailId,
    required this.email,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory ClientEmailModel.fromJson(Map<String, dynamic> json) {
    String? contactTypeName = json['contact_type_name']?.toString();
    if (contactTypeName == null && json['contact_type_details'] is Map) {
      contactTypeName = (json['contact_type_details'] as Map)['name']?.toString();
    }
    
    return ClientEmailModel(
      id: json['id']?.toString() ?? '',
      emailId: json['email']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: contactTypeName,
    );
  }
}

class ClientMobileModel {
  final String id;
  final String mobileId;
  final String number;
  final String? contactTypeId;
  final String? contactTypeName;

  ClientMobileModel({
    required this.id,
    required this.mobileId,
    required this.number,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory ClientMobileModel.fromJson(Map<String, dynamic> json) {
    String? contactTypeName = json['contact_type_name']?.toString();
    if (contactTypeName == null && json['contact_type_details'] is Map) {
      contactTypeName = (json['contact_type_details'] as Map)['name']?.toString();
    }

    return ClientMobileModel(
      id: json['id']?.toString() ?? '',
      mobileId: json['mobile']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: contactTypeName,
    );
  }
}

class ClientAddressModel {
  final String id;
  final String addressId;
  final AddressModel? addressDetails;

  ClientAddressModel({
    required this.id,
    required this.addressId,
    this.addressDetails,
  });

  factory ClientAddressModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('line_1')) {
      return ClientAddressModel(
        id: json['id']?.toString() ?? '',
        addressId: json['id']?.toString() ?? '',
        addressDetails: AddressModel.fromJson(json),
      );
    }
    return ClientAddressModel(
      id: json['id']?.toString() ?? '',
      addressId: json['address']?.toString() ?? '',
      addressDetails: json['address_details'] != null 
          ? AddressModel.fromJson(json['address_details'])
          : null,
    );
  }
}

class ClientModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final List<ClientAddressModel> addresses;
  final List<ClientEmailModel> emails;
  final List<ClientMobileModel> mobiles;

  ClientModel({
    required this.id,
    required this.name,
    required this.code,
    this.isActive = true,
    this.addresses = const [],
    this.emails = const [],
    this.mobiles = const [],
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {

    List<ClientAddressModel> addresses = [];
    if (json['addresses'] != null && json['addresses'] is List) {
      addresses = (json['addresses'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => ClientAddressModel.fromJson(a))
          .toList();
    }

    List<ClientEmailModel> emails = [];
    if (json['emails'] != null && json['emails'] is List) {
      emails = (json['emails'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ClientEmailModel.fromJson(e))
          .toList();
    }

    List<ClientMobileModel> mobiles = [];
    if (json['mobiles'] != null && json['mobiles'] is List) {
      mobiles = (json['mobiles'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => ClientMobileModel.fromJson(m))
          .toList();
    }

    return ClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      addresses: addresses,
      emails: emails,
      mobiles: mobiles,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'is_active': isActive,
  };

  String get primaryEmail => emails.isNotEmpty ? emails.first.email : '';
  String get primaryPhone => mobiles.isNotEmpty ? mobiles.first.number : '';
}
