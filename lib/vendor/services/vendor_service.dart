import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vendor_model.dart';
import '../../shared/services/base_service.dart';
import '../../auth/services/token_manager.dart';

import '../../core/constants/api_constants.dart';

class VendorService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/vendor/vendors/';

  Future<List<VendorModel>> getVendors({String? organizationId}) async {
    try {
      Uri url = Uri.parse(baseUrl);
      if (organizationId != null) {
        url = url.replace(queryParameters: {'organization': organizationId});
      }

      final response = await performRequest((headers) => http.get(url, headers: headers));

      if (response.statusCode == 200) {
        dynamic body = jsonDecode(response.body);
        
        List<dynamic> results;
        if (body is Map && body.containsKey('results')) {
          results = body['results'];
        } else if (body is List) {
          results = body;
        } else {
          results = [];
        }
        
        return results.map((dynamic item) => VendorModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load vendors: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching vendors: $e");
    }
  }

  Future<VendorModel> createVendor(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) {
          data['organization'] = orgId;
        }
      }
      
      final response = await performRequest((headers) => http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(data),
      ));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return VendorModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create vendor: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating vendor: $e");
    }
  }

  Future<VendorModel> updateVendor(String id, Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) {
          data['organization'] = orgId;
        }
      }

      final response = await performRequest((headers) => http.patch(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
        body: jsonEncode(data),
      ));

      if (response.statusCode == 200) {
        return VendorModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update vendor: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating vendor: $e");
    }
  }

  Future<void> deleteVendor(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
      ));
      if (response.statusCode != 204) {
        throw Exception("Failed to delete vendor: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting vendor: $e");
    }
  }

  Future<String> getNextCode() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}get-next-code/'), 
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'];
      }
      throw Exception("Failed to get next code: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error getting next code: $e");
    }
  }

  Future<VendorModel> getVendor(String id) async {
    try {
      final response = await performRequest((headers) => http.get(Uri.parse('$baseUrl$id/'), headers: headers));
      if (response.statusCode == 200) {
        return VendorModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load vendor: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching vendor: $e");
    }
  }
}
