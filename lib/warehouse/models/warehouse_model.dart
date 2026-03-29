import 'warehouse_address_model.dart';

class WarehouseEmailModel {
  final String id;
  final String emailId;
  final String email;
  final String? contactTypeId;
  final String? contactTypeName;

  WarehouseEmailModel({
    required this.id,
    required this.emailId,
    required this.email,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory WarehouseEmailModel.fromJson(Map<String, dynamic> json) {
    return WarehouseEmailModel(
      id: json['id']?.toString() ?? '',
      emailId: json['email']?.toString() ?? '',
      email: json['email_str']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: json['contact_type_name']?.toString(),
    );
  }
}

class WarehouseMobileModel {
  final String id;
  final String mobileId;
  final String number;
  final String? contactTypeId;
  final String? contactTypeName;

  WarehouseMobileModel({
    required this.id,
    required this.mobileId,
    required this.number,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory WarehouseMobileModel.fromJson(Map<String, dynamic> json) {
    return WarehouseMobileModel(
      id: json['id']?.toString() ?? '',
      mobileId: json['mobile']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: json['contact_type_name']?.toString(),
    );
  }
}

class WarehouseModel {
  final String id;
  final String name;
  final String code;
  final String organizationId;
  final bool isPrimary;
  final bool isActive;
  final List<WarehouseAddressModel> addressList;
  final List<WarehouseEmailModel> emails;
  final List<WarehouseMobileModel> mobiles;

  WarehouseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.organizationId,
    required this.isPrimary,
    required this.isActive,
    this.addressList = const [],
    this.emails = const [],
    this.mobiles = const [],
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    var addressList = <WarehouseAddressModel>[];
    if (json['addresses'] != null) {
      addressList = (json['addresses'] as List)
          .map((i) => WarehouseAddressModel.fromJson(i))
          .toList();
    } else if (json['address_list'] != null) {
      // Handle legacy key
      addressList = (json['address_list'] as List)
          .map((i) => WarehouseAddressModel.fromJson(i))
          .toList();
    }

    var emailsList = <WarehouseEmailModel>[];
    if (json['emails'] != null) {
      emailsList = (json['emails'] as List)
          .map((i) => WarehouseEmailModel.fromJson(i))
          .toList();
    }

    var mobilesList = <WarehouseMobileModel>[];
    if (json['mobiles'] != null) {
      mobilesList = (json['mobiles'] as List)
          .map((i) => WarehouseMobileModel.fromJson(i))
          .toList();
    }

    return WarehouseModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      organizationId: json['organization']?.toString() ?? '',
      isPrimary: json['is_primary'] ?? false,
      isActive: json['is_active'] ?? true,
      addressList: addressList,
      emails: emailsList,
      mobiles: mobilesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'is_primary': isPrimary,
      'is_active': isActive,
    };
  }

  String get primaryEmail => emails.isNotEmpty ? emails.first.email : '';
  String get primaryPhone => mobiles.isNotEmpty ? mobiles.first.number : '';
}
