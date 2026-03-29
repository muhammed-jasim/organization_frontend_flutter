import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyOrgId = 'organization_id';
  static const _keyOrgName = 'organization_name';
  static const _keyOrgLogo = 'organization_logo';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> saveOrganizationDetails({
    required String id,
    required String name,
    String? logo,
  }) async {
    await _storage.write(key: _keyOrgId, value: id);
    await _storage.write(key: _keyOrgName, value: name);
    if (logo != null) {
      await _storage.write(key: _keyOrgLogo, value: logo);
    } else {
      await _storage.delete(key: _keyOrgLogo);
    }
  }

  static Future<void> saveOrganizationId(String orgId) async {
    await _storage.write(key: _keyOrgId, value: orgId);
  }

  static Future<String?> getOrganizationId() async {
    return await _storage.read(key: _keyOrgId);
  }

  static Future<String?> getOrganizationName() async {
    return await _storage.read(key: _keyOrgName);
  }

  static Future<String?> getOrganizationLogo() async {
    return await _storage.read(key: _keyOrgLogo);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyOrgId);
    await _storage.delete(key: _keyOrgName);
    await _storage.delete(key: _keyOrgLogo);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _keyAccessToken);
  }
}
