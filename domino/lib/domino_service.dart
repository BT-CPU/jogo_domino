// domino_service.dart
// Service único consolidado para o Dominó Químico.

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'domino_models.dart';

// ---------------------------------------------------------------------------
// Configuração de URL
// ---------------------------------------------------------------------------
const _kBaseUrl = 'https://jogodomino-production.up.railway.app';

// ---------------------------------------------------------------------------
// DominoService
// ---------------------------------------------------------------------------
class DominoService {
  DominoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ─── Partida ──────────────────────────────────────────────────────────────

  /// Cria uma nova partida e retorna o estado inicial.
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

  /// Envia a jogada do jogador.
  ///
  /// Lança [JogadaInvalidaException] quando o backend retorna 422.
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

  /// Compra uma peça do monte.
  ///
  /// Lança [MonteVazioException] quando o backend retorna 422.
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

  // [CORREÇÃO BUG 1] Passa a vez do jogador quando ele não tem jogadas válidas
  // e o monte está vazio. Sem este método, o jogador ficava preso em loop
  // infinito de erros 422 ao tentar jogar peças que não encaixam.
  //
  // O backend valida que o jogador realmente não pode jogar antes de aceitar
  // a passagem de vez — então não é possível usar isso como atalho.
  //
  // Lança [PassarVezInvalidaException] quando o backend retorna 400
  // (jogador ainda tem jogadas ou monte não está vazio).
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
      throw PassarVezInvalidaException(
        body['detail'] as String? ?? 'Não é possível passar a vez agora.',
      );
    }

    throw _erroHttp('passar vez', response);
  }

  /// Persiste o resultado da partida no banco de dados.
  Future<void> finalizarPartida({
    required int idUsuario,
    required DificuldadeJogo dificuldade,
    required int tempoSegundos,
    required int qtdAcertos,
    required int qtdErros,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kBaseUrl/partidas/finalizar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'nivel_dificuldade': dificuldade.id,
        'tempo_segundos': tempoSegundos,
        'qtd_acertos': qtdAcertos,
        'qtd_erros': qtdErros,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _erroHttp('finalizar partida', response);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Exception _erroHttp(String operacao, http.Response response) {
    return Exception(
      'Erro ao $operacao (HTTP ${response.statusCode}): ${response.body}',
    );
  }
}

// ---------------------------------------------------------------------------
// Exceções tipadas
// ---------------------------------------------------------------------------

/// Lançada quando o backend rejeita a jogada por combinação química incorreta.
class JogadaInvalidaException implements Exception {
  const JogadaInvalidaException();

  @override
  String toString() => 'Combinação química incorreta! Tente outra peça ou extremidade.';
}

/// Lançada quando se tenta comprar do monte e ele já está vazio.
class MonteVazioException implements Exception {
  const MonteVazioException();

  @override
  String toString() => 'O monte está vazio!';
}

// [CORREÇÃO BUG 1] Lançada quando o backend rejeita a passagem de vez
// (jogador ainda tem jogadas disponíveis ou monte não está vazio).
class PassarVezInvalidaException implements Exception {
  const PassarVezInvalidaException(this.message);

  final String message;

  @override
  String toString() => message;
}