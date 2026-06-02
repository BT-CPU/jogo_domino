class ApiConfig {
  static const String _producao =
      'https://jogodomino-production.up.railway.app';

  static String get authBaseUrl => _producao;
  static String get gameplayBaseUrl => _producao;
}
