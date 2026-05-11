class PartidaRelatorio {
  const PartidaRelatorio({
    required this.idPartida,
    required this.nivelDificuldade,
    required this.tempoSegundos,
    required this.qtdAcertos,
    required this.qtdErros,
    required this.dataPartida,
  });

  final int idPartida;
  final int nivelDificuldade;
  final int tempoSegundos;
  final int qtdAcertos;
  final int qtdErros;
  final DateTime dataPartida;

  String get nivelLabel => 'Nivel $nivelDificuldade';

  String get tempoFormatado {
    final minutos = (tempoSegundos ~/ 60).toString().padLeft(2, '0');
    final segundos = (tempoSegundos % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  String get dataFormatada {
    final dia = dataPartida.day.toString().padLeft(2, '0');
    final mes = dataPartida.month.toString().padLeft(2, '0');
    final ano = dataPartida.year.toString();
    return '$dia/$mes/$ano';
  }

  factory PartidaRelatorio.fromJson(Map<String, dynamic> json) {
    return PartidaRelatorio(
      idPartida: json['id_partida'] as int,
      nivelDificuldade: json['nivel_dificuldade'] as int,
      tempoSegundos: json['tempo_segundos'] as int,
      qtdAcertos: json['qtd_acertos'] as int,
      qtdErros: json['qtd_erros'] as int,
      dataPartida: DateTime.parse(json['data_partida'] as String),
    );
  }
}

class RelatorioAluno {
  const RelatorioAluno({
    required this.idUsuario,
    required this.nome,
    required this.turma,
    required this.totalPartidas,
    required this.taxaAcertoMedia,
    required this.melhorTempoSegundos,
    required this.ultimaJogada,
    required this.historico,
  });

  final int idUsuario;
  final String nome;
  final String turma;
  final int totalPartidas;
  final double taxaAcertoMedia;
  final int? melhorTempoSegundos;
  final DateTime? ultimaJogada;
  final List<PartidaRelatorio> historico;

  String get melhorTempoFormatado {
    if (melhorTempoSegundos == null) {
      return '--:--';
    }

    final minutos = (melhorTempoSegundos! ~/ 60).toString().padLeft(2, '0');
    final segundos = (melhorTempoSegundos! % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  String get ultimaJogadaLabel {
    if (ultimaJogada == null) {
      return 'Nunca jogou';
    }

    final agora = DateTime.now();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);
    final inicioUltima = DateTime(
      ultimaJogada!.year,
      ultimaJogada!.month,
      ultimaJogada!.day,
    );
    final diffDias = inicioHoje.difference(inicioUltima).inDays;

    if (diffDias == 0) {
      return 'Hoje';
    }
    if (diffDias == 1) {
      return 'Ontem';
    }
    if (diffDias > 1 && diffDias <= 6) {
      return 'Ha $diffDias dias';
    }

    final dia = ultimaJogada!.day.toString().padLeft(2, '0');
    final mes = ultimaJogada!.month.toString().padLeft(2, '0');
    final ano = ultimaJogada!.year.toString();
    return '$dia/$mes/$ano';
  }

  factory RelatorioAluno.fromJson(Map<String, dynamic> json) {
    final historicoJson = json['historico'] as List<dynamic>? ?? const [];
    return RelatorioAluno(
      idUsuario: json['id_usuario'] as int,
      nome: json['nome'] as String,
      turma: json['turma'] as String? ?? 'Sem turma',
      totalPartidas: json['total_partidas'] as int? ?? 0,
      taxaAcertoMedia: (json['taxa_acerto_media'] as num?)?.toDouble() ?? 0,
      melhorTempoSegundos: json['melhor_tempo_segundos'] as int?,
      ultimaJogada: json['ultima_jogada'] == null
          ? null
          : DateTime.parse(json['ultima_jogada'] as String),
      historico: historicoJson
          .map(
            (item) => PartidaRelatorio.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class RelatorioProfessor {
  const RelatorioProfessor({
    required this.idProfessor,
    required this.nomeProfessor,
    required this.mediaAcertoTurma,
    required this.totalPartidasTurma,
    required this.alunos,
  });

  final int idProfessor;
  final String nomeProfessor;
  final double mediaAcertoTurma;
  final int totalPartidasTurma;
  final List<RelatorioAluno> alunos;

  factory RelatorioProfessor.fromJson(Map<String, dynamic> json) {
    final alunosJson = json['alunos'] as List<dynamic>? ?? const [];
    return RelatorioProfessor(
      idProfessor: json['id_professor'] as int,
      nomeProfessor: json['nome_professor'] as String,
      mediaAcertoTurma: (json['media_acerto_turma'] as num?)?.toDouble() ?? 0,
      totalPartidasTurma: json['total_partidas_turma'] as int? ?? 0,
      alunos: alunosJson
          .map((item) => RelatorioAluno.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
