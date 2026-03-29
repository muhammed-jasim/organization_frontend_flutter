import '../../shared/models/location_models.dart';

class SubcontractorAddressModel {
  final String id;
  final String subcontractorId;
  final AddressModel? addressDetails;

  SubcontractorAddressModel({
    required this.id,
    required this.subcontractorId,
    this.addressDetails,
  });

  factory SubcontractorAddressModel.fromJson(Map<String, dynamic> json) {
    return SubcontractorAddressModel(
      id: json['id']?.toString() ?? '',
      subcontractorId: json['subcontractor']?.toString() ?? '',
      addressDetails: json['address_details'] != null 
          ? AddressModel.fromJson(json['address_details']) 
          : null,
    );
  }
}

class SubcontractorEmailModel {
  final String id;
  final String emailId;
  final String email;
  final String? contactTypeId;
  final String? contactTypeName;

  SubcontractorEmailModel({
    required this.id,
    required this.emailId,
    required this.email,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory SubcontractorEmailModel.fromJson(Map<String, dynamic> json) {
    return SubcontractorEmailModel(
      id: json['id']?.toString() ?? '',
      emailId: json['email']?.toString() ?? '',
      email: json['email_str']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: json['contact_type_name']?.toString(),
    );
  }
}

class SubcontractorMobileModel {
  final String id;
  final String mobileId;
  final String number;
  final String? contactTypeId;
  final String? contactTypeName;

  SubcontractorMobileModel({
    required this.id,
    required this.mobileId,
    required this.number,
    this.contactTypeId,
    this.contactTypeName,
  });

  factory SubcontractorMobileModel.fromJson(Map<String, dynamic> json) {
    return SubcontractorMobileModel(
      id: json['id']?.toString() ?? '',
      mobileId: json['mobile']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      contactTypeId: json['contact_type']?.toString(),
      contactTypeName: json['contact_type_name']?.toString(),
    );
  }
}

class SubcontractorModel {
  final String id;
  final String name;
  final String specialization;
  
  final bool isActive;
  final String organizationId;

  final List<SubcontractorAddressModel> addresses;
  final List<SubcontractorEmailModel> emails;
  final List<SubcontractorMobileModel> mobiles;

  SubcontractorModel({
    required this.id,
    required this.name,
    this.specialization = '',
    this.isActive = true,
    required this.organizationId,
    this.addresses = const [],
    this.emails = const [],
    this.mobiles = const [],
  });

  factory SubcontractorModel.fromJson(Map<String, dynamic> json) {
    var addrList = <SubcontractorAddressModel>[];
    if (json['addresses'] != null) {
      addrList = (json['addresses'] as List)
          .map((i) => SubcontractorAddressModel.fromJson(i))
          .toList();
    }

    var emailList = <SubcontractorEmailModel>[];
    if (json['emails'] != null) {
      emailList = (json['emails'] as List)
          .map((i) => SubcontractorEmailModel.fromJson(i))
          .toList();
    }

    var mobileList = <SubcontractorMobileModel>[];
    if (json['mobiles'] != null) {
      mobileList = (json['mobiles'] as List)
          .map((i) => SubcontractorMobileModel.fromJson(i))
          .toList();
    }

    return SubcontractorModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      isActive: json['is_active'] ?? true,
      organizationId: json['organization']?.toString() ?? '',
      addresses: addrList,
      emails: emailList,
      mobiles: mobileList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'is_active': isActive,
    };
  }

  String get primaryEmail => emails.isNotEmpty ? emails.first.email : '';
  String get primaryPhone => mobiles.isNotEmpty ? mobiles.first.number : '';
}
