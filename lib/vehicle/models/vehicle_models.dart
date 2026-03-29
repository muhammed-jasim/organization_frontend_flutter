import '../../shared/models/attachment_model.dart';

class VehicleModel {
  final String id;
  final String make;
  final String model;
  final int? year;
  final String licensePlate;
  final String? vin;
  final String vehicleType;
  final bool isActive;
  final String organization;
  final String? assignedTo;
  final VehicleContactModel? contactInfo;
  final VehiclePaymentOptionModel? paymentOption;
  final List<VehiclePhotoModel> photos;
  final List<AttachmentModel> attachments;

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    this.year,
    required this.licensePlate,
    this.vin,
    required this.vehicleType,
    required this.isActive,
    required this.organization,
    this.assignedTo,
    this.contactInfo,
    this.paymentOption,
    this.photos = const [],
    this.attachments = const [],
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id']?.toString() ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'],
      licensePlate: json['license_plate'] ?? '',
      vin: json['vin'],
      vehicleType: json['vehicle_type'] ?? '',
      isActive: json['is_active'] ?? true,
      organization: json['organization']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString(),
      contactInfo: json['contact_info'] != null 
          ? VehicleContactModel.fromJson(json['contact_info']) 
          : null,
      paymentOption: json['payment_option'] != null 
          ? VehiclePaymentOptionModel.fromJson(json['payment_option']) 
          : null,
      photos: (json['photos'] as List?)?.map((p) => VehiclePhotoModel.fromJson(p)).toList() ?? [],
      attachments: (json['attachments'] as List?)?.map((a) => AttachmentModel.fromJson(a)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'vin': vin,
      'vehicle_type': vehicleType,
      'is_active': isActive,
      'organization': organization,
      'assigned_to': assignedTo,
      'contact_info': contactInfo?.toJson(),
      'payment_option': paymentOption?.toJson(),
    };
  }
}

class VehiclePhotoModel {
  final String id;
  final String imageUrl;
  final bool isPrimary;

  VehiclePhotoModel({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
  });

  factory VehiclePhotoModel.fromJson(Map<String, dynamic> json) {
    return VehiclePhotoModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class VehicleContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String address;
  final String contactType;

  VehicleContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.address,
    required this.contactType,
  });

  factory VehicleContactModel.fromJson(Map<String, dynamic> json) {
    return VehicleContactModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      address: json['address'] ?? '',
      contactType: json['contact_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'contact_type': contactType,
    };
  }
}

class VehiclePaymentOptionModel {
  final String id;
  final double rate;
  final String currency;
  final String terms;
  final String paymentType;

  VehiclePaymentOptionModel({
    required this.id,
    required this.rate,
    required this.currency,
    required this.terms,
    required this.paymentType,
  });

  factory VehiclePaymentOptionModel.fromJson(Map<String, dynamic> json) {
    return VehiclePaymentOptionModel(
      id: json['id']?.toString() ?? '',
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'INR',
      terms: json['terms'] ?? '',
      paymentType: json['payment_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rate': rate,
      'currency': currency,
      'terms': terms,
      'payment_type': paymentType,
    };
  }
}
