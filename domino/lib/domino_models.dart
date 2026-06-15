
enum DificuldadeJogo {
  formulaClasse(1, 'Nível 1', 'Fórmula ↔ Classe'),
  formulaNome(2, 'Nível 2', 'Fórmula ↔ Nome'),
  formulaPropriedade(3, 'Nível 3', 'Fórmula ↔ Propriedade');

  const DificuldadeJogo(this.id, this.titulo, this.descricao);

  final int id;
  final String titulo;
  final String descricao;

  static DificuldadeJogo fromId(int id) => values.firstWhere(
        (d) => d.id == id,
        orElse: () => DificuldadeJogo.formulaClasse,
      );
}

class PecaDomino {
  const PecaDomino({
    required this.idPeca,
    required this.visivelEsquerdo,
    required this.visivelDireito,
    required this.validadorEsquerdo,
    required this.validadorDireito,
  });

  final int idPeca;
  final String visivelEsquerdo;
  final String visivelDireito;
  final int validadorEsquerdo;
  final int validadorDireito;

  factory PecaDomino.fromJson(Map<String, dynamic> json) => PecaDomino(
        idPeca: json['id_peca'] as int,
        visivelEsquerdo: json['visivel_esquerdo'] as String,
        visivelDireito: json['visivel_direito'] as String,
        validadorEsquerdo: json['validador_esquerdo'] as int,
        validadorDireito: json['validador_direito'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id_peca': idPeca,
        'visivel_esquerdo': visivelEsquerdo,
        'visivel_direito': visivelDireito,
        'validador_esquerdo': validadorEsquerdo,
        'validador_direito': validadorDireito,
      };
}

class EstadoPartida {
  const EstadoPartida({
    required this.idPartida,
    required this.mesa,
    required this.maoJogador,
    required this.status,
    required this.fimDeJogo,
    required this.quantidadeMonte,
    this.qtdAcertos = 0,
    this.jogadorTemJogadas = true,
    this.podePasar = false,
  });

  final String idPartida;
  final List<PecaDomino> mesa;
  final List<PecaDomino> maoJogador;
  final String status;
  final bool fimDeJogo;
  final int quantidadeMonte;
  final int qtdAcertos;
  final bool jogadorTemJogadas;
  final bool podePasar;

  factory EstadoPartida.fromJson(Map<String, dynamic> json) => EstadoPartida(
        idPartida: json['id_partida'] as String,
        mesa: (json['mesa'] as List<dynamic>)
            .map((e) => PecaDomino.fromJson(e as Map<String, dynamic>))
            .toList(),
        maoJogador: (json['mao_jogador'] as List<dynamic>)
            .map((e) => PecaDomino.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: json['status'] as String,
        fimDeJogo: json['fim_de_jogo'] as bool,
        quantidadeMonte: (json['quantidade_monte'] as int?) ?? 0,
        qtdAcertos: (json['qtd_acertos'] as int?) ?? 0,
        jogadorTemJogadas: (json['jogador_tem_jogadas'] as bool?) ?? true,
        podePasar: (json['pode_passar'] as bool?) ?? false,
      );
}