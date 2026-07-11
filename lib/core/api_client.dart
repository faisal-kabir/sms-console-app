import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';
import '../features/sms/sms_repository.dart';

class ApiClient {
  final Dio dio;
  final TenantRepository tenantRepository;
  final Connectivity connectivity;

  bool _isRefreshing = false;

  ApiClient({required this.tenantRepository, required this.connectivity})
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      ) {
    dio.interceptors.clear();
    if (kDebugMode) {
      dio.interceptors.add(ApiLogInterceptor());
    }
  }

  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    // 1. Check internet connection
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    final reqOptions = options ?? Options();
    reqOptions.headers ??= {};

    // 2. Attach Tenant ID and Bearer authorization credentials
    reqOptions.headers!['X-Tenant-Id'] = tenantRepository.tenantId;
    reqOptions.headers!['Authorization'] = 'Bearer ${tenantRepository.token}';

    try {
      return await dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: reqOptions,
      );
    } on DioException catch (err) {
      final isAuthError = err.response?.statusCode == 401;

      // 3. Auto-refresh auth token on 401 Unauthorized errors
      if (isAuthError && !_isRefreshing && path != '/api/v1/auth/refresh') {
        _isRefreshing = true;
        try {
          final refreshResponse = await dio.post<Map<String, dynamic>>(
            '/api/v1/auth/refresh',
            options: Options(
              headers: {
                'X-Tenant-Id': tenantRepository.tenantId,
                'Authorization': 'Bearer ${tenantRepository.refreshToken}',
              },
            ),
          );

          final newAccessToken =
              refreshResponse.data?['accessToken'] as String?;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            tenantRepository.updateToken(newAccessToken);

            // Retry request with the new access token
            reqOptions.headers!['Authorization'] = 'Bearer $newAccessToken';
            _isRefreshing = false;
            return await dio.request<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: reqOptions,
            );
          }
        } catch (_) {
          _isRefreshing = false;
          rethrow;
        } finally {
          _isRefreshing = false;
        }
      }
      rethrow;
    }
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
    final isConnectionError =
        err.type == DioExceptionType.connectionError ||
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
