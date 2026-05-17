// domino_service.dart
// Service único consolidado para o Dominó Químico.
// Substitui: jogo_service.dart e partida_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'domino_models.dart';

// ---------------------------------------------------------------------------
// Configuração de URL
// Troque a constante abaixo se o endpoint mudar (ex.: ambiente de dev).
// ---------------------------------------------------------------------------
const _kBaseUrl = 'https://jogodomino-production.up.railway.app';

// ---------------------------------------------------------------------------
// DominoService
// Todas as chamadas HTTP relacionadas ao jogo em um único lugar.
// ---------------------------------------------------------------------------
class DominoService {
  DominoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ─── Partida ──────────────────────────────────────────────────────────────

  /// Cria uma nova partida e retorna o estado inicial (mão do jogador + mesa).
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

    // O backend retorna 201 Created na criação.
    if (response.statusCode == 200 || response.statusCode == 201) {
      return EstadoPartida.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }

    throw _erroHttp('criar partida', response);
  }

  /// Envia a jogada do jogador. O backend processa o turno do bot
  /// na mesma chamada e devolve o estado atualizado.
  ///
  /// [ponta] deve ser `"esquerda"` ou `"direita"`.
  ///
  /// Lança [JogadaInvalidaException] quando o backend retorna 422
  /// (combinação química incorreta) para que a UI possa tratar
  /// separadamente dos demais erros de rede/servidor.
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

  /// Compra uma peça do monte e retorna o estado atualizado.
  /// Lança [MonteVazioException] quando o backend retorna 422
  /// (monte esgotado) — a UI pode checar [EstadoPartida.quantidadeMonte]
  /// antes de chamar para evitar a requisição desnecessária.
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

  /// Persiste o resultado da partida no banco de dados.
  /// Falha silenciosa é aceitável (não bloqueia o fluxo de fim de jogo),
  /// mas a exceção é propagada para que a UI decida como lidar.
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
// Permitem que a UI distinga erros de domínio de erros de rede.
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