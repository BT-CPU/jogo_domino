import 'dart:convert';
import 'package:http/http.dart' as http;
import 'partida_model.dart';

class PartidaService {
  final String baseUrl = 'https://jogodomino-production.up.railway.app';

  // Cria a partida e recebe o estado inicial
  Future<StatusPartida> criarPartida(int idUsuario, int nivel) async {
    final response = await http.post(
      Uri.parse('$baseUrl/partidas/criar'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_usuario": idUsuario, "nivel_dificuldade": nivel}),
    );

    if (response.statusCode == 201) {
      return StatusPartida.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Erro ao iniciar partida");
    }
  }

  // Envia uma jogada e recebe o novo estado (após a vez do bot)
  Future<StatusPartida> jogarPeca(String idPartida, int idPeca, String ponta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/partidas/jogar'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_partida": idPartida,
        "id_peca": idPeca,
        "ponta": ponta,
      }),
    );

    if (response.statusCode == 200) {
      return StatusPartida.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 422) {
      // Aqui é onde o erro de química cai
      throw Exception("Combinação Química Incorreta!");
    } else {
      throw Exception("Erro na jogada");
    }
  }
}