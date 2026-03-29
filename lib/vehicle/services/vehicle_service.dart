import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vehicle_models.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class VehicleService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/vehicle/vehicles/';

  Future<List<VehicleModel>> getVehicles({String? organizationId}) async {
    try {
      String url = baseUrl;
      if (organizationId != null) {
        url += '?organization=$organizationId';
      }
      final response = await performRequest((headers) => http.get(Uri.parse(url), headers: headers));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load vehicles: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching vehicles: $e");
    }
  }

  Future<VehicleModel> getVehicle(String id) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return VehicleModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load vehicle: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching vehicle: $e");
    }
  }

  Future<void> uploadPhotos(String vehicleId, List<XFile> photos) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$vehicleId/upload_photos/'));
      final headers = await getHeaders();
      request.headers.addAll(headers);

      for (var photo in photos) {
        request.files.add(await http.MultipartFile.fromPath('photos', photo.path));
      }

      final response = await request.send();
      if (response.statusCode != 201) {
        final body = await response.stream.bytesToString();
        throw Exception("Failed to upload photos: $body");
      }
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
        throw Exception("Failed to delete photo: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting photo: $e");
    }
  }

  Future<void> uploadAttachments(String vehicleId, List<PlatformFile> files) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$vehicleId/upload_attachments/'));
      final headers = await getHeaders();
      request.headers.addAll(headers);

      for (var file in files) {
        if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath('attachments', file.path!));
        }
      }

      final response = await request.send();
      if (response.statusCode != 201) {
        final body = await response.stream.bytesToString();
        throw Exception("Failed to upload attachments: $body");
      }
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
        throw Exception("Failed to delete attachment: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting attachment: $e");
    }
  }

  Future<VehicleModel> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(data),
      ));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return VehicleModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create vehicle: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating vehicle: $e");
    }
  }

  Future<VehicleModel> updateVehicle(String id, Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      
      if (response.statusCode == 200) {
        return VehicleModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update vehicle: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating vehicle: $e");
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
      ));
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception("Failed to delete vehicle: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting vehicle: $e");
    }
  }

  Future<Map<String, dynamic>> getVehicleFormData({String? organizationId}) async {
    try {
      String url = '${baseUrl}form_data/';
      if (organizationId != null) {
        url += '?organization=$organizationId';
      }
      final response = await performRequest((headers) => http.get(Uri.parse(url), headers: headers));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return {'contact_types': [], 'payment_types': []};
    } catch (e) {
      return {'contact_types': [], 'payment_types': []};
    }
  }
}
