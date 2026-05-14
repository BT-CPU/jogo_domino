import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'relatorio_models.dart';

class RelatorioService {
  const RelatorioService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get _httpClient => _client ?? http.Client();

  Future<RelatorioAluno> obterRelatorioAluno(int idUsuario) async {
    final response = await _httpClient.get(
      Uri.parse('${ApiConfig.gameplayBaseUrl}/relatorios/aluno/$idUsuario'),
    );

    if (response.statusCode != 200) {
      throw Exception(_extrairErro(response.body));
    }

    return RelatorioAluno.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<RelatorioProfessor> obterRelatorioProfessor(int idProfessor) async {
    final response = await _httpClient.get(
      Uri.parse(
        '${ApiConfig.gameplayBaseUrl}/relatorios/professor/$idProfessor',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(_extrairErro(response.body));
    }

    return RelatorioProfessor.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _extrairErro(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail'] as String? ?? 'Falha ao carregar relatório.';
    } catch (_) {
      return 'Falha ao carregar relatório.';
    }
  }
}