import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subcontractor_model.dart';
import '../../shared/services/base_service.dart';
import '../../auth/services/token_manager.dart';

import '../../core/constants/api_constants.dart';

class SubcontractorService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/subcontractor/subcontractors/';

  Future<List<SubcontractorModel>> getSubcontractors() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse(baseUrl),
        headers: headers,
      ));
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
        
        return results.map((dynamic item) => SubcontractorModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load subcontractors: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching subcontractors: $e");
    }
  }

  Future<SubcontractorModel> createSubcontractor(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) {
          data['organization'] = orgId;
        } else {
          data['organization'] = 1; 
        }
      }
      
      final response = await performRequest((headers) => http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(data),
      ));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SubcontractorModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create subcontractor: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating subcontractor: $e");
    }
  }

  Future<SubcontractorModel> updateSubcontractor(String id, Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      
      if (response.statusCode == 200) {
        return SubcontractorModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update subcontractor: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating subcontractor: $e");
    }
  }

  Future<SubcontractorModel> getSubcontractor(String id) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return SubcontractorModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load subcontractor: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching subcontractor: $e");
    }
  }

  Future<void> deleteSubcontractor(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('$baseUrl$id/'),
        headers: headers,
      ));
      if (response.statusCode != 204) {
        throw Exception("Failed to delete subcontractor: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting subcontractor: $e");
    }
  }
}
