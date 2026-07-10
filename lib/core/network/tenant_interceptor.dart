import 'package:dio/dio.dart';
import '../../features/sms/data/repositories/tenant_repository.dart';

class TenantInterceptor extends Interceptor {
  final TenantRepository tenantRepository;

  TenantInterceptor(this.tenantRepository);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer ${tenantRepository.token}';
    options.headers['X-Tenant-Id'] = tenantRepository.tenantId;
    super.onRequest(options, handler);
  }
}
