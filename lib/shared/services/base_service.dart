import 'package:http/http.dart' as http;
import '../../../auth/services/token_manager.dart';
import '../../../auth/services/auth_service.dart';

abstract class BaseService {
  Future<Map<String, String>> getHeaders() async {
    final token = await TokenManager.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Centralized request handler that handles token refresh on 401 Unauthorized errors.
  Future<http.Response> performRequest(
    Future<http.Response> Function(Map<String, String> headers) requestFn,
  ) async {
    // 1. Get initial headers with current access token
    final headers = await getHeaders();

    // 2. Perform the initial request
    var response = await requestFn(headers);

    // 3. If 401 Unauthorized, attempt to refresh the token
    if (response.statusCode == 401) {
      final success = await AuthService().refreshToken();

      if (success) {
        // 4. If refresh succeeded, get new headers and retry the request once
        final newHeaders = await getHeaders();
        response = await requestFn(newHeaders);
      } else {
        // 5. If refresh fails, clear tokens (logout)
        await TokenManager.clearAll();
        // Optional: Trigger a navigation to login or throw a specific error
      }
    }

    return response;
  }

  /// Centralized handler for MultipartRequests that handles token refresh on 401.
  Future<http.Response> performMultipartRequest(
    Future<http.MultipartRequest> Function(Map<String, String> headers) requestFactory,
  ) async {
    // 1. Get initial headers
    final headers = await getHeaders();
    
    // 2. Create and perform the initial request
    final request = await requestFactory(headers);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // 3. If 401 Unauthorized, attempt to refresh
    if (response.statusCode == 401) {
      final success = await AuthService().refreshToken();

      if (success) {
        // 4. If refresh succeeded, recreate the request with new headers and retry
        final newHeaders = await getHeaders();
        final newRequest = await requestFactory(newHeaders);
        streamedResponse = await newRequest.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // 5. If refresh fails, clear tokens
        await TokenManager.clearAll();
      }
    }

    return response;
  }
}
