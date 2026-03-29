import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment_model.dart';
import '../../shared/models/attachment_model.dart';
import '../../shared/services/base_service.dart';
import '../../auth/services/token_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_constants.dart';

class EquipmentService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/equipments/';

  Future<EquipmentModel> getEquipment(String id) async {
    try {
      final response = await performRequest((headers) => http.get(Uri.parse('${baseUrl}equipments/$id/'), headers: headers));
      if (response.statusCode == 200) {
        return EquipmentModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load equipment details");
    } catch (e) {
      throw Exception("Error fetching equipment: $e");
    }
  }

  Future<List<EquipmentModel>> getEquipments({Map<String, String>? filters}) async {
    try {
      Uri url = Uri.parse('${baseUrl}equipments/');
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
        List<dynamic> results = body is Map ? body['results'] : body;
        return results.map((item) => EquipmentModel.fromJson(item)).toList();
      }
      throw Exception("Failed to load equipments");
    } catch (e) {
      throw Exception("Error fetching equipments: $e");
    }
  }

  Future<List<EquipmentCategoryModel>> getCategories() async {
    try {
      final url = Uri.parse('${baseUrl}categories/');
      final response = await performRequest((headers) => http.get(url, headers: headers));
      if (response.statusCode == 200) {
        dynamic decoded = jsonDecode(response.body);
        List<dynamic> results = decoded is Map ? decoded['results'] : decoded;
        return results.map((item) => EquipmentCategoryModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<EquipmentStatusModel>> getStatuses() async {
    try {
      final url = Uri.parse('${baseUrl}status/');
      final response = await performRequest((headers) => http.get(url, headers: headers));
      if (response.statusCode == 200) {
        dynamic decoded = jsonDecode(response.body);
        List<dynamic> results = decoded is Map ? decoded['results'] : decoded;
        return results.map((item) => EquipmentStatusModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<EquipmentOwnershipTypeModel>> getOwnershipTypes() async {
    try {
      final url = Uri.parse('${baseUrl}ownership-type/');
      final response = await performRequest((headers) => http.get(url, headers: headers));
      if (response.statusCode == 200) {
        dynamic decoded = jsonDecode(response.body);
        List<dynamic> results = decoded is Map ? decoded['results'] : decoded;
        return results.map((item) => EquipmentOwnershipTypeModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<EquipmentModel> createEquipment(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) data['organization'] = orgId;
      }
      final response = await performRequest((headers) => http.post(
        Uri.parse('${baseUrl}equipments/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return EquipmentModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to create equipment: ${response.body}");
    } catch (e) {
      throw Exception("Error creating equipment: $e");
    }
  }

  Future<EquipmentModel> updateEquipment(String id, Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(
        Uri.parse('${baseUrl}equipments/$id/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      if (response.statusCode == 200) {
        return EquipmentModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to update equipment: ${response.body}");
    } catch (e) {
      throw Exception("Error updating equipment: $e");
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('${baseUrl}equipments/$id/'),
        headers: headers,
      ));
      if (response.statusCode != 204) {
        throw Exception("Failed to delete equipment");
      }
    } catch (e) {
      throw Exception("Error deleting equipment: $e");
    }
  }

  Future<List<EquipmentPhotoModel>> uploadPhotos(String equipmentId, List<XFile> images) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}equipments/$equipmentId/upload-photos/'));
      final headers = await getHeaders();
      request.headers.addAll(headers);
      
      for (var image in images) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'images', 
          bytes,
          filename: image.name,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        List<dynamic> results = jsonDecode(response.body);
        return results.map((item) => EquipmentPhotoModel.fromJson(item)).toList();
      }
      throw Exception("Failed to upload photos");
    } catch (e) {
      throw Exception("Error uploading photos: $e");
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('${baseUrl}equipments/delete-photo/'),
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

  Future<List<AttachmentModel>> uploadAttachments(String equipmentId, List<PlatformFile> files) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}equipments/$equipmentId/upload-attachments/'));
      final headers = await getHeaders();
      request.headers.addAll(headers);
      
      for (var file in files) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'files', 
            file.bytes!,
            filename: file.name,
            contentType: MediaType('application', 'octet-stream'),
          ));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        List<dynamic> results = jsonDecode(response.body);
        return results.map((item) => AttachmentModel.fromJson(item)).toList();
      }
      throw Exception("Failed to upload attachments");
    } catch (e) {
      throw Exception("Error uploading attachments: $e");
    }
  }

  Future<void> deleteAttachment(String attachmentId) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('${baseUrl}equipments/delete-attachment/'),
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
        Uri.parse('${baseUrl}equipments/get-next-code/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['code'];
      }
      return '';
    } catch (e) { return ''; }
  }
}
