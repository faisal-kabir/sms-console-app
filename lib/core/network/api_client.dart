import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../../features/sms/data/repositories/tenant_repository.dart';
import 'tenant_interceptor.dart';
import 'auth_refresh_interceptor.dart';
import 'mock_api_interceptor.dart';

class ApiClient {
  final Dio dio;
  final TenantRepository tenantRepository;
  final Connectivity connectivity;

  ApiClient({required this.tenantRepository, required this.connectivity})
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      ) {
    dio.interceptors.clear();

    // 1. Add logger interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    // 2. Add Tenant Injector Interceptor
    dio.interceptors.add(TenantInterceptor(tenantRepository));

    // 3. Add Auth Token Refresh Interceptor
    dio.interceptors.add(AuthRefreshInterceptor(tenantRepository, dio));

    // 4. Add Mock API Interceptor for offline stubbing
    dio.interceptors.add(MockApiInterceptor());
  }

  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    // Check connectivity first
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    return dio.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
