import '../../shared/models/attachment_model.dart';
import '../../shared/models/location_models.dart';

class EmployeeModel {
  final String id;
  final String firstName;
  final String lastName;
  final List<MobileModel> mobiles;
  final List<EmailModel> emails;
  final List<AddressModel> addresses;
  final double expectedSalary;
  final String displayName;
  final List<EmployeePhotoModel> photos;
  final List<AttachmentModel> attachments; 
  final String? jobRoleName;
  final String? employeeCode;
  final String status;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.firstName,
    this.lastName = '',
    this.mobiles = const [],
    this.emails = const [],
    this.addresses = const [],
    this.expectedSalary = 0.0,
    required this.displayName,
    this.photos = const [],
    this.attachments = const [],
    this.jobRoleName,
    this.employeeCode,
    this.status = 'active',
    this.isActive = true,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      mobiles: json['mobiles'] != null 
          ? (json['mobiles'] as List).map((m) => MobileModel.fromJson(m)).toList()
          : [],
      emails: json['emails'] != null 
          ? (json['emails'] as List).map((e) => EmailModel.fromJson(e)).toList()
          : [],
      addresses: json['addresses'] != null 
          ? (json['addresses'] as List).map((a) => AddressModel.fromJson(a)).toList()
          : [],
      expectedSalary: json['expected_salary'] != null 
          ? double.tryParse(json['expected_salary'].toString()) ?? 0.0 
          : 0.0,
      displayName: json['display_name'] ?? json['first_name'] ?? 'Unknown',
      photos: json['photos'] != null 
          ? (json['photos'] as List).map((p) => EmployeePhotoModel.fromJson(p)).toList()
          : [],
      attachments: json['attachments'] != null 
          ? (json['attachments'] as List).map((a) => AttachmentModel.fromJson(a)).toList()
          : [],
      jobRoleName: json['job_role_name']?.toString(),
      employeeCode: json['employee_code']?.toString(),
      status: json['status'] ?? 'active',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'expected_salary': expectedSalary,
      'is_active': isActive,
    };
  }
}

class EmployeePhotoModel {
  final String id;
  final String imageUrl;
  final bool isPrimary;
  final String? description;

  EmployeePhotoModel({
    required this.id,
    required this.imageUrl,
    this.isPrimary = false,
    this.description,
  });

  factory EmployeePhotoModel.fromJson(Map<String, dynamic> json) {
    return EmployeePhotoModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      description: json['description'],
    );
  }
}
