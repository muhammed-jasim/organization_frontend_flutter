import '../../shared/models/attachment_model.dart';

class EquipmentCategoryModel {
  final String id;
  final String name;
  final String code;

  EquipmentCategoryModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory EquipmentCategoryModel.fromJson(Map<String, dynamic> json) {
    return EquipmentCategoryModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class EquipmentStatusModel {
  final String id;
  final String name;
  final String code;

  EquipmentStatusModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory EquipmentStatusModel.fromJson(Map<String, dynamic> json) {
    return EquipmentStatusModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class EquipmentOwnershipTypeModel {
  final String id;
  final String name;
  final String code;

  EquipmentOwnershipTypeModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory EquipmentOwnershipTypeModel.fromJson(Map<String, dynamic> json) {
    return EquipmentOwnershipTypeModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class EquipmentVendorModel {
  final String? id;
  final String vendorId;
  final String? vendorName;
  final String rentalStartDate;
  final String? rentalEndDate;
  final String rentalRatePerDay;
  final String? securityDeposit;
  final String? notes;

  EquipmentVendorModel({
    this.id,
    required this.vendorId,
    this.vendorName,
    required this.rentalStartDate,
    this.rentalEndDate,
    required this.rentalRatePerDay,
    this.securityDeposit,
    this.notes,
  });

  factory EquipmentVendorModel.fromJson(Map<String, dynamic> json) {
    return EquipmentVendorModel(
      id: json['id']?.toString(),
      vendorId: json['vendor']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString(),
      rentalStartDate: json['rental_start_date'] ?? '',
      rentalEndDate: json['rental_end_date'],
      rentalRatePerDay: json['rental_rate_per_day']?.toString() ?? '0',
      securityDeposit: json['security_deposit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendorId,
      'rental_start_date': rentalStartDate,
      'rental_end_date': rentalEndDate,
      'rental_rate_per_day': rentalRatePerDay,
      'security_deposit': securityDeposit,
    };
  }
}

class EquipmentPhotoModel {
  final String id;
  final String imageUrl;
  final bool isPrimary;
  final String? description;

  EquipmentPhotoModel({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    this.description,
  });

  factory EquipmentPhotoModel.fromJson(Map<String, dynamic> json) {
    return EquipmentPhotoModel(
      id: json['id'].toString(),
      imageUrl: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      description: json['description'],
    );
  }
}

class EquipmentModel {
  final String id;
  final String name;
  final String code;
  final String categoryId;
  final String statusId;
  final String ownershipTypeId;
  final String? purchaseDate;
  final String? purchaseCost;
  final String? notes;
  final bool isActive;
  final EquipmentCategoryModel? categoryDetail;
  final EquipmentStatusModel? statusDetail;
  final EquipmentOwnershipTypeModel? ownershipTypeDetail;
  final EquipmentVendorModel? rentalDetails;
  final List<EquipmentPhotoModel> photos;
  final List<AttachmentModel> attachments;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.categoryId,
    required this.statusId,
    required this.ownershipTypeId,
    this.purchaseDate,
    this.purchaseCost,
    this.notes,
    required this.isActive,
    this.categoryDetail,
    this.statusDetail,
    this.ownershipTypeDetail,
    this.rentalDetails,
    this.photos = const [],
    this.attachments = const [],
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      categoryId: json['category']?.toString() ?? '',
      statusId: json['status']?.toString() ?? '',
      ownershipTypeId: json['ownership_type']?.toString() ?? '',
      purchaseDate: json['purchase_date'],
      purchaseCost: json['purchase_cost']?.toString(),
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      categoryDetail: json['category_detail'] != null ? EquipmentCategoryModel.fromJson(json['category_detail']) : null,
      statusDetail: json['status_detail'] != null ? EquipmentStatusModel.fromJson(json['status_detail']) : null,
      ownershipTypeDetail: json['ownership_type_detail'] != null ? EquipmentOwnershipTypeModel.fromJson(json['ownership_type_detail']) : null,
      rentalDetails: json['rental_details'] != null ? EquipmentVendorModel.fromJson(json['rental_details']) : null,
      photos: (json['photos'] as List?)?.map((p) => EquipmentPhotoModel.fromJson(p)).toList() ?? [],
      attachments: (json['attachments'] as List?)?.map((a) => AttachmentModel.fromJson(a)).toList() ?? [],
    );
  }
}
