import '../../../../core/config/app_config.dart';

class TenantRepository {
  String _tenantId = AppConfig.initialTenantId;
  String _token = AppConfig.initialApiKey;
  final String _refreshToken = 'fw_refresh_token_secret_123456';

  String get tenantId => _tenantId;
  String get token => _token;
  String get refreshToken => _refreshToken;

  void setTenantId(String value) {
    _tenantId = value;
  }

  void updateToken(String newToken) {
    _token = newToken;
  }
}
