import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'jogo_models.dart';
import 'jogo_service.dart';

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

  final JogoService _jogoService = JogoService();
  final ScrollController _tabuleiroScrollController = ScrollController();

  EstadoPartida? _estado;
  Timer? _timer;
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
    });

    try {
      final estado = await _jogoService.iniciarPartida(
        dificuldade: widget.dificuldade,
        idUsuario: widget.idUsuario,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _estado = estado;
        _carregando = false;
        _mensagemStatus = 'Sua vez. Escolha uma peça compativel.';
      });
      _rolarTabuleiroParaDireita();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _estado == null || _estado!.finalizada) {
          return;
        }
        setState(() {
          _estado = _estado!.copyWith(
            tempoSegundos: _estado!.tempoSegundos + 1,
          );
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

  Future<void> _jogarPeca(PecaJogo peca) async {
    final estado = _estado;
    if (estado == null || _processandoJogada || estado.finalizada) {
      return;
    }

    setState(() {
      _processandoJogada = true;
      _mensagemStatus = 'Validando jogada...';
    });

    try {
      final resultado = await _jogoService.jogarPeca(
        estado: estado,
        peca: peca,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _estado = resultado.estado;
        _mensagemStatus = resultado.mensagem;
        _processandoJogada = false;
      });
      _rolarTabuleiroParaDireita();

      if (resultado.estado.finalizada) {
        await _encerrarPartida();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Falha ao processar a jogada.';
      });

      _mostrarSnack(e.toString(), isErro: true);
    }
  }

  Future<void> _encerrarPartida() async {
    final estado = _estado;
    if (estado == null || _partidaPersistida) {
      return;
    }

    _timer?.cancel();
    _partidaPersistida = true;
    await _jogoService.finalizarPartida(estado: estado);

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
                'Acertos: ${estado.qtdAcertos}',
                style: GoogleFonts.nunito(fontSize: 14),
              ),
              Text(
                'Erros: ${estado.qtdErros}',
                style: GoogleFonts.nunito(fontSize: 14),
              ),
              Text(
                'Tempo: ${_formatarTempo(estado.tempoSegundos)}',
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
                  estado.dificuldade.titulo.toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  estado.dificuldade.descricao,
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
                  value: _formatarTempo(estado.tempoSegundos),
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
                  value: '${estado.qtdErros}',
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

  Widget _buildStatus(EstadoPartida estado) {
    final turno = estado.turnoAtual == TurnoPartida.jogador
        ? 'Sua vez'
        : 'Vez do bot';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            turno,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _vermelho,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mensagemStatus,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ponta ativa: ${estado.pontaAtiva.valor}',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabuleiro(EstadoPartida estado) {
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
            'Tabuleiro',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            controller: _tabuleiroScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final peca in estado.tabuleiro) ...[
                  _buildPecaTabuleiro(peca),
                  _buildSeta(),
                ],
                _buildPontaAtiva(estado.pontaAtiva),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPecaTabuleiro(PecaPosicionada peca) {
    final corOrigem = switch (peca.origem) {
      OrigemPeca.inicial => Colors.blueGrey,
      OrigemPeca.jogador => Colors.green,
      OrigemPeca.bot => _vermelho,
    };

    final legenda = switch (peca.origem) {
      OrigemPeca.inicial => 'Inicio',
      OrigemPeca.jogador => 'Voce',
      OrigemPeca.bot => 'Bot',
    };

    return Column(
      children: [
        Container(
          width: 170,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildLadoPeca(peca.esquerda)),
              Container(width: 1, color: Colors.grey[300]),
              Expanded(child: _buildLadoPeca(peca.direita)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: corOrigem.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            legenda,
            style: GoogleFonts.nunito(
              color: corOrigem,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPontaAtiva(LadoPeca lado) {
    return Container(
      width: 150,
      height: 76,
      decoration: BoxDecoration(
        color: _vermelho.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _vermelho, width: 2),
      ),
      child: Center(
        child: Text(
          lado.valor,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _vermelho,
          ),
        ),
      ),
    );
  }

  Widget _buildLadoPeca(LadoPeca lado) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          lado.valor,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
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
            'Sua mao',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (estado.maoJogador.isEmpty)
            Text(
              'Nenhuma peca restante.',
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: estado.maoJogador.map((peca) {
                return SizedBox(
                  width: 210,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildLadoPeca(peca.esquerda)),
                            Container(width: 1, color: Colors.grey[300]),
                            Expanded(child: _buildLadoPeca(peca.direita)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _processandoJogada || estado.finalizada
                              ? null
                              : () => _jogarPeca(peca),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _vermelho,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Jogar peca',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(Icons.arrow_forward_rounded, color: _vermelho),
    );
  }

  String _formatarTempo(int segundosTotais) {
    final minutos = (segundosTotais ~/ 60).toString().padLeft(2, '0');
    final segundos = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
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
