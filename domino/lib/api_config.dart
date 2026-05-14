import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _producao =
      'jogodomino-production.up.railway.app';

  static String get authBaseUrl => _producao;

  static String get gameplayBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == '127.0.0.1' || host == 'localhost') {
        return 'http://127.0.0.1:8000';
      }
    }

    return _producao;
  }
}
