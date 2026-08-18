import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  final String baseUrl;
  final String? token;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get<dynamic>('up');
      return response.statusCode == 200;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'api/login',
        data: {'email': email, 'password': password},
      );
      return response.data!;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('api/logout');
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<Map<String, dynamic>>> listSaves() async {
    try {
      final response = await _dio.get<List<dynamic>>('api/saves');
      return (response.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> createSave({
    required String id,
    required String url,
    required String title,
    required DateTime createdAt,
    String? collectionId,
    bool aiEnabled = true,
  }) async {
    final cleanCollectionId = (collectionId == null || collectionId == 'global') ? null : collectionId;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'api/saves',
        data: {
          'id': id,
          'url': url,
          'title': title,
          'created_at': createdAt.toUtc().toIso8601String(),
          'collection_id': cleanCollectionId,
          'ai_enabled': aiEnabled,
        },
      );
      return response.data!;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> patchSave({
    required String id,
    required String? collectionId,
  }) async {
    final cleanCollectionId = (collectionId == null || collectionId == 'global') ? null : collectionId;
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        'api/saves/$id',
        data: {'collection_id': cleanCollectionId},
      );
      return response.data!;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> autoOrganizeSaves() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('api/saves/auto-organize');
      return response.data!;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<Map<String, dynamic>>> listCollections() async {
    try {
      final response = await _dio.get<List<dynamic>>('api/collections');
      return (response.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> createCollection({
    required String id,
    required String name,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'api/collections',
        data: {'id': id, 'name': name},
      );
      return response.data!;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> renameCollection({
    required String id,
    required String name,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        'api/collections/$id',
        data: {'name': name},
      );
      return response.data!;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await _dio.delete<void>('api/collections/$id');
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> deleteSave(String id) async {
    try {
      await _dio.delete<void>('api/saves/$id');
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  ApiException _map(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException("Couldn't reach the server.");
    }
    final status = error.response?.statusCode;
    if (status == 401) {
      return ApiException('Unauthorized', statusCode: 401);
    }
    if (status == 422) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return ApiException(data['message'].toString(), statusCode: 422);
      }
      return ApiException('Validation error', statusCode: 422);
    }
    return ApiException("Couldn't reach the server.", statusCode: status);
  }
}
