import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/site_model.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class SiteService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/site/sites';

  Future<List<SiteModel>> getSites() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        dynamic decoded = jsonDecode(response.body);
        List<dynamic> body;
        if (decoded is Map && decoded.containsKey('results')) {
          body = decoded['results'];
        } else if (decoded is List) {
          body = decoded;
        } else {
          body = [];
        }
        return body.map((dynamic item) => SiteModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load sites: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching sites: $e");
    }
  }

  Future<SiteModel> getSite(String id) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/$id/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return SiteModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load site detail: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching site detail: $e");
    }
  }

  Future<String> getNextCode() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/get-next-code/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['code'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<SiteModel> onboardSite({
    required String name,
    required String organizationId,
    String? status,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? clientData,
    List<Map<String, dynamic>>? addresses,
    List<XFile>? images,
    List<PlatformFile>? attachments,
    String? notes,
  }) async {
    try {
      final response = await performMultipartRequest((headers) async {
        final uri = Uri.parse('$baseUrl/');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.fields['name'] = name;
        request.fields['organization'] = organizationId;
        if (notes != null) request.fields['notes'] = notes;
        if (status != null) request.fields['status'] = status;
        if (budget != null) request.fields['estimated_budget'] = budget.toString();
        if (startDate != null) {
          request.fields['expected_start_date'] = startDate.toIso8601String().split('T')[0];
        }
        if (endDate != null) {
          request.fields['expected_end_date'] = endDate.toIso8601String().split('T')[0];
        }
        if (clientData != null) request.fields['client_data'] = jsonEncode(clientData);
        if (addresses != null) request.fields['addresses'] = jsonEncode(addresses);
        
        if (images != null) {
          for (var i = 0; i < images.length; i++) {
            if (kIsWeb) {
              final bytes = await images[i].readAsBytes();
              request.files.add(http.MultipartFile.fromBytes(
                'images',
                bytes,
                filename: images[i].name,
                contentType: MediaType('image', 'jpeg'),
              ));
            } else {
              request.files.add(await http.MultipartFile.fromPath(
                'images',
                images[i].path,
                contentType: MediaType('image', 'jpeg'),
              ));
            }
          }
        }

        if (attachments != null) {
          for (var file in attachments) {
            if (kIsWeb) {
              if (file.bytes != null) {
                request.files.add(http.MultipartFile.fromBytes(
                  'attachments',
                  file.bytes!,
                  filename: file.name,
                ));
              }
            } else if (file.path != null) {
              request.files.add(await http.MultipartFile.fromPath(
                'attachments',
                file.path!,
              ));
            }
          }
        }
        
        return request;
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SiteModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to onboard site: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error onboarding site: $e');
    }
  }

  Future<SiteModel> updateSite(String id, Map<String, dynamic> data, {List<XFile>? newImages, List<PlatformFile>? newAttachments}) async {
    try {
      final response = await performMultipartRequest((headers) async {
        final uri = Uri.parse('$baseUrl/$id/');
        final request = http.MultipartRequest('PATCH', uri);
        request.headers.addAll(headers);
        
        data.forEach((key, value) {
          if (value != null) {
            if (value is Map || value is List) {
              request.fields[key] = jsonEncode(value);
            } else {
              request.fields[key] = value.toString();
            }
          }
        });

        if (newImages != null) {
          for (var image in newImages) {
            if (kIsWeb) {
              final bytes = await image.readAsBytes();
              request.files.add(http.MultipartFile.fromBytes(
                'images',
                bytes,
                filename: image.name,
                contentType: MediaType('image', 'jpeg'),
              ));
            } else {
              request.files.add(await http.MultipartFile.fromPath(
                'images',
                image.path,
                contentType: MediaType('image', 'jpeg'),
              ));
            }
          }
        }

        if (newAttachments != null) {
          for (var file in newAttachments) {
            if (kIsWeb) {
              if (file.bytes != null) {
                request.files.add(http.MultipartFile.fromBytes(
                  'attachments',
                  file.bytes!,
                  filename: file.name,
                ));
              }
            } else if (file.path != null) {
              request.files.add(await http.MultipartFile.fromPath(
                'attachments',
                file.path!,
              ));
            }
          }
        }
        return request;
      });

      if (response.statusCode == 200) {
        return SiteModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update site: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating site: $e");
    }
  }

  Future<void> assignResource({
    required String siteId,
    required String type, // 'employee' or 'equipment'
    String? id,
    List<String>? ids,
    String? taskId,
  }) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('$baseUrl/$siteId/assign-resource/'),
        headers: headers,
        body: jsonEncode({
          'type': type,
          'id': id,
          'ids': ids,
          'task_id': taskId,
        }),
      ));

      if (response.statusCode != 200) {
        throw Exception('Failed to assign resource: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error assigning resource: $e');
    }
  }

  Future<Map<String, dynamic>> createQuotation({
    required String siteId,
    required double amount,
    Map<String, dynamic>? details,
  }) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('$baseUrl/$siteId/create-quotation/'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'details': details,
        }),
      ));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create quotation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating quotation: $e');
    }
  }

  Future<void> deleteSite(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('$baseUrl/$id/'),
        headers: headers,
      ));
      
      if (response.statusCode != 204) {
        throw Exception("Failed to delete site: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting site: $e");
    }
  }

  Future<List<SiteTaskModel>> getTasks(String siteId) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${ApiConstants.mainApiUrl}/site/tasks/?site=$siteId'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => SiteTaskModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<SiteTaskModel> createTask(Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('${ApiConstants.mainApiUrl}/site/tasks/'),
        headers: headers,
        body: jsonEncode(data),
      ));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SiteTaskModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<void> toggleTaskItem(String itemId) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('${ApiConstants.mainApiUrl}/site/task-items/$itemId/toggle-completion/'),
        headers: headers,
      ));

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle task item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error toggling task item: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('${ApiConstants.mainApiUrl}/site/tasks/$id/'),
        headers: headers,
      ));
      
      if (response.statusCode != 204) {
        throw Exception("Failed to delete task: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting task: $e");
    }
  }

  Future<List<SiteStatusModel>> getSiteStatuses() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/statuses/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => SiteStatusModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
