import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Atualizado para os seus novos modelos e service do backend em Python
import 'partida_model.dart';
import 'partida_service.dart';
import 'jogo_models.dart'
    hide StatusPartida; // Mantido para carregar a DificuldadeJogo do seu Enum

import 'dart:ui';

class TelaJogo extends StatefulWidget {
  const TelaJogo({
    super.key,
    this.dificuldade = DificuldadeJogo.formulaFuncao,
    this.idUsuario = 1,
  });

  final DificuldadeJogo dificuldade;
  final int? idUsuario;

  @override
  State<TelaJogo> createState() => _TelaJogoState();
}

class _TelaJogoState extends State<TelaJogo> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaEscuro = Color(0xFF333333);
  static const _cinzaFundo = Color(0xFFF7F7F7);

  // Cores Temáticas para o Layout Profissional
  static const _corPecaDomino = Color(0xFFFFFDF9); // Tom marfim/osso realista
  static const _bordaPecaDomino = Color(
    0xFFE6DCC8,
  ); // Borda suave para dar profundidade

  final PartidaService _partidaService = PartidaService();
  final ScrollController _tabuleiroScrollController = ScrollController();

  StatusPartida? _estado;
  Timer? _timer;

  // Variáveis locais para manter os seus contadores visuais funcionando
  int _tempoSegundos = 0;
  int _qtdAcertos = 0;
  int _qtdErros = 0;

  bool _carregando = true;
  bool _processandoJogada = false;
  bool _partidaPersistida = false;
  String? _erro;
  String _mensagemStatus = 'Preparando partida...';

  @override
  void initState() {
    super.initState();
    _iniciarPartida();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabuleiroScrollController.dispose();
    super.dispose();
  }

  Future<void> _iniciarPartida() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _mensagemStatus = 'Preparando partida...';
      _tempoSegundos = 0;
      _qtdAcertos = 0;
      _qtdErros = 0;
    });

    try {
      final estado = await _partidaService.criarPartida(
        widget.idUsuario ?? 1,
        widget.dificuldade.index +
            1, // Mapeando seu Enum para o nível do backend
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _estado = estado;
        _carregando = false;
        _mensagemStatus = estado.status;
      });

      // Delay de proteção para dar tempo do Flutter criar o layout
      Future.delayed(const Duration(milliseconds: 100), () {
        _rolarTabuleiroParaDireita();
      });
      _rolarTabuleiroParaDireita();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _estado == null || _estado!.fimDeJogo) {
          return;
        }
        setState(() {
          _tempoSegundos++;
        });
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erro = 'Nao foi possivel iniciar a partida.';
        _mensagemStatus = e.toString();
        _carregando = false;
      });
    }
  }

  // --- FUNÇÃO ORIGINAL ADAPTADA ---
  Future<void> _confirmarJogada(PecaDomino peca, String ponta) async {
    final estado = _estado;
    if (estado == null || _processandoJogada || estado.fimDeJogo) return;

    setState(() {
      _processandoJogada = true;
      _mensagemStatus = 'Validando jogada na ponta $ponta...';
    });

    try {
      final resultado = await _partidaService.jogarPeca(
        estado.idPartida,
        peca.idPeca,
        ponta,
      );

      if (!mounted) return;

      setState(() {
        _estado = resultado;
        _mensagemStatus = resultado.status;
        _qtdAcertos++;
        _processandoJogada = false;
      });

      // USANDO O MÉTODO AQUI: Rola para a esquerda ou direita dependendo de onde o jogador soltou
      _rolarTabuleiroParaAsPontas(esquerda: ponta == 'esquerda');

      if (resultado.fimDeJogo) {
        await _encerrarPartida();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Combinação incorreta.';
        _qtdErros++;
      });

      _mostrarSnack(e.toString().replaceAll('Exception: ', ''), isErro: true);
    }
  }

  Future<void> _encerrarPartida() async {
    final estado = _estado;
    if (estado == null || _partidaPersistida) {
      return;
    }

    _timer?.cancel();
    _partidaPersistida = true;

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Partida concluida',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acertos: $_qtdAcertos',
                style: GoogleFonts.nunito(fontSize: 14),
              ),
              Text(
                'Erros: $_qtdErros',
                style: GoogleFonts.nunito(fontSize: 14),
              ),
              Text(
                'Tempo: ${_formatarTempo(_tempoSegundos)}',
                style: GoogleFonts.nunito(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Voltar',
                style: GoogleFonts.nunito(
                  color: _vermelho,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: SafeArea(
        child: _carregando
            ? _buildCarregando()
            : _erro != null
            ? _buildErro()
            : _buildConteudo(),
      ),
    );
  }

  Widget _buildCarregando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _vermelho),
          const SizedBox(height: 16),
          Text(
            _mensagemStatus,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _vermelho, size: 48),
            const SizedBox(height: 16),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _mensagemStatus,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _iniciarPartida,
              style: ElevatedButton.styleFrom(
                backgroundColor: _vermelho,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    final estado = _estado!;
    return Column(
      children: [
        _buildHeader(estado),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatus(estado),
                const SizedBox(height: 24),
                _buildTabuleiro(estado),
                const SizedBox(height: 24),
                _buildMaoJogador(estado),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(StatusPartida estado) {
    return Container(
      color: _cinzaEscuro,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _vermelho,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dificuldade.titulo.toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.dificuldade.descricao,
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildHeaderItem(
                  icon: Icons.access_time,
                  label: 'Tempo',
                  value: _formatarTempo(_tempoSegundos),
                ),
                _buildHeaderItem(
                  icon: Icons.check_circle_outline,
                  label: 'Acertos',
                  value: '$_qtdAcertos',
                  iconColor: Colors.greenAccent,
                ),
                _buildHeaderItem(
                  icon: Icons.cancel_outlined,
                  label: 'Erros',
                  value: '$_qtdErros',
                  iconColor: Colors.redAccent,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sair',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = Colors.white70,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatus(StatusPartida estado) {
    final turno = estado.fimDeJogo ? 'Fim de Jogo' : 'Sua vez';

    String pontas = "";
    if (estado.mesa.isNotEmpty) {
      pontas =
          "Esq: ${estado.mesa.first.visivelEsquerdo} | Dir: ${estado.mesa.last.visivelDireito}";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // O AnimatedSwitcher cuida de animar a troca de conteúdo automaticamente
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack, // Efeito leve de "mola" ao entrar
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        // A chave (Key) baseada na mensagem garante que o Flutter saiba quando rodar a animação
        key: ValueKey<String>('$turno-${_mensagemStatus}'),
        child: Column(
          key: ValueKey<String>('$turno-${_mensagemStatus}-inner'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Indicador visual piscante (Dot animado)
                if (!estado.fimDeJogo)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.4, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    onEnd:
                        () {}, // Gambiarra nativa para fazer o Flutter reconstruir em loop se quiser, mas para o pulso contínuo o ideal é repetir:
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: _processandoJogada
                            ? 0.4
                            : (DateTime.now().millisecond % 2 == 0
                                  ? 0.5
                                  : 1.0), // Cria um senso de atividade ativo
                        child: Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Colors
                                .green, // Verde ativo para o turno do jogador
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),

                // Texto do Turno Animado em Escala/Cor
                Text(
                  turno,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: estado.fimDeJogo ? _cinzaEscuro : _vermelho,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mensagem de Status (ex: "Validando jogada...")
            Text(
              _mensagemStatus,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: _processandoJogada ? _vermelho : Colors.grey[700],
                fontWeight: _processandoJogada
                    ? FontWeight.w700
                    : FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Mini badge das pontas ativas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _cinzaFundo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    estado.mesa.isEmpty
                        ? 'Mesa vazia'
                        : 'Pontas ativas: $pontas',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabuleiro(StatusPartida estado) {
    return Container(
      // Definimos uma altura fixa para o tabuleiro para garantir que o scroll
      // horizontal não "dance" verticalmente
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.red, // Mantido sua cor vermelha de teste
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho fixo (não scrolla)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tabuleiro',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Arraste para os lados para ver tudo',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Área de jogo Scrollável
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ScrollConfiguration(
                  // Permite que o scroll funcione com o "clique e arraste" do mouse no PC/Web
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: SingleChildScrollView(
                    controller: _tabuleiroScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    // ConstrainedBox garante que a área "arrastável" tenha no mínimo
                    // a largura da tela, tornando todo o fundo vermelho tocável
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. ZONA DE SOLTURA DA ESQUERDA
                            if (!estado.fimDeJogo && !_processandoJogada)
                              _buildZonaSoltura(ponta: 'esquerda')
                            else
                              const SizedBox(width: 20),

                            const SizedBox(width: 16),

                            // Peças centrais da mesa
                            for (int i = 0; i < estado.mesa.length; i++) ...[
                              _buildPecaEstilizada(
                                estado.mesa[i],
                                emMesa: true,
                              ),
                              if (i != estado.mesa.length - 1) _buildSeta(),
                            ],

                            const SizedBox(width: 16),

                            // 2. ZONA DE SOLTURA DA DIREITA
                            if (!estado.fimDeJogo && !_processandoJogada)
                              _buildZonaSoltura(ponta: 'direita')
                            else
                              const SizedBox(width: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget visual que brilha ao arrastar a peça por cima
  Widget _buildZonaSoltura({required String ponta}) {
    return DragTarget<PecaDomino>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _confirmarJogada(details.data, ponta);
      },
      builder: (context, candidateData, rejectedData) {
        final estaPorCima = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: estaPorCima
                ? _vermelho.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estaPorCima ? _vermelho : Colors.white30,
              width: estaPorCima ? 3 : 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ponta == 'esquerda' ? Icons.arrow_back : Icons.arrow_forward,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                ponta == 'esquerda' ? 'Ponta\nEsq.' : 'Ponta\nDir.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- COMPONENTE VISUAL REESTILIZADO: A PEÇA DE DOMINÓ REALISTA ---
  Widget _buildPecaEstilizada(PecaDomino peca, {required bool emMesa}) {
    return Container(
      width: emMesa ? 180 : 210,
      height: emMesa ? 80 : 90,
      decoration: BoxDecoration(
        color: _corPecaDomino,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordaPecaDomino, width: 2),
        boxShadow: [
          BoxShadow(
            color: emMesa ? Colors.black45 : Colors.black12,
            blurRadius: emMesa ? 6 : 4,
            offset: emMesa ? const Offset(2, 4) : const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Divisória e Lados da Peça
          Row(
            children: [
              Expanded(
                child: _buildLadoPeca(peca.visivelEsquerdo, emMesa: emMesa),
              ),

              // Linha divisória clássica de dominó de osso/marfim
              Container(
                width: 2,
                height: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black26,
              ),

              Expanded(
                child: _buildLadoPeca(peca.visivelDireito, emMesa: emMesa),
              ),
            ],
          ),

          // O Pino Central Metálico clássico das peças de dominó físicas
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFB8860B), // Cor bronze/dourada para o pino
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLadoPeca(String valorLado, {required bool emMesa}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Center(
        child: Text(
          valorLado,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: emMesa ? 12 : 13,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2C3E50), // Cor grafite escura elegante
          ),
        ),
      ),
    );
  }

  Widget _buildMaoJogador(StatusPartida estado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua mão',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toque e segure na peça para arrastá-la até o tabuleiro',
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          if (estado.maoJogador.isEmpty)
            Text(
              'Nenhuma peça restante.',
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 20,
              children: estado.maoJogador.map((peca) {
                // Desabilita o arrasto se o jogo estiver processando algo
                final podeInteragir = !_processandoJogada && !estado.fimDeJogo;

                return Opacity(
                  opacity: podeInteragir ? 1.0 : 0.5,
                  child: Draggable<PecaDomino>(
                    data: peca,
                    maxSimultaneousDrags: podeInteragir ? 1 : 0,
                    // O que aparece flutuando sob o dedo do usuário enquanto ele arrasta:
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.85,
                        child: _buildPecaEstilizada(peca, emMesa: false),
                      ),
                    ),
                    // O que fica no lugar original enquanto a peça está voando:
                    childWhenDragging: Opacity(
                      opacity: 0.2,
                      child: _buildPecaEstilizada(peca, emMesa: false),
                    ),
                    // Peça em estado normal de repouso:
                    child: _buildPecaEstilizada(peca, emMesa: false),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSeta() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color:
            Colors.white70, // Seta clara para combinar com o fundo verde-feltro
        size: 20,
      ),
    );
  }

  String _formatarTempo(int segundosTotais) {
    final minutos = (segundosTotais ~/ 60).toString().padLeft(2, '0');
    final segundos = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  void _rolarTabuleiroParaAsPontas({bool esquerda = false}) {
    // Pequeno delay para esperar o Flutter renderizar a nova peça antes de scrollar
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_tabuleiroScrollController.hasClients) {
        if (esquerda) {
          _tabuleiroScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        } else {
          _tabuleiroScrollController.animateTo(
            _tabuleiroScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _mostrarSnack(String mensagem, {required bool isErro}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? _vermelho : Colors.green[700],
      ),
    );
  }

  void _rolarTabuleiroParaDireita() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabuleiroScrollController.hasClients) {
        return;
      }

      _tabuleiroScrollController.animateTo(
        _tabuleiroScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }
}
