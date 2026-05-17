// domino_models.dart
// Modelos únicos consolidados para o Dominó Químico.
// Substitui: jogo_models.dart e partida_model.dart

// ---------------------------------------------------------------------------
// Enum de dificuldade
// Níveis espelham exatamente o backend Python:
//   1 → Fórmula  ↔ Classe funcional
//   2 → Fórmula  ↔ Nome do composto
//   3 → Fórmula  ↔ Propriedade da função
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
// Espelha PecaDomino do Python (StatusPartidaResponse).
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

  /// Texto exibido no lado esquerdo da peça (sempre a fórmula do composto).
  final String visivelEsquerdo;

  /// Texto exibido no lado direito (classe, nome ou propriedade, conforme nível).
  final String visivelDireito;

  /// ID de classificação do lado esquerdo — usado para validar encaixe.
  final int validadorEsquerdo;

  /// ID de classificação do lado direito — usado para validar encaixe.
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
// Espelha StatusPartidaResponse do Python.
// ---------------------------------------------------------------------------
class EstadoPartida {
  const EstadoPartida({
    required this.idPartida,
    required this.mesa,
    required this.maoJogador,
    required this.status,
    required this.fimDeJogo,
    required this.quantidadeMonte,
  });

  final String idPartida;

  /// Peças atualmente visíveis na mesa, em ordem da esquerda para a direita.
  final List<PecaDomino> mesa;

  /// Peças na mão do jogador humano.
  final List<PecaDomino> maoJogador;

  /// Mensagem descritiva do último evento (jogada do bot, compra, fim etc.).
  final String status;

  /// true quando a partida terminou (vitória, derrota ou empate).
  final bool fimDeJogo;

  /// Quantidade de peças restantes no monte de compras.
  final int quantidadeMonte;

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
      );
}