import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../../shared/services/base_service.dart';

import '../../core/constants/api_constants.dart';

class ProfileService extends BaseService {
  // Use the same base url structure as AuthService. Adjust if necessary.
  static const String baseUrl = ApiConstants.userEndpoint;

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load profile: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching profile: $e");
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await performRequest((headers) => http.patch(
        Uri.parse('$baseUrl/profile/'),
        headers: headers,
        body: jsonEncode(data),
      ));

      if (response.statusCode == 200) {
        return true;
      } else {
        String errorMsg = "Failed to update profile (${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
             if (errorData.containsKey('detail')) {
               errorMsg = errorData['detail'];
             } else if (errorData.containsKey('error')) {
               errorMsg = errorData['error'];
             } else {
               errorMsg = errorData.values.expand((v) => v is List ? v : [v]).join(', ');
             }
          }
        } catch (_) {
          String fallbackError = response.body;
          if (fallbackError.length > 100) {
            fallbackError = fallbackError.substring(0, 100) + '... (Server Error)';
          }
           errorMsg = "$errorMsg: $fallbackError";
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
       if (e.toString().contains("Exception:")) {
         throw Exception(e.toString().replaceFirst("Exception: ", ""));
      }
      throw Exception("Error updating profile: $e");
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await performRequest((headers) => http.post(
        Uri.parse('$baseUrl/change-password/'),
        headers: headers,
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      ));

      if (response.statusCode == 200) {
        return true;
      } else {
        String errorMsg = "Failed to change password (${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
             if (errorData.containsKey('detail')) {
               errorMsg = errorData['detail'];
             } else if (errorData.containsKey('error')) {
               errorMsg = errorData['error'];
             } else {
               errorMsg = errorData.values.expand((v) => v is List ? v : [v]).join(', ');
             }
          }
        } catch (_) {
          String fallbackError = response.body;
          if (fallbackError.length > 100) {
            fallbackError = fallbackError.substring(0, 100) + '... (Server Error)';
          }
           errorMsg = "$errorMsg: $fallbackError";
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e.toString().contains("Exception:")) {
         throw Exception(e.toString().replaceFirst("Exception: ", ""));
      }
      throw Exception("Error changing password: $e");
    }
  }
}
