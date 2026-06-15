
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'domino_models.dart';

const _kBaseUrl = 'https://jogodomino-production.up.railway.app';

class DominoService {
  DominoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<EstadoPartida> criarPartida({
    required DificuldadeJogo dificuldade,
    required int idUsuario,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/partidas/criar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'nivel_dificuldade': dificuldade.id,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return EstadoPartida.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }

    throw _erroHttp('criar partida', response);
  }

  Future<EstadoPartida> jogarPeca({
    required String idPartida,
    required int idPeca,
    required String ponta,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/partidas/jogar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_partida': idPartida,
        'id_peca': idPeca,
        'ponta': ponta,
      }),
    );

    if (response.statusCode == 200) {
      return EstadoPartida.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 422) {
      throw const JogadaInvalidaException();
    }

    throw _erroHttp('jogar peça', response);
  }


  Future<EstadoPartida> comprarPeca({required String idPartida}) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/partidas/comprar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_partida': idPartida}),
    );

    if (response.statusCode == 200) {
      return EstadoPartida.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 422) {
      throw const MonteVazioException();
    }

    throw _erroHttp('comprar peça', response);
  }

  Future<EstadoPartida> passarVez({required String idPartida}) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/partidas/passar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_partida': idPartida}),
    );

    if (response.statusCode == 200) {
      return EstadoPartida.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 400) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw PassarVezBloqueadaException(
        body['detail'] as String? ?? 'Não é possível passar a vez agora.',
      );
    }

    throw _erroHttp('passar vez', response);
  }

  Future<void> finalizarPartida({
    required int idUsuario,
    required DificuldadeJogo dificuldade,
    required int tempoSegundos,
    required String idPartida,
    required int qtdErros,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/partidas/finalizar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'nivel_dificuldade': dificuldade.id,
        'tempo_segundos': tempoSegundos,
        'id_partida': idPartida,
        'qtd_erros': qtdErros,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _erroHttp('finalizar partida', response);
    }
  }


  Exception _erroHttp(String operacao, http.Response response) {
    return Exception(
      'Erro ao $operacao (HTTP ${response.statusCode}): ${response.body}',
    );
  }
}

class JogadaInvalidaException implements Exception {
  const JogadaInvalidaException();

  @override
  String toString() =>
      'Combinação química incorreta! Tente outra peça ou extremidade.';
}

class MonteVazioException implements Exception {
  const MonteVazioException();

  @override
  String toString() => 'O monte está vazio!';
}

class PassarVezBloqueadaException implements Exception {
  const PassarVezBloqueadaException(this.motivo);

  final String motivo;

  @override
  String toString() => motivo;
}