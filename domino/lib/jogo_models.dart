import 'dart:convert';

enum DificuldadeJogo {
  formulaFuncao(1, 'Nivel 1', 'Formula ↔ Funcao'),
  propriedadesClassificacao(2, 'Nivel 2', 'Propriedades ↔ Classificacao'),
  classificacaoReacao(3, 'Nivel 3', 'Classificacao ↔ Reacao');

  const DificuldadeJogo(this.id, this.titulo, this.descricao);

  final int id;
  final String titulo;
  final String descricao;

  static DificuldadeJogo fromId(int id) {
    return values.firstWhere(
      (dificuldade) => dificuldade.id == id,
      orElse: () => DificuldadeJogo.formulaFuncao,
    );
  }
}

enum TipoConteudoPeca { formula, funcao, propriedade, classificacao }

enum OrigemPeca { inicial, jogador, bot }

enum TurnoPartida { jogador, bot }

enum StatusPartida { emAndamento, finalizada }

class LadoPeca {
  const LadoPeca({required this.tipo, required this.valor});

  final TipoConteudoPeca tipo;
  final String valor;

  Map<String, dynamic> toJson() => {'tipo': tipo.name, 'valor': valor};

  factory LadoPeca.fromJson(Map<String, dynamic> json) {
    return LadoPeca(
      tipo: TipoConteudoPeca.values.byName(json['tipo'] as String),
      valor: json['valor'] as String,
    );
  }
}

class PecaJogo {
  const PecaJogo({
    required this.id,
    required this.esquerda,
    required this.direita,
  });

  final String id;
  final LadoPeca esquerda;
  final LadoPeca direita;

  PecaJogo invertida() {
    return PecaJogo(id: id, esquerda: direita, direita: esquerda);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'esquerda': esquerda.toJson(),
    'direita': direita.toJson(),
  };

  factory PecaJogo.fromJson(Map<String, dynamic> json) {
    return PecaJogo(
      id: json['id'] as String,
      esquerda: LadoPeca.fromJson(json['esquerda'] as Map<String, dynamic>),
      direita: LadoPeca.fromJson(json['direita'] as Map<String, dynamic>),
    );
  }
}

class PecaPosicionada {
  const PecaPosicionada({
    required this.id,
    required this.esquerda,
    required this.direita,
    required this.origem,
  });

  final String id;
  final LadoPeca esquerda;
  final LadoPeca direita;
  final OrigemPeca origem;

  factory PecaPosicionada.fromPeca(
    PecaJogo peca, {
    required OrigemPeca origem,
  }) {
    return PecaPosicionada(
      id: peca.id,
      esquerda: peca.esquerda,
      direita: peca.direita,
      origem: origem,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'esquerda': esquerda.toJson(),
    'direita': direita.toJson(),
    'origem': origem.name,
  };

  factory PecaPosicionada.fromJson(Map<String, dynamic> json) {
    return PecaPosicionada(
      id: json['id'] as String,
      esquerda: LadoPeca.fromJson(json['esquerda'] as Map<String, dynamic>),
      direita: LadoPeca.fromJson(json['direita'] as Map<String, dynamic>),
      origem: OrigemPeca.values.byName(json['origem'] as String),
    );
  }
}

class EstadoPartida {
  const EstadoPartida({
    required this.idUsuario,
    required this.dificuldade,
    required this.turnoAtual,
    required this.status,
    required this.qtdAcertos,
    required this.qtdErros,
    required this.tempoSegundos,
    required this.pontaAtiva,
    required this.maoJogador,
    required this.tabuleiro,
  });

  final int? idUsuario;
  final DificuldadeJogo dificuldade;
  final TurnoPartida turnoAtual;
  final StatusPartida status;
  final int qtdAcertos;
  final int qtdErros;
  final int tempoSegundos;
  final LadoPeca pontaAtiva;
  final List<PecaJogo> maoJogador;
  final List<PecaPosicionada> tabuleiro;

  bool get finalizada => status == StatusPartida.finalizada;

  EstadoPartida copyWith({
    int? idUsuario,
    DificuldadeJogo? dificuldade,
    TurnoPartida? turnoAtual,
    StatusPartida? status,
    int? qtdAcertos,
    int? qtdErros,
    int? tempoSegundos,
    LadoPeca? pontaAtiva,
    List<PecaJogo>? maoJogador,
    List<PecaPosicionada>? tabuleiro,
  }) {
    return EstadoPartida(
      idUsuario: idUsuario ?? this.idUsuario,
      dificuldade: dificuldade ?? this.dificuldade,
      turnoAtual: turnoAtual ?? this.turnoAtual,
      status: status ?? this.status,
      qtdAcertos: qtdAcertos ?? this.qtdAcertos,
      qtdErros: qtdErros ?? this.qtdErros,
      tempoSegundos: tempoSegundos ?? this.tempoSegundos,
      pontaAtiva: pontaAtiva ?? this.pontaAtiva,
      maoJogador: maoJogador ?? this.maoJogador,
      tabuleiro: tabuleiro ?? this.tabuleiro,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'dificuldade': dificuldade.id,
    'turno_atual': turnoAtual.name,
    'status': status.name,
    'qtd_acertos': qtdAcertos,
    'qtd_erros': qtdErros,
    'tempo_segundos': tempoSegundos,
    'ponta_ativa': pontaAtiva.toJson(),
    'mao_jogador': maoJogador.map((peca) => peca.toJson()).toList(),
    'tabuleiro': tabuleiro.map((peca) => peca.toJson()).toList(),
  };

  factory EstadoPartida.fromJson(Map<String, dynamic> json) {
    return EstadoPartida(
      idUsuario: json['id_usuario'] as int?,
      dificuldade: DificuldadeJogo.fromId(json['dificuldade'] as int),
      turnoAtual: TurnoPartida.values.byName(json['turno_atual'] as String),
      status: StatusPartida.values.byName(json['status'] as String),
      qtdAcertos: json['qtd_acertos'] as int,
      qtdErros: json['qtd_erros'] as int,
      tempoSegundos: json['tempo_segundos'] as int,
      pontaAtiva: LadoPeca.fromJson(
        json['ponta_ativa'] as Map<String, dynamic>,
      ),
      maoJogador: (json['mao_jogador'] as List<dynamic>)
          .map((peca) => PecaJogo.fromJson(peca as Map<String, dynamic>))
          .toList(),
      tabuleiro: (json['tabuleiro'] as List<dynamic>)
          .map((peca) => PecaPosicionada.fromJson(peca as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ResultadoJogada {
  const ResultadoJogada({
    required this.jogadaValida,
    required this.estado,
    required this.mensagem,
    this.pecaBot,
  });

  final bool jogadaValida;
  final EstadoPartida estado;
  final String mensagem;
  final PecaPosicionada? pecaBot;

  Map<String, dynamic> toJson() => {
    'jogada_valida': jogadaValida,
    'estado': estado.toJson(),
    'mensagem': mensagem,
    'peca_bot': pecaBot?.toJson(),
  };

  factory ResultadoJogada.fromJson(Map<String, dynamic> json) {
    return ResultadoJogada(
      jogadaValida: json['jogada_valida'] as bool,
      estado: EstadoPartida.fromJson(json['estado'] as Map<String, dynamic>),
      mensagem: json['mensagem'] as String,
      pecaBot: json['peca_bot'] == null
          ? null
          : PecaPosicionada.fromJson(json['peca_bot'] as Map<String, dynamic>),
    );
  }
}

String prettyJson(Map<String, dynamic> json) {
  return const JsonEncoder.withIndent('  ').convert(json);
}
