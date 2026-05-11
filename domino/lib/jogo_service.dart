import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'jogo_models.dart';

class JogoService {
  JogoService({http.Client? client, Random? random})
    : _client = client ?? http.Client(),
      _engine = _LocalGameEngine(random: random ?? Random());

  static const bool _usarApiRemotaNoGameplay = false;

  final http.Client _client;
  final _LocalGameEngine _engine;

  Future<EstadoPartida> iniciarPartida({
    required DificuldadeJogo dificuldade,
    int? idUsuario,
  }) async {
    if (_usarApiRemotaNoGameplay) {
      try {
        final response = await _client.post(
          Uri.parse('${ApiConfig.gameplayBaseUrl}/partidas/iniciar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_usuario': idUsuario,
            'nivel_dificuldade': dificuldade.id,
          }),
        );

        if (response.statusCode == 200) {
          return EstadoPartida.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {
        // Fall back to local engine for development and offline use.
      }
    }

    return _engine.iniciarPartida(
      dificuldade: dificuldade,
      idUsuario: idUsuario,
    );
  }

  Future<ResultadoJogada> jogarPeca({
    required EstadoPartida estado,
    required PecaJogo peca,
  }) async {
    if (_usarApiRemotaNoGameplay) {
      try {
        final response = await _client.post(
          Uri.parse('${ApiConfig.gameplayBaseUrl}/partidas/jogada'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'estado': estado.toJson(), 'peca': peca.toJson()}),
        );

        if (response.statusCode == 200) {
          return ResultadoJogada.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }
      } catch (_) {
        // Fall back to local engine for development and offline use.
      }
    }

    return _engine.jogarPeca(estado: estado, peca: peca);
  }

  Future<void> finalizarPartida({required EstadoPartida estado}) async {
    try {
      await _client.post(
        Uri.parse('${ApiConfig.gameplayBaseUrl}/partidas/finalizar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': estado.idUsuario,
          'nivel_dificuldade': estado.dificuldade.id,
          'tempo_segundos': estado.tempoSegundos,
          'qtd_acertos': estado.qtdAcertos,
          'qtd_erros': estado.qtdErros,
        }),
      );
    } catch (_) {
      // The local flow keeps working even if persistence is unavailable.
    }
  }
}

class _LocalGameEngine {
  _LocalGameEngine({required Random random}) : _random = random;

  final Random _random;
  int _seed = 0;

  EstadoPartida iniciarPartida({
    required DificuldadeJogo dificuldade,
    int? idUsuario,
  }) {
    final pool = _buildPool(dificuldade);
    final handSize = min(5, pool.length.clamp(3, 999));
    final shuffled = [...pool]..shuffle(_random);
    final maoJogador = shuffled.take(handSize).toList();
    final restantes = shuffled.skip(handSize).toList();

    final inicio = _escolherInicio(
      dificuldade: dificuldade,
      maoJogador: maoJogador,
      candidatas: restantes.isNotEmpty ? restantes : pool,
    );

    return EstadoPartida(
      idUsuario: idUsuario,
      dificuldade: dificuldade,
      turnoAtual: TurnoPartida.jogador,
      status: StatusPartida.emAndamento,
      qtdAcertos: 0,
      qtdErros: 0,
      tempoSegundos: 0,
      pontaAtiva: inicio.direita,
      maoJogador: maoJogador,
      tabuleiro: [PecaPosicionada.fromPeca(inicio, origem: OrigemPeca.inicial)],
    );
  }

  ResultadoJogada jogarPeca({
    required EstadoPartida estado,
    required PecaJogo peca,
  }) {
    if (estado.finalizada) {
      return ResultadoJogada(
        jogadaValida: false,
        estado: estado,
        mensagem: 'A partida ja foi encerrada.',
      );
    }

    if (!_contemPeca(estado.maoJogador, peca.id)) {
      return ResultadoJogada(
        jogadaValida: false,
        estado: estado.copyWith(qtdErros: estado.qtdErros + 1),
        mensagem: 'Essa peca nao esta mais na sua mao.',
      );
    }

    final posicionadaJogador = _posicionarPeca(
      dificuldade: estado.dificuldade,
      pontaAtiva: estado.pontaAtiva,
      peca: peca,
      origem: OrigemPeca.jogador,
    );

    if (posicionadaJogador == null) {
      return ResultadoJogada(
        jogadaValida: false,
        estado: estado.copyWith(qtdErros: estado.qtdErros + 1),
        mensagem: 'Conexao incorreta. Tente outra peca.',
      );
    }

    final novaMao = estado.maoJogador
        .where((item) => item.id != peca.id)
        .toList();
    final novoTabuleiro = [...estado.tabuleiro, posicionadaJogador];
    var proximoEstado = estado.copyWith(
      qtdAcertos: estado.qtdAcertos + 1,
      maoJogador: novaMao,
      tabuleiro: novoTabuleiro,
      pontaAtiva: posicionadaJogador.direita,
      turnoAtual: TurnoPartida.bot,
    );

    if (novaMao.isEmpty) {
      proximoEstado = proximoEstado.copyWith(
        status: StatusPartida.finalizada,
        turnoAtual: TurnoPartida.jogador,
      );
      return ResultadoJogada(
        jogadaValida: true,
        estado: proximoEstado,
        mensagem: 'Voce esvaziou a mao e concluiu a partida!',
      );
    }

    final respostaBot = _gerarJogadaBot(
      dificuldade: estado.dificuldade,
      pontaAtiva: proximoEstado.pontaAtiva,
      maoJogadorRestante: novaMao,
    );

    if (respostaBot == null) {
      proximoEstado = proximoEstado.copyWith(
        turnoAtual: TurnoPartida.jogador,
        status: StatusPartida.finalizada,
      );
      return ResultadoJogada(
        jogadaValida: true,
        estado: proximoEstado,
        mensagem:
            'Jogada correta. O bot nao encontrou resposta e a rodada foi encerrada.',
      );
    }

    final estadoComBot = proximoEstado.copyWith(
      turnoAtual: TurnoPartida.jogador,
      pontaAtiva: respostaBot.direita,
      tabuleiro: [...proximoEstado.tabuleiro, respostaBot],
    );

    return ResultadoJogada(
      jogadaValida: true,
      estado: estadoComBot,
      mensagem: 'Jogada correta. O bot respondeu com uma peca compativel.',
      pecaBot: respostaBot,
    );
  }

  bool _contemPeca(List<PecaJogo> pecas, String pecaId) {
    return pecas.any((peca) => peca.id == pecaId);
  }

  PecaJogo _escolherInicio({
    required DificuldadeJogo dificuldade,
    required List<PecaJogo> maoJogador,
    required List<PecaJogo> candidatas,
  }) {
    for (final candidata in [...candidatas]..shuffle(_random)) {
      if (maoJogador.any(
        (pecaJogador) => _podeConectar(
          dificuldade: dificuldade,
          pontaAtiva: candidata.direita,
          peca: pecaJogador,
        ),
      )) {
        return candidata;
      }
    }

    final fallback = candidatas.first;
    return fallback;
  }

  bool _podeConectar({
    required DificuldadeJogo dificuldade,
    required LadoPeca pontaAtiva,
    required PecaJogo peca,
  }) {
    return _saoCompativeis(
      dificuldade: dificuldade,
      primeiro: pontaAtiva,
      segundo: peca.esquerda,
    );
  }

  PecaPosicionada? _posicionarPeca({
    required DificuldadeJogo dificuldade,
    required LadoPeca pontaAtiva,
    required PecaJogo peca,
    required OrigemPeca origem,
  }) {
    if (!_saoCompativeis(
      dificuldade: dificuldade,
      primeiro: pontaAtiva,
      segundo: peca.esquerda,
    )) {
      return null;
    }

    return PecaPosicionada(
      id: '${peca.id}-${origem.name}',
      esquerda: peca.esquerda,
      direita: peca.direita,
      origem: origem,
    );
  }

  PecaPosicionada? _gerarJogadaBot({
    required DificuldadeJogo dificuldade,
    required LadoPeca pontaAtiva,
    required List<PecaJogo> maoJogadorRestante,
  }) {
    final candidatas = <_CandidataBot>[];
    final fallback = <PecaPosicionada>[];

    for (final peca in _buildPool(dificuldade)) {
      final posicionada = _posicionarPeca(
        dificuldade: dificuldade,
        pontaAtiva: pontaAtiva,
        peca: peca,
        origem: OrigemPeca.bot,
      );

      if (posicionada == null) {
        continue;
      }

      fallback.add(posicionada);

      final conexoesFuturas = maoJogadorRestante
          .where(
            (pecaJogador) => _podeConectar(
              dificuldade: dificuldade,
              pontaAtiva: posicionada.direita,
              peca: pecaJogador,
            ),
          )
          .length;

      if (conexoesFuturas > 0) {
        candidatas.add(
          _CandidataBot(peca: posicionada, conexoesFuturas: conexoesFuturas),
        );
      }
    }

    if (candidatas.isNotEmpty) {
      candidatas.sort(
        (primeira, segunda) =>
            segunda.conexoesFuturas.compareTo(primeira.conexoesFuturas),
      );
      final melhorPontuacao = candidatas.first.conexoesFuturas;
      final melhores = candidatas
          .where((candidata) => candidata.conexoesFuturas == melhorPontuacao)
          .toList();
      return melhores[_random.nextInt(melhores.length)].peca;
    }

    if (fallback.isNotEmpty) {
      return fallback[_random.nextInt(fallback.length)];
    }

    return null;
  }

  bool _saoCompativeis({
    required DificuldadeJogo dificuldade,
    required LadoPeca primeiro,
    required LadoPeca segundo,
  }) {
    switch (dificuldade) {
      case DificuldadeJogo.formulaFuncao:
        final formula = _resolverFormula(primeiro, segundo);
        final funcao = _resolverFuncao(primeiro, segundo);
        if (formula == null || funcao == null) {
          return false;
        }
        return _conteudos.any(
          (conteudo) =>
              conteudo.formula == formula && conteudo.funcao == funcao,
        );
      case DificuldadeJogo.propriedadesClassificacao:
        final propriedade = _resolverPropriedade(primeiro, segundo);
        final classificacao = _resolverClassificacao(primeiro, segundo);
        if (propriedade == null || classificacao == null) {
          return false;
        }
        return _conteudos.any(
          (conteudo) =>
              conteudo.propriedade == propriedade &&
              conteudo.classificacao == classificacao,
        );
      case DificuldadeJogo.classificacaoReacao:
        if (primeiro.tipo != TipoConteudoPeca.classificacao ||
            segundo.tipo != TipoConteudoPeca.classificacao) {
          return false;
        }
        return _compatibilidades
                .where(
                  (compatibilidade) => compatibilidade.origem == primeiro.valor,
                )
                .any(
                  (compatibilidade) => compatibilidade.destino == segundo.valor,
                ) ||
            _compatibilidades
                .where(
                  (compatibilidade) => compatibilidade.origem == segundo.valor,
                )
                .any(
                  (compatibilidade) =>
                      compatibilidade.destino == primeiro.valor,
                );
    }
  }

  String? _resolverFormula(LadoPeca primeiro, LadoPeca segundo) {
    if (primeiro.tipo == TipoConteudoPeca.formula) {
      return primeiro.valor;
    }
    if (segundo.tipo == TipoConteudoPeca.formula) {
      return segundo.valor;
    }
    return null;
  }

  String? _resolverFuncao(LadoPeca primeiro, LadoPeca segundo) {
    if (primeiro.tipo == TipoConteudoPeca.funcao) {
      return primeiro.valor;
    }
    if (segundo.tipo == TipoConteudoPeca.funcao) {
      return segundo.valor;
    }
    return null;
  }

  String? _resolverPropriedade(LadoPeca primeiro, LadoPeca segundo) {
    if (primeiro.tipo == TipoConteudoPeca.propriedade) {
      return primeiro.valor;
    }
    if (segundo.tipo == TipoConteudoPeca.propriedade) {
      return segundo.valor;
    }
    return null;
  }

  String? _resolverClassificacao(LadoPeca primeiro, LadoPeca segundo) {
    if (primeiro.tipo == TipoConteudoPeca.classificacao) {
      return primeiro.valor;
    }
    if (segundo.tipo == TipoConteudoPeca.classificacao) {
      return segundo.valor;
    }
    return null;
  }

  List<PecaJogo> _buildPool(DificuldadeJogo dificuldade) {
    switch (dificuldade) {
      case DificuldadeJogo.formulaFuncao:
        return _buildFormulaFuncaoPool();
      case DificuldadeJogo.propriedadesClassificacao:
        return _buildPropriedadeClassificacaoPool();
      case DificuldadeJogo.classificacaoReacao:
        return _buildClassificacaoReacaoPool();
    }
  }

  List<PecaJogo> _buildFormulaFuncaoPool() {
    final formulas = _conteudos.map((conteudo) => conteudo.formula).toList();
    final funcoes = _conteudos
        .map((conteudo) => conteudo.funcao)
        .toSet()
        .toList();

    final pecas = <PecaJogo>[];
    for (final formula in formulas) {
      for (final funcao in funcoes) {
        pecas.add(
          PecaJogo(
            id: 'd1-${_seed++}',
            esquerda: LadoPeca(tipo: TipoConteudoPeca.formula, valor: formula),
            direita: LadoPeca(tipo: TipoConteudoPeca.funcao, valor: funcao),
          ),
        );
      }
    }
    return pecas;
  }

  List<PecaJogo> _buildPropriedadeClassificacaoPool() {
    final propriedades = _conteudos
        .map((conteudo) => conteudo.propriedade)
        .toSet()
        .toList();
    final classificacoes = _conteudos
        .map((conteudo) => conteudo.classificacao)
        .toSet()
        .toList();

    final pecas = <PecaJogo>[];
    for (final propriedade in propriedades) {
      for (final classificacao in classificacoes) {
        pecas.add(
          PecaJogo(
            id: 'd2-${_seed++}',
            esquerda: LadoPeca(
              tipo: TipoConteudoPeca.propriedade,
              valor: propriedade,
            ),
            direita: LadoPeca(
              tipo: TipoConteudoPeca.classificacao,
              valor: classificacao,
            ),
          ),
        );
      }
    }
    return pecas;
  }

  List<PecaJogo> _buildClassificacaoReacaoPool() {
    final classificacoes = {
      for (final compatibilidade in _compatibilidades) compatibilidade.origem,
      for (final compatibilidade in _compatibilidades) compatibilidade.destino,
    }.toList();

    final pecas = <PecaJogo>[];
    for (final classificacaoOrigem in classificacoes) {
      for (final classificacaoDestino in classificacoes) {
        pecas.add(
          PecaJogo(
            id: 'd3-${_seed++}',
            esquerda: LadoPeca(
              tipo: TipoConteudoPeca.classificacao,
              valor: classificacaoOrigem,
            ),
            direita: LadoPeca(
              tipo: TipoConteudoPeca.classificacao,
              valor: classificacaoDestino,
            ),
          ),
        );
      }
    }
    return pecas;
  }
}

class _CandidataBot {
  const _CandidataBot({required this.peca, required this.conexoesFuturas});

  final PecaPosicionada peca;
  final int conexoesFuturas;
}

class _ConteudoQuimico {
  const _ConteudoQuimico({
    required this.formula,
    required this.funcao,
    required this.classificacao,
    required this.propriedade,
  });

  final String formula;
  final String funcao;
  final String classificacao;
  final String propriedade;
}

class _CompatibilidadeClassificacao {
  const _CompatibilidadeClassificacao({
    required this.origem,
    required this.destino,
  });

  final String origem;
  final String destino;
}

const List<_ConteudoQuimico> _conteudos = [
  _ConteudoQuimico(
    formula: 'HCl',
    funcao: 'Acido',
    classificacao: 'Acido',
    propriedade: 'Libera H+ em agua',
  ),
  _ConteudoQuimico(
    formula: 'H2SO4',
    funcao: 'Acido',
    classificacao: 'Acido',
    propriedade: 'Ioniza e forma H+',
  ),
  _ConteudoQuimico(
    formula: 'HNO3',
    funcao: 'Acido',
    classificacao: 'Acido',
    propriedade: 'Acido forte em agua',
  ),
  _ConteudoQuimico(
    formula: 'NaOH',
    funcao: 'Base',
    classificacao: 'Base',
    propriedade: 'Libera OH- em agua',
  ),
  _ConteudoQuimico(
    formula: 'KOH',
    funcao: 'Base',
    classificacao: 'Base',
    propriedade: 'Hidroxila em solucao',
  ),
  _ConteudoQuimico(
    formula: 'Ca(OH)2',
    funcao: 'Base',
    classificacao: 'Base',
    propriedade: 'Base ionica com OH-',
  ),
  _ConteudoQuimico(
    formula: 'NaCl',
    funcao: 'Sal',
    classificacao: 'Sal',
    propriedade: 'Resulta de neutralizacao',
  ),
  _ConteudoQuimico(
    formula: 'KNO3',
    funcao: 'Sal',
    classificacao: 'Sal',
    propriedade: 'Composto ionico derivado de acido e base',
  ),
  _ConteudoQuimico(
    formula: 'CaCO3',
    funcao: 'Sal',
    classificacao: 'Sal',
    propriedade: 'Sal de carbonato',
  ),
  _ConteudoQuimico(
    formula: 'CO2',
    funcao: 'Oxido',
    classificacao: 'Oxido acido',
    propriedade: 'Oxido de ametal',
  ),
  _ConteudoQuimico(
    formula: 'SO3',
    funcao: 'Oxido',
    classificacao: 'Oxido acido',
    propriedade: 'Oxido que forma acido em agua',
  ),
  _ConteudoQuimico(
    formula: 'CaO',
    funcao: 'Oxido',
    classificacao: 'Oxido basico',
    propriedade: 'Oxido de metal',
  ),
  _ConteudoQuimico(
    formula: 'Na2O',
    funcao: 'Oxido',
    classificacao: 'Oxido basico',
    propriedade: 'Oxido metalico basico',
  ),
];

const List<_CompatibilidadeClassificacao> _compatibilidades = [
  _CompatibilidadeClassificacao(origem: 'Acido', destino: 'Base'),
  _CompatibilidadeClassificacao(origem: 'Base', destino: 'Acido'),
  _CompatibilidadeClassificacao(origem: 'Acido', destino: 'Oxido basico'),
  _CompatibilidadeClassificacao(origem: 'Oxido basico', destino: 'Acido'),
  _CompatibilidadeClassificacao(origem: 'Base', destino: 'Oxido acido'),
  _CompatibilidadeClassificacao(origem: 'Oxido acido', destino: 'Base'),
];
