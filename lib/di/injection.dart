import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import '../core/network/api_client.dart';
import '../features/sms/data/repositories/sms_repository.dart';
import '../features/sms/data/repositories/tenant_repository.dart';
import '../features/sms/presentation/bloc/sms_console_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Core Services
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // 2. Tenant Context
  getIt.registerLazySingleton<TenantRepository>(() => TenantRepository());

  // 3. API Network Client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tenantRepository: getIt<TenantRepository>(),
      connectivity: getIt<Connectivity>(),
    ),
  );

  // 4. Repositories
  getIt.registerLazySingleton<SmsRepository>(
    () => SmsRepository(apiClient: getIt<ApiClient>()),
  );

  // 5. State Management (BLoC)
  getIt.registerFactory<SmsConsoleBloc>(
    () => SmsConsoleBloc(
      smsRepository: getIt<SmsRepository>(),
      tenantRepository: getIt<TenantRepository>(),
    ),
  );
}
