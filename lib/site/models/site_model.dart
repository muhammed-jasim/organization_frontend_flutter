import '../../shared/models/location_models.dart';
import '../../employee/models/employee_model.dart';
import '../../equipment/models/equipment_model.dart';
import '../../client/models/client_model.dart';

class SiteStatusModel {
  final String id;
  final String name;
  final String code;
  final String description;

  SiteStatusModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
  });

  factory SiteStatusModel.fromJson(Map<String, dynamic> json) {
    return SiteStatusModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class SiteMediaModel {
  final String id;
  final String image;
  final String caption;
  final DateTime createdAt;

  SiteMediaModel({
    required this.id,
    required this.image,
    required this.caption,
    required this.createdAt,
  });

  factory SiteMediaModel.fromJson(Map<String, dynamic> json) {
    return SiteMediaModel(
      id: json['id']?.toString() ?? '',
      image: json['image'] ?? json['file'] ?? '',
      caption: json['caption'] ?? json['description'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SiteModel {
  final String id;
  final String name;
  final String code;
  final String status;
  final SiteStatusModel? statusDetails;
  final String? organizationId;
  final ClientLinkModel? clientLink;
  final List<SiteMediaModel> photos;
  final List<SiteMediaModel> attachments;
  final List<QuotationModel> quotations;
  final List<SiteEmployeeModel> employees;
  final List<SiteEquipmentModel> equipments;
  final List<SiteTaskModel> tasks;
  final List<SiteNoteModel> siteNotes;
  final List<AddressModel> addresses;
  final double? estimatedBudget;
  final String? notes;
  final DateTime? expectedStartDate;
  final DateTime? expectedEndDate;
  final DateTime createdAt;

  SiteModel({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.statusDetails,
    this.organizationId,
    this.clientLink,
    this.photos = const [],
    this.attachments = const [],
    this.quotations = const [],
    this.employees = const [],
    this.equipments = const [],
    this.tasks = const [],
    this.siteNotes = const [],
    this.addresses = const [],
    this.estimatedBudget,
    this.notes,
    this.expectedStartDate,
    this.expectedEndDate,
    required this.createdAt,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      status: json['status']?.toString() ?? '',
      statusDetails: json['status_details'] != null 
          ? SiteStatusModel.fromJson(json['status_details']) 
          : null,
      organizationId: json['organization']?.toString(),
      clientLink: json['client_link'] != null
          ? ClientLinkModel.fromJson(json['client_link'])
          : null,
      photos: json['photos'] != null 
          ? (json['photos'] as List).map((i) => SiteMediaModel.fromJson(i)).toList()
          : [],
      attachments: json['attachments'] != null 
          ? (json['attachments'] as List).map((i) => SiteMediaModel.fromJson(i)).toList()
          : [],
      quotations: json['quotations'] != null
          ? (json['quotations'] as List).map((i) => QuotationModel.fromJson(i)).toList()
          : [],
      employees: (json['employees'] as List?)?.map((e) => SiteEmployeeModel.fromJson(e)).toList() ?? [],
      equipments: (json['equipments'] as List?)?.map((e) => SiteEquipmentModel.fromJson(e)).toList() ?? [],
      tasks: (json['tasks'] as List?)?.map((p) => SiteTaskModel.fromJson(p)).toList() ?? [],
      siteNotes: (json['site_notes'] as List?)?.map((n) => SiteNoteModel.fromJson(n)).toList() ?? [],
      addresses: (json['addresses'] as List?)?.map((a) => AddressModel.fromJson(a)).toList() ?? [],
      estimatedBudget: json['estimated_budget'] != null ? double.tryParse(json['estimated_budget'].toString()) : null,
      notes: json['notes'],
      expectedStartDate: json['expected_start_date'] != null ? DateTime.tryParse(json['expected_start_date']) : null,
      expectedEndDate: json['expected_end_date'] != null ? DateTime.tryParse(json['expected_end_date']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status,
      'organization': organizationId,
      'estimated_budget': estimatedBudget,
      'notes': notes,
      'expected_start_date': expectedStartDate?.toIso8601String().split('T')[0],
      'expected_end_date': expectedEndDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ClientLinkModel {
  final String id;
  final String clientId;
  final String? clientName;
  final ClientModel? client;

  ClientLinkModel({
    required this.id,
    required this.clientId,
    this.clientName,
    this.client,
  });

  factory ClientLinkModel.fromJson(Map<String, dynamic> json) {
    String cId = '';
    if (json['client'] != null) {
      if (json['client'] is Map) {
        cId = json['client']['id']?.toString() ?? '';
      } else {
        cId = json['client'].toString();
      }
    }

    return ClientLinkModel(
      id: json['id']?.toString() ?? '',
      clientId: cId,
      clientName: json['client_name']?.toString() ?? (json['client'] is Map ? json['client']['name'] : null),
      client: json['client'] != null && json['client'] is Map 
          ? ClientModel.fromJson(json['client'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class QuotationModel {
  final String id;
  final String status;
  final double totalAmount;
  final DateTime? sentAt;

  QuotationModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    this.sentAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at']) : null,
    );
  }
}
class SiteEmployeeModel {
  final String id;
  final EmployeeModel? employee;
  final String? taskId;

  SiteEmployeeModel({required this.id, this.employee, this.taskId});

  factory SiteEmployeeModel.fromJson(Map<String, dynamic> json) {
    return SiteEmployeeModel(
      id: json['id']?.toString() ?? '',
      employee: json['employee'] != null ? EmployeeModel.fromJson(json['employee']) : null,
      taskId: json['task']?.toString() ?? json['task_id']?.toString() ?? json['phase_id']?.toString(),
    );
  }
}

class SiteEquipmentModel {
  final String id;
  final EquipmentModel? equipment;
  final String? taskId;

  SiteEquipmentModel({required this.id, this.equipment, this.taskId});

  factory SiteEquipmentModel.fromJson(Map<String, dynamic> json) {
    return SiteEquipmentModel(
      id: json['id']?.toString() ?? '',
      equipment: json['equipment'] != null ? EquipmentModel.fromJson(json['equipment']) : null,
      taskId: json['task']?.toString() ?? json['task_id']?.toString() ?? json['phase_id']?.toString(),
    );
  }
}

class SiteTaskModel {
  final String id;
  final String siteId;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final double completionPercentage;
  final List<SiteTaskChecklistItemModel> items;

  SiteTaskModel({
    required this.id,
    required this.siteId,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.completionPercentage = 0,
    this.items = const [],
  });

  factory SiteTaskModel.fromJson(Map<String, dynamic> json) {
    return SiteTaskModel(
      id: json['id']?.toString() ?? '',
      siteId: json['site']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      completionPercentage: double.tryParse(json['completion_percentage']?.toString() ?? '0') ?? 0.0,
      items: (json['items'] as List?)
              ?.map((i) => SiteTaskChecklistItemModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class SiteTaskChecklistItemModel {
  final String id;
  final String taskId;
  final String title;
  final int order;
  final bool isMandatory;
  final bool isCompleted;

  SiteTaskChecklistItemModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.order = 0,
    this.isMandatory = true,
    this.isCompleted = false,
  });

  factory SiteTaskChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return SiteTaskChecklistItemModel(
      id: json['id']?.toString() ?? '',
      taskId: json['task']?.toString() ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      isMandatory: json['is_mandatory'] ?? true,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class SiteNoteModel {
  final String id;
  final String? siteId;
  final String note;
  final DateTime createdAt;

  SiteNoteModel({
    required this.id,
    this.siteId,
    required this.note,
    required this.createdAt,
  });

  factory SiteNoteModel.fromJson(Map<String, dynamic> json) {
    return SiteNoteModel(
      id: json['id']?.toString() ?? '',
      siteId: json['site']?.toString(),
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
