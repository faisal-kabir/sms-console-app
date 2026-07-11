class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://api.formwork.internal',
  );

  static const String initialApiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'fw_live_8c21e0b47ad94f13ba77e0c9d51a3b62',
  );

  static const String initialTenantId = String.fromEnvironment(
    'TENANT_ID',
    defaultValue: '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
  );
}
