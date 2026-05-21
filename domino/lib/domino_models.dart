// domino_models.dart

// ---------------------------------------------------------------------------
// Enum de dificuldade
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Peça do dominó
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Estado da partida
// ---------------------------------------------------------------------------
class EstadoPartida {
  const EstadoPartida({
    required this.idPartida,
    required this.mesa,
    required this.maoJogador,
    required this.status,
    required this.fimDeJogo,
    required this.quantidadeMonte,
    // Bug C corrigido: acertos contados server-side.
    this.qtdAcertos = 0,
    // Bug B corrigido: sinaliza se há jogadas válidas disponíveis.
    this.jogadorTemJogadas = true,
  });

  final String idPartida;

  /// Peças na mesa, da esquerda para a direita.
  final List<PecaDomino> mesa;

  /// Peças na mão do jogador.
  final List<PecaDomino> maoJogador;

  /// Mensagem descritiva do último evento.
  final String status;

  /// true quando a partida terminou.
  final bool fimDeJogo;

  /// Quantidade de peças no monte de compras.
  final int quantidadeMonte;

  /// Acertos contabilizados pelo servidor (imune a manipulação client-side).
  final int qtdAcertos;

  /// Bug B/E: false quando o jogador não tem peças jogáveis.
  /// A UI usa este campo para exibir o botão "Passar".
  final bool jogadorTemJogadas;

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
      );
}