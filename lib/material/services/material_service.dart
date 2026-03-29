import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/material_models.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class MaterialService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/material';

  Future<List<MaterialCategoryModel>> getMaterialCategories() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => MaterialCategoryModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching categories: $e");
    }
  }

  Future<List<MaterialModel>> getMaterials() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/materials/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => MaterialModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load materials: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching materials: $e");
    }
  }

  Future<MaterialModel> getMaterial(int id) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/materials/$id/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return MaterialModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load material: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching material: $e");
    }
  }

  Future<MaterialModel> createMaterial(Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('$baseUrl/materials/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return MaterialModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create material: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating material: $e");
    }
  }

  Future<MaterialModel> updateMaterial(int id, Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(
        Uri.parse('$baseUrl/materials/$id/'),
        headers: headers,
        body: jsonEncode(data),
      ));
      if (response.statusCode == 200) {
        return MaterialModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update material: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating material: $e");
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      final response = await performRequest((headers) => http.delete(
        Uri.parse('$baseUrl/materials/$id/'),
        headers: headers,
      ));
      if (response.statusCode != 204) {
        throw Exception("Failed to delete material: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting material: $e");
    }
  }
}
