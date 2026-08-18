import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:later/data/services/api_client.dart';

class AuthRepository {
  AuthRepository({
    required this.storage,
    required this.baseUrl,
  });

  final FlutterSecureStorage storage;
  final String baseUrl;
  static const tokenKey = 'later.token';

  Future<String?> token() => storage.read(key: tokenKey);

  Future<void> login(String email, String password) async {
    final client = ApiClient(baseUrl: baseUrl);
    final data = await client.login(email, password);
    final token = data['token'] as String;
    await storage.write(key: tokenKey, value: token);
  }

  Future<void> logout() async {
    final current = await token();
    if (current != null) {
      try {
        await ApiClient(baseUrl: baseUrl, token: current).logout();
      } on ApiException {
        // still clear local session
      }
    }
    await storage.delete(key: tokenKey);
  }
}
