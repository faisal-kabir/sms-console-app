import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sms_console_app/core/network/mock_api_interceptor.dart';
import '../config/app_config.dart';
import '../../features/sms/data/repositories/tenant_repository.dart';
import 'tenant_interceptor.dart';
import 'auth_refresh_interceptor.dart';

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

    // 1. Add custom logger interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(ApiLogInterceptor());
    }

    // 2. Add Tenant Injector Interceptor
    dio.interceptors.add(TenantInterceptor(tenantRepository));
    dio.interceptors.add(MockApiInterceptor());

    // 3. Add Auth Token Refresh Interceptor
    dio.interceptors.add(AuthRefreshInterceptor(tenantRepository, dio));
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

class ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('--> ${options.method} ${options.uri}');
    debugPrint('Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('Response: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isConnectionError = err.type == DioExceptionType.connectionError ||
        err.error?.toString().contains('SocketException') == true ||
        err.message?.contains('Failed host lookup') == true;

    if (isConnectionError) {
      debugPrint(
        'xxx Connection Offline (Failed host lookup for ${err.requestOptions.uri.host}). Using offline fallback.',
      );
    } else {
      debugPrint('xxx Error: ${err.message}');
      if (err.response != null) {
        debugPrint('Response: ${err.response!.data}');
      }
    }
    super.onError(err, handler);
  }
}
