import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class LocationService extends BaseService {
  static const String baseUrl = '${ApiConstants.mainApiUrl}/shared/';

  List<dynamic> _extractResults(dynamic body) {
    if (body is Map && body.containsKey('results')) {
      return body['results'];
    } else if (body is List) {
      return body;
    }
    return [];
  }

  Future<List<CountryModel>> getCountries() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}countries/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(jsonDecode(response.body));
        return results.map((item) => CountryModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load countries");
      }
    } catch (e) {
      throw Exception("Error fetching countries: $e");
    }
  }

  Future<List<StateModel>> getStates(String countryId) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}states/?country=$countryId'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(jsonDecode(response.body));
        return results.map((item) => StateModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load states");
      }
    } catch (e) {
      throw Exception("Error fetching states: $e");
    }
  }

  Future<List<DistrictModel>> getDistricts(String stateId) async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}districts/?state=$stateId'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(jsonDecode(response.body));
        return results.map((item) => DistrictModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load districts");
      }
    } catch (e) {
      throw Exception("Error fetching districts: $e");
    }
  }

  Future<List<AddressTypeModel>> getAddressTypes() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}address-type/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(jsonDecode(response.body));
        return results.map((item) => AddressTypeModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load address types");
      }
    } catch (e) {
      throw Exception("Error fetching address types: $e");
    }
  }

  Future<List<ContactTypeModel>> getContactTypes() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('${baseUrl}contact-type/'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final List<dynamic> results = _extractResults(jsonDecode(response.body));
        return results.map((item) => ContactTypeModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load contact types");
      }
    } catch (e) {
      throw Exception("Error fetching contact types: $e");
    }
  }
}
