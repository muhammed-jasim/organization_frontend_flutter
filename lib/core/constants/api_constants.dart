class ApiConstants {
  // Main Server (Port 8000)
  static const String mainServerUrl = 'http://127.0.0.1:8000';
  static const String mainApiUrl = '$mainServerUrl/api/v1';

  // Auth Server (Port 8001)
  static const String authServerUrl = 'http://127.0.0.1:8001';
  static const String authApiUrl = '$authServerUrl/api/v1';

  // Specific Auth Endpoints
  static const String userEndpoint = '$authApiUrl/accounts/user';
}
