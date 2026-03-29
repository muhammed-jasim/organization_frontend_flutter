import '../../warehouse/models/warehouse_address_model.dart';

class VendorEmailModel {
  final String id;
  final String emailId;
  final String email;
  final String? contactTypeId;
  final String? contactTypeName;

  VendorEmailModel({
    required this.id,
    required this.emailId,
    required this.email,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory VendorEmailModel.fromJson(Map<String, dynamic> json) {
    return VendorEmailModel(
      id: json['id']?.toString() ?? '',
      emailId: json['email']?.toString() ?? '',
      email: json['email_str']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: json['contact_type_name']?.toString(),
    );
  }
}

class VendorMobileModel {
  final String id;
  final String mobileId;
  final String number;
  final String? contactTypeId;
  final String? contactTypeName;

  VendorMobileModel({
    required this.id,
    required this.mobileId,
    required this.number,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory VendorMobileModel.fromJson(Map<String, dynamic> json) {
    return VendorMobileModel(
      id: json['id']?.toString() ?? '',
      mobileId: json['mobile']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: json['contact_type_name']?.toString(),
    );
  }
}

class VendorModel {
  final String id;
  final String name;
  final String code;
  final String? organizationId;
  final bool isActive;
  final List<WarehouseAddressModel> addressList;
  final List<VendorEmailModel> emails;
  final List<VendorMobileModel> mobiles;

  VendorModel({
    required this.id,
    required this.name,
    required this.code,
    this.organizationId,
    required this.isActive,
    this.addressList = const [],
    this.emails = const [],
    this.mobiles = const [],
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    var addressList = <WarehouseAddressModel>[];
    if (json['addresses'] != null) {
      addressList = (json['addresses'] as List)
          .map((i) => WarehouseAddressModel.fromJson(i))
          .toList();
    }

    var emailsList = <VendorEmailModel>[];
    if (json['emails'] != null) {
      emailsList = (json['emails'] as List)
          .map((i) => VendorEmailModel.fromJson(i))
          .toList();
    }

    var mobilesList = <VendorMobileModel>[];
    if (json['mobiles'] != null) {
      mobilesList = (json['mobiles'] as List)
          .map((i) => VendorMobileModel.fromJson(i))
          .toList();
    }

    return VendorModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      organizationId: json['organization']?.toString(),
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
      'is_active': isActive,
    };
  }

  String get primaryEmail => emails.isNotEmpty ? emails.first.email : '';
  String get primaryPhone => mobiles.isNotEmpty ? mobiles.first.number : '';
}
