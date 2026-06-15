// tela_jogo.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'domino_models.dart';
import 'domino_service.dart';

class TelaJogo extends StatefulWidget {
  const TelaJogo({
    super.key,
    this.dificuldade = DificuldadeJogo.formulaClasse,
    this.idUsuario = 1,
  });

  final DificuldadeJogo dificuldade;
  final int? idUsuario;

  @override
  State<TelaJogo> createState() => _TelaJogoState();
}

class _TelaJogoState extends State<TelaJogo>
    with SingleTickerProviderStateMixin {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaEscuro = Color(0xFF333333);
  static const _cinzaFundo = Color(0xFFF7F7F7);
  static const _corPecaDomino = Color(0xFFFFFDF9);
  static const _bordaPecaDomino = Color(0xFFE6DCC8);
  static const _verdeAcerto = Color(0xFF27AE60);
  final DominoService _service = DominoService();
  final ScrollController _tabuleiroScrollController = ScrollController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  EstadoPartida? _estado;
  Timer? _timer;

  int _tempoSegundos = 0;
  int _qtdErros = 0;
  bool _carregando = true;
  bool _processandoJogada = false;
  bool _partidaPersistida = false;
  String? _erro;
  String _mensagemStatus = 'Preparando partida...';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _iniciarPartida();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _tabuleiroScrollController.dispose();
    super.dispose();
  }

  Future<void> _iniciarPartida() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _mensagemStatus = 'Preparando partida...';
      _tempoSegundos = 0;
      _qtdErros = 0;
      _partidaPersistida = false;
    });

    try {
      final estado = await _service.criarPartida(
        dificuldade: widget.dificuldade,
        idUsuario: widget.idUsuario ?? 1,
      );

      if (!mounted) return;

      setState(() {
        _estado = estado;
        _carregando = false;
        _mensagemStatus = estado.status;
      });

      Future.delayed(
        const Duration(milliseconds: 100),
        _rolarTabuleiroParaDireita,
      );

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _estado == null || _estado!.fimDeJogo) return;
        setState(() => _tempoSegundos++);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível iniciar a partida.';
        _mensagemStatus = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _confirmarJogada(PecaDomino peca, String ponta) async {
    final estado = _estado;
    if (estado == null || _processandoJogada || estado.fimDeJogo) return;

    setState(() {
      _processandoJogada = true;
      _mensagemStatus = 'Validando jogada na ponta $ponta...';
    });

    try {
      final resultado = await _service.jogarPeca(
        idPartida: estado.idPartida,
        idPeca: peca.idPeca,
        ponta: ponta,
      );

      if (!mounted) return;

      setState(() {
        _estado = resultado;
        _mensagemStatus = resultado.status;
        _processandoJogada = false;
      });

      _rolarTabuleiroParaAsPontas(esquerda: ponta == 'esquerda');

      if (resultado.fimDeJogo) await _encerrarPartida();
    } on JogadaInvalidaException catch (e) {
      if (!mounted) return;
      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Combinação incorreta.';
        _qtdErros++;
      });
      _mostrarSnack(e.toString(), isErro: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Erro inesperado.';
      });
      _mostrarSnack(e.toString(), isErro: true);
    }
  }

  Future<void> _comprarPeca() async {
    final estado = _estado;
    if (estado == null || _processandoJogada || estado.fimDeJogo) return;

    if (estado.quantidadeMonte == 0) {
      _mostrarSnack('O monte está vazio!', isErro: true);
      return;
    }

    setState(() {
      _processandoJogada = true;
      _mensagemStatus = 'Comprando peça do monte...';
    });

    try {
      final resultado = await _service.comprarPeca(idPartida: estado.idPartida);

      if (!mounted) return;

      setState(() {
        _estado = resultado;
        _mensagemStatus = resultado.status;
        _processandoJogada = false;
      });
    } on MonteVazioException catch (e) {
      if (!mounted) return;
      setState(() => _processandoJogada = false);
      _mostrarSnack(e.toString(), isErro: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Erro ao comprar peça.';
      });
      _mostrarSnack(e.toString(), isErro: true);
    }
  }

  Future<void> _passarVez() async {
    final estado = _estado;
    if (estado == null || _processandoJogada || estado.fimDeJogo) return;

    setState(() {
      _processandoJogada = true;
      _mensagemStatus = 'Passando a vez...';
    });

    try {
      final resultado = await _service.passarVez(idPartida: estado.idPartida);

      if (!mounted) return;

      setState(() {
        _estado = resultado;
        _mensagemStatus = resultado.status;
        _processandoJogada = false;
      });

      if (resultado.fimDeJogo) await _encerrarPartida();
    } on PassarVezBloqueadaException catch (e) {
      if (!mounted) return;
      setState(() => _processandoJogada = false);
      _mostrarSnack(e.toString(), isErro: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Erro ao passar a vez.';
      });
      _mostrarSnack(e.toString(), isErro: true);
    }
  }

  Future<void> _encerrarPartida() async {
    final estado = _estado;
    if (estado == null || _partidaPersistida) return;

    _timer?.cancel();
    _partidaPersistida = true;

    try {
      await _service.finalizarPartida(
        idUsuario: widget.idUsuario ?? 1,
        dificuldade: widget.dificuldade,
        tempoSegundos: _tempoSegundos,
        idPartida: estado.idPartida,
        qtdErros: _qtdErros,
      );
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Partida concluída',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mensagemStatus,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _cinzaEscuro,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Acertos: ${_estado?.qtdAcertos ?? 0}',
              style: GoogleFonts.nunito(fontSize: 14),
            ),
            Text('Erros: $_qtdErros', style: GoogleFonts.nunito(fontSize: 14)),
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
              _iniciarPartida();
            },
            child: Text(
              'Jogar de novo',
              style: GoogleFonts.nunito(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
      ),
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

  Widget _buildHeader(EstadoPartida estado) {
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
                  value: '${estado.qtdAcertos}',
                  iconColor: Colors.greenAccent,
                ),
                _buildHeaderItem(
                  icon: Icons.cancel_outlined,
                  label: 'Erros',
                  value: '$_qtdErros',
                  iconColor: Colors.redAccent,
                ),
                _buildHeaderItem(
                  icon: Icons.style_outlined,
                  label: 'Monte',
                  value: '${estado.quantidadeMonte}',
                  iconColor: Colors.amberAccent,
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

  Widget _buildStatus(EstadoPartida estado) {
    final turno = estado.fimDeJogo ? 'Fim de Jogo' : 'Sua vez';
    final pontas = estado.mesa.isEmpty
        ? 'Mesa vazia'
        : 'Esq: ${estado.mesa.first.visivelEsquerdo} | Dir: ${estado.mesa.last.visivelDireito}';
    final jogadorBloqueado =
        !estado.fimDeJogo && !estado.jogadorTemJogadas;
    final podePasar = !estado.fimDeJogo && estado.podePasar;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey<String>('$turno-$_mensagemStatus'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (!estado.fimDeJogo)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Opacity(
                      opacity: _processandoJogada ? 0.3 : _pulseAnim.value,
                      child: Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: jogadorBloqueado
                              ? Colors.orange
                              : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
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

            if (jogadorBloqueado) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        podePasar
                            ? 'Sem jogadas. Compre mais peças ou passe a vez.'
                            : 'Sem jogadas disponíveis. Compre uma peça do monte para poder passar.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                        Flexible(
                          child: Text(
                            'Pontas ativas: $pontas',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!estado.fimDeJogo) ...[
                  ElevatedButton.icon(
                    onPressed:
                        (_processandoJogada || estado.quantidadeMonte == 0)
                        ? null
                        : _comprarPeca,
                    icon: const Icon(Icons.add_card, size: 16),
                    label: Text(
                      'Comprar (${estado.quantidadeMonte})',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cinzaEscuro,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  if (podePasar) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _processandoJogada ? null : _passarVez,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: Text(
                        'Passar',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabuleiro(EstadoPartida estado) {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.red,
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ScrollConfiguration(
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
                            if (!estado.fimDeJogo && !_processandoJogada)
                              _buildZonaSoltura(ponta: 'esquerda')
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 16),
                            for (int i = 0; i < estado.mesa.length; i++) ...[
                              _buildPecaEstilizada(
                                estado.mesa[i],
                                emMesa: true,
                              ),
                              if (i != estado.mesa.length - 1) _buildSeta(),
                            ],
                            const SizedBox(width: 16),
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

  Widget _buildZonaSoltura({required String ponta}) {
    return DragTarget<PecaDomino>(
      onWillAcceptWithDetails: (details) => details.data is PecaDomino,
      onAcceptWithDetails: (details) {
        if (!_processandoJogada) _confirmarJogada(details.data, ponta);
      },
      builder: (context, candidateData, _) {
        final estaPorCima = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: estaPorCima
                ? _vermelho.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estaPorCima ? _vermelho : Colors.white30,
              width: estaPorCima ? 3 : 2,
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


  Widget _buildPecaEstilizada(PecaDomino peca, {required bool emMesa}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, 
      onLongPress: () => _mostrarZoomPeca(peca),
      child: Container(
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
            Row(
              children: [
                Expanded(
                  child: _buildLadoPeca(peca.visivelEsquerdo, emMesa: emMesa),
                ),
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
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFB8860B),
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
      ),
    );
  }

  Widget _buildLadoPeca(String valorLado, {required bool emMesa, bool isZoom = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Center(
        child: Text(
          valorLado,
          textAlign: TextAlign.center,
          maxLines: isZoom ? 10 : 5, 
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: isZoom ? 18 : (emMesa ? 11 : 12),
            fontWeight: FontWeight.w900,
            height: 1.1, 
            color: const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }

  void _mostrarZoomPeca(PecaDomino peca) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), 
            child: Container(
              width: 320, 
              height: 200,
              decoration: BoxDecoration(
                color: _corPecaDomino,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _bordaPecaDomino, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildLadoPeca(peca.visivelEsquerdo, emMesa: false, isZoom: true),
                      ),
                      Container(
                        width: 3,
                        height: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black26,
                      ),
                      Expanded(
                        child: _buildLadoPeca(peca.visivelDireito, emMesa: false, isZoom: true),
                      ),
                    ],
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8860B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaoJogador(EstadoPartida estado) {
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
            'Arraste a peça até uma das setas no tabuleiro',
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
                final podeInteragir = !_processandoJogada && !estado.fimDeJogo;
                return Opacity(
                  opacity: podeInteragir ? 1.0 : 0.5,
                  child: Draggable<PecaDomino>(
                    data: peca,
                    maxSimultaneousDrags: podeInteragir ? 1 : 0,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.85,
                        child: _buildPecaEstilizada(peca, emMesa: false),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.2,
                      child: _buildPecaEstilizada(peca, emMesa: false),
                    ),
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
        color: Colors.white70,
        size: 20,
      ),
    );
  }

  String _formatarTempo(int segundosTotais) {
    final m = (segundosTotais ~/ 60).toString().padLeft(2, '0');
    final s = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _rolarTabuleiroParaAsPontas({bool esquerda = false}) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_tabuleiroScrollController.hasClients) return;
      _tabuleiroScrollController.animateTo(
        esquerda ? 0 : _tabuleiroScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  void _rolarTabuleiroParaDireita() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabuleiroScrollController.hasClients) return;
      _tabuleiroScrollController.animateTo(
        _tabuleiroScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _mostrarSnack(String mensagem, {required bool isErro}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? _vermelho : _verdeAcerto,
      ),
    );
  }
}