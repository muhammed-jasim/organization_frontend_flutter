import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import '../../shared/services/base_service.dart';
import '../../auth/services/token_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';

class EmployeeService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/employee/';

  Future<EmployeeModel> getEmployee(String id) async {
    try {
      final response = await performRequest((headers) => http.get(Uri.parse('$baseUrl$id/'), headers: headers));
      if (response.statusCode == 200) {
        return EmployeeModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load employee details");
    } catch (e) {
      throw Exception("Error fetching employee: $e");
    }
  }

  Future<List<EmployeeModel>> getEmployees({Map<String, String>? filters}) async {
    try {
      Uri url = Uri.parse(baseUrl);
      if (filters != null) {
        url = url.replace(queryParameters: filters);
      } else {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) {
          url = url.replace(queryParameters: {'organization': orgId});
        }
      }

      final response = await performRequest((headers) => http.get(url, headers: headers));

      if (response.statusCode == 200) {
        dynamic body = jsonDecode(response.body);
        List<dynamic> results = body is Map ? (body['results'] ?? []) : body;
        return results.map((item) => EmployeeModel.fromJson(item)).toList();
      }
      throw Exception("Failed to load employees");
    } catch (e) {
      throw Exception("Error fetching employees: $e");
    }
  }

  Future<EmployeeModel> createEmployee(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) data['organization'] = orgId;
      }
      final response = await performRequest((headers) => http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(data),
      ));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return EmployeeModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create employee: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating employee: $e");
    }
  }

  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      if (response.statusCode == 200) {
        return EmployeeModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to update employee: ${response.body}");
    } catch (e) {
      throw Exception("Error updating employee: $e");
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
      ));
      if (response.statusCode != 204) {
        throw Exception("Failed to delete employee");
      }
    } catch (e) {
      throw Exception("Error deleting employee: $e");
    }
  }

  Future<void> uploadPhotos(String employeeId, List<XFile> photos) async {
    try {
      await performMultipartRequest((headers) async {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$employeeId/upload_photos/'));
        request.headers.addAll(headers);
        for (var photo in photos) {
          request.files.add(await http.MultipartFile.fromPath(
            'photos',
            photo.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
        return request;
      });
    } catch (e) {
      throw Exception("Error uploading photos: $e");
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('${baseUrl}delete_photo/'),
        headers: headers,
        body: jsonEncode({'photo_id': photoId}),
      ));
      if (response.statusCode != 200) {
        throw Exception("Failed to delete photo");
      }
    } catch (e) {
      throw Exception("Error deleting photo: $e");
    }
  }

  Future<void> uploadAttachments(String employeeId, List<PlatformFile> files) async {
    try {
      await performMultipartRequest((headers) async {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$employeeId/upload_attachments/'));
        request.headers.addAll(headers);
        for (var file in files) {
          if (file.path != null) {
            request.files.add(await http.MultipartFile.fromPath(
              'attachments',
              file.path!,
            ));
          }
        }
        return request;
      });
    } catch (e) {
      throw Exception("Error uploading attachments: $e");
    }
  }

  Future<void> deleteAttachment(String attachmentId) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('${baseUrl}delete_attachment/'),
        headers: headers,
        body: jsonEncode({'attachment_id': attachmentId}),
      ));
      if (response.statusCode != 200) {
        throw Exception("Failed to delete attachment");
      }
    } catch (e) {
      throw Exception("Error deleting attachment: $e");
    }
  }

  Future<String> getNextCode() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}get_next_code/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['code'] ?? '';
      }
      return '';
    } catch (e) { return ''; }
  }
}
