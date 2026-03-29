import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client_model.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class ClientService extends BaseService {
  static const String _base = '${ApiConstants.mainApiUrl}/client/clients/';

  Future<List<ClientModel>> getClients() async {
    try {
      final response = await performRequest((headers) => http.get(Uri.parse(_base), headers: headers));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> results = body is Map && body.containsKey('results') ? body['results'] : (body is List ? body : []);
        return results.whereType<Map<String, dynamic>>().map((i) => ClientModel.fromJson(i)).toList();
      }
      throw Exception("Failed to load clients: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching clients: $e");
    }
  }

  Future<ClientModel> getClient(String id) async {
    try {
      final response = await performRequest((headers) => http.get(Uri.parse('$_base$id/'), headers: headers));
      if (response.statusCode == 200) {
        return ClientModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load client: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching client: $e");
    }
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.post(Uri.parse(_base), headers: headers, body: jsonEncode(data)));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ClientModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to create client: ${response.body}");
    } catch (e) {
      throw Exception("Error creating client: $e");
    }
  }

  Future<ClientModel> updateClient(String id, Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(Uri.parse('$_base$id/'), headers: headers, body: jsonEncode(data)));
      if (response.statusCode == 200) {
        return ClientModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to update client: ${response.body}");
    } catch (e) {
      throw Exception("Error updating client: $e");
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      final response = await performRequest((headers) => http.delete(Uri.parse('$_base$id/'), headers: headers));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception("Failed to delete client: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error deleting client: $e");
    }
  }

  Future<String> getNextCode() async {
    try {
      final response = await performRequest((headers) => http.get(Uri.parse('${_base}get-next-code/'), headers: headers));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'];
      }
      throw Exception("Failed to get next code: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error getting next code: $e");
    }
  }
}
