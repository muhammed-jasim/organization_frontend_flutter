import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

import '../../core/constants/api_constants.dart';

class AuthService {
  static const String authBaseUrl = ApiConstants.userEndpoint;
  // Use http://10.0.2.2:8000/api/v1/accounts/user for local Android Emulator testing if needed

  Future<bool> requestOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Error requesting OTP: $e");
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access'];
        final refresh = data['refresh'];
        if (token != null) {
          await TokenManager.saveAccessToken(token);
          if (refresh != null) await TokenManager.saveRefreshToken(refresh);
          return true;
        }
      }
      return false;
    } catch (e) {
      throw Exception("Error verifying OTP: $e");
    }
  }

  Future<bool> registerWithPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobile,
    required String dob,
  }) async {
    try {
      final url = Uri.parse('$authBaseUrl/password-signup/');
      final payload = {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': mobile,
        'dob': _formatDateForDjango(dob),
      };

      print('----- DEBUG REGISTER API -----');
      print('URL: $url');
      print('Payload: $payload');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('------------------------------');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access'];
        final refresh = data['refresh'];
        if (token != null) {
          await TokenManager.saveAccessToken(token);
          if (refresh != null) await TokenManager.saveRefreshToken(refresh);
          return true;
        }
      } else {
        String errorMsg = "Registration failed (${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
             // Handle our custom global exception format or DRF validation errors
             if (errorData.containsKey('detail')) {
               errorMsg = errorData['detail'];
             } else if (errorData.containsKey('error')) {
               errorMsg = errorData['error'];
             } else {
               errorMsg = errorData.values.expand((v) => v is List ? v : [v]).join(', ');
             }
          }
        } catch (_) {
          // Fallback if not JSON
          String fallbackError = response.body;
          if (fallbackError.length > 100) {
            fallbackError = fallbackError.substring(0, 100) + '... (Server Error)';
          }
          errorMsg = "$errorMsg: $fallbackError";
        }
        
        throw Exception(errorMsg);
      }
      return false;
    } catch (e) {
      if (e.toString().contains("Exception:")) {
         throw Exception(e.toString().replaceFirst("Exception: ", ""));
      }
      throw Exception("Error registering: $e");
    }
  }

  Future<bool> loginWithPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/password-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access'];
        final refresh = data['refresh'];
        if (token != null) {
          await TokenManager.saveAccessToken(token);
          if (refresh != null) await TokenManager.saveRefreshToken(refresh);
          return true;
        }
      } else {
        String errorMsg = "Login failed (${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
             // Handle our custom global exception format or DRF validation errors
             if (errorData.containsKey('detail')) {
               errorMsg = errorData['detail'];
             } else if (errorData.containsKey('error')) {
               errorMsg = errorData['error'];
             } else {
               errorMsg = errorData.values.expand((v) => v is List ? v : [v]).join(', ');
             }
          }
        } catch (_) {
          // Fallback if not JSON
          String fallbackError = response.body;
          if (fallbackError.length > 100) {
            fallbackError = fallbackError.substring(0, 100) + '... (Server Error)';
          }
          errorMsg = "$errorMsg: $fallbackError";
        }
        
        throw Exception(errorMsg);
      }
      return false;
    } catch (e) {
      if (e.toString().contains("Exception:")) {
         throw Exception(e.toString().replaceFirst("Exception: ", ""));
      }
      throw Exception("Error logging in: $e");
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refresh = await TokenManager.getRefreshToken();
      if (refresh == null) return false;

      final response = await http.post(
        Uri.parse('$authBaseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access'];
        if (token != null) {
          await TokenManager.saveAccessToken(token);
          // SimpleJWT rotation might return a new refresh token
          if (data['refresh'] != null) {
            await TokenManager.saveRefreshToken(data['refresh']);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Token refresh error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await TokenManager.clearToken();
    } catch (e) {
      throw Exception("Error logging out: $e");
    }
  }

  // Helper to convert DD/MM/YYYY to YYYY-MM-DD for Django
  String _formatDateForDjango(String originalDate) {
    if (originalDate.isEmpty) return originalDate;
    try {
      final parts = originalDate.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (_) {}
    return originalDate; // fallback
  }
}
