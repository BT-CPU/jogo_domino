class ApiConfig {
  // A sua API real hospedada no Railway
  static const String _producao =
      'https://jogodomino-production.up.railway.app';

  static String get authBaseUrl => _producao;

  // Removemos a "armadilha" do localhost. Agora usa sempre o Railway!
  static String get gameplayBaseUrl => _producao;
}
