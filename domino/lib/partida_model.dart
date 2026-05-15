class PecaDomino {
  final int idPeca;
  final String visivelEsquerdo;
  final String visivelDireito;
  final int validadorEsquerdo;
  final int validadorDireito;

  PecaDomino({
    required this.idPeca,
    required this.visivelEsquerdo,
    required this.visivelDireito,
    required this.validadorEsquerdo,
    required this.validadorDireito,
  });

  factory PecaDomino.fromJson(Map<String, dynamic> json) {
    return PecaDomino(
      idPeca: json['id_peca'] ?? 0,
      visivelEsquerdo: json['visivel_esquerdo'] ?? '',
      visivelDireito: json['visivel_direito'] ?? '',
      validadorEsquerdo: json['validador_esquerdo'] ?? 0,
      validadorDireito: json['validador_direito'] ?? 0,
    );
  }
}

class StatusPartida {
  final String idPartida;
  final List<PecaDomino> mesa;
  final List<PecaDomino> maoJogador;
  final String status;
  final bool fimDeJogo;

  StatusPartida({
    required this.idPartida,
    required this.mesa,
    required this.maoJogador,
    required this.status,
    required this.fimDeJogo,
  });

  factory StatusPartida.fromJson(Map<String, dynamic> json) {
    return StatusPartida(
      idPartida: json['id_partida'] ?? '',
      mesa: (json['mesa'] as List? ?? [])
          .map((i) => PecaDomino.fromJson(i))
          .toList(),
      maoJogador: (json['mao_jogador'] as List? ?? [])
          .map((i) => PecaDomino.fromJson(i))
          .toList(),
      status: json['status'] ?? '',
      fimDeJogo: json['fim_de_jogo'] ?? false,
    );
  }
}