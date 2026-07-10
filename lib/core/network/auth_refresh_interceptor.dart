import 'package:dio/dio.dart';
import '../../features/sms/data/repositories/tenant_repository.dart';
import '../config/app_config.dart';

class AuthRefreshInterceptor extends Interceptor {
  final TenantRepository tenantRepository;
  final Dio dio;

  AuthRefreshInterceptor(this.tenantRepository, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;
      // Prevent infinite loop if the refresh request itself fails
      if (requestOptions.path.contains('/api/v1/auth/refresh')) {
        return super.onError(err, handler);
      }

      try {
        // Attempt token refresh
        final refreshResponse = await dio.post(
          '${AppConfig.apiBaseUrl}/api/v1/auth/refresh',
          data: {'refreshToken': tenantRepository.refreshToken},
        );

        if (refreshResponse.statusCode == 200) {
          final data = refreshResponse.data as Map<String, dynamic>;
          final newToken = data['accessToken'] as String;
          tenantRepository.updateToken(newToken);

          // Retry the original request with the new token
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          
          // Fetch expects a clean requestOptions
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, propagate the original error
      }
    }
    super.onError(err, handler);
  }
}
