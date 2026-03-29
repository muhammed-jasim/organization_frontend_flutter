import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/services/token_manager.dart';
import '../models/organization_model.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class OrganizationService extends BaseService {
  // Using same base host as auth for now
  static const String baseUrl = ApiConstants.mainApiUrl;

  Future<OrganizationModel?> getCurrentOrganization() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/organization/organizations/current/'),
        headers: headers,
      ));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final org = OrganizationModel.fromJson(data);
        await TokenManager.saveOrganizationDetails(
          id: org.id,
          name: org.name,
          logo: org.logo,
        );
        return org;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception("Failed to load current organization (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching current organization: $e");
    }
  }

  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/organization/organizations/'),
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
        return results.map((item) => OrganizationModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load organizations (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching organizations: $e");
    }
  }

  Future<List<OrganizationTypeModel>> getOrganizationTypes() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/organization/types/'),
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
        return results.map((item) => OrganizationTypeModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load organization types");
      }
    } catch (e) {
      throw Exception("Error fetching organization types: $e");
    }
  }

  Future<List<UserOrganizationRoleModel>> getRoles() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/organization/roles/'),
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
        return results.map((item) => UserOrganizationRoleModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load organization roles");
      }
    } catch (e) {
      throw Exception("Error fetching organization roles: $e");
    }
  }

  Future<List<CountryModel>> getCountries() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/shared/countries/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CountryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<StateModel>> getStates(String countryId) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/shared/states/?country=$countryId'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StateModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DistrictModel>> getDistricts(String stateId) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/shared/districts/?state=$stateId'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DistrictModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<AddressTypeModel>> getAddressTypes() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/shared/address-type/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AddressTypeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<OrganizationModel> createOrganization(
    String name,
    String typeId, {
    List<Map<String, dynamic>>? addresses,
    XFile? logo,
  }) async {
    try {
      final response = await performMultipartRequest((headers) async {
        final uri = Uri.parse('$baseUrl/organization/organizations/');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.fields['name'] = name;
        request.fields['type'] = typeId;
        if (addresses != null && addresses.isNotEmpty) {
          request.fields['addresses_json'] = jsonEncode(addresses);
        }
        if (logo != null) {
          if (kIsWeb) {
            final bytes = await logo.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'logo',
              bytes,
              filename: logo.name,
              contentType: MediaType('image', 'jpeg'),
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'logo',
              logo.path,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        }
        return request;
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final org = OrganizationModel.fromJson(jsonDecode(response.body));
        await TokenManager.saveOrganizationDetails(
          id: org.id,
          name: org.name,
          logo: org.logo,
        );
        return org;
      } else {
        throw Exception("Failed to create organization: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating organization: $e");
    }
  }

  Future<void> switchOrganization(String orgId) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('$baseUrl/organization/organizations/$orgId/switch/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        await getCurrentOrganization();
      } else {
        throw Exception("Failed to switch organization (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      throw Exception("Error switching organization: $e");
    }
  }

  Future<OrganizationModel> updateOrganization(
    String id, {
    String? name,
    String? typeId,
    XFile? logo,
  }) async {
    try {
      final response = await performMultipartRequest((headers) async {
        final uri = Uri.parse('$baseUrl/organization/organizations/$id/');
        final request = http.MultipartRequest('PATCH', uri);
        request.headers.addAll(headers);
        if (name != null) request.fields['name'] = name;
        if (typeId != null) request.fields['type'] = typeId;
        if (logo != null) {
          if (kIsWeb) {
            final bytes = await logo.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'logo',
              bytes,
              filename: logo.name,
              contentType: MediaType('image', 'jpeg'),
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'logo',
              logo.path,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        }
        return request;
      });
      
      if (response.statusCode == 200) {
        final org = OrganizationModel.fromJson(jsonDecode(response.body));
        final currentId = await TokenManager.getOrganizationId();
        if (currentId == org.id) {
          await TokenManager.saveOrganizationDetails(
            id: org.id,
            name: org.name,
            logo: org.logo,
          );
        }
        return org;
      } else {
        throw Exception("Failed to update organization: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating organization: $e");
    }
  }

  Future<void> updateOrgAddresses(
    String orgId,
    List<Map<String, dynamic>> addresses,
  ) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('$baseUrl/organization/organizations/$orgId/update-addresses/'),
        headers: headers,
        body: jsonEncode({'addresses': addresses}),
      ));

      if (response.statusCode != 200) {
        throw Exception("Failed to update addresses (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating addresses: $e");
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/organization/organizations/dashboard-stats/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to load dashboard stats (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching dashboard stats: $e");
    }
  }
}
