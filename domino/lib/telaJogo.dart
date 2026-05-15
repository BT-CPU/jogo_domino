import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Atualizado para os seus novos modelos e service do backend em Python
import 'partida_model.dart'; 
import 'partida_service.dart';
import 'jogo_models.dart' hide StatusPartida; // Mantido para carregar a DificuldadeJogo do seu Enum

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
        widget.dificuldade.index + 1, // Mapeando seu Enum para o nível do backend
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _estado = estado;
        _carregando = false;
        _mensagemStatus = estado.status;
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

  // --- NOVA FUNÇÃO: ABRE A ESCOLHA DA PONTA ---
  void _mostrarEscolhaDePonta(PecaDomino peca) {
    if (_processandoJogada || _estado!.fimDeJogo) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Onde deseja encaixar a peça?',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmarJogada(peca, 'esquerda');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Ponta Esquerda', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmarJogada(peca, 'direita');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vermelho,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Ponta Direita', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNÇÃO ORIGINAL ADAPTADA ---
  Future<void> _confirmarJogada(PecaDomino peca, String ponta) async {
    final estado = _estado;
    if (estado == null || _processandoJogada || estado.fimDeJogo) {
      return;
    }

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

      if (!mounted) {
        return;
      }

      setState(() {
        _estado = resultado;
        _mensagemStatus = resultado.status;
        _qtdAcertos++; // Computa o acerto
        _processandoJogada = false;
      });
      _rolarTabuleiroParaDireita();

      if (resultado.fimDeJogo) {
        await _encerrarPartida();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _processandoJogada = false;
        _mensagemStatus = 'Combinação incorreta.';
        _qtdErros++; // Computa o erro
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
    
    // Se você tiver um método para salvar a partida no backend, chame-o aqui
    // await _partidaService.finalizarPartida(estado: estado);

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
    // Como o backend agora gerencia o bot internamente em cada jogada, a vez no app é sempre do jogador.
    final turno = estado.fimDeJogo ? 'Fim de Jogo' : 'Sua vez';
    
    // Obtém as pontas ativas atuais da mesa
    String pontas = "";
    if (estado.mesa.isNotEmpty) {
      pontas = "Esq: ${estado.mesa.first.visivelEsquerdo} | Dir: ${estado.mesa.last.visivelDireito}";
    }

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
            'Pontas ativas: $pontas',
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

  Widget _buildTabuleiro(StatusPartida estado) {
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
                for (final peca in estado.mesa) ...[
                  _buildPecaTabuleiro(peca),
                  if (peca != estado.mesa.last) _buildSeta(), // Evita seta depois da última peça
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPecaTabuleiro(PecaDomino peca) {
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
              Expanded(child: _buildLadoPeca(peca.visivelEsquerdo)),
              Container(width: 1, color: Colors.grey[300]),
              Expanded(child: _buildLadoPeca(peca.visivelDireito)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Mesa',
            style: GoogleFonts.nunito(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // Alterado para receber String em vez do modelo antigo LadoPeca
  Widget _buildLadoPeca(String valorLado) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          valorLado,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
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
                            Expanded(child: _buildLadoPeca(peca.visivelEsquerdo)),
                            Container(width: 1, color: Colors.grey[300]),
                            Expanded(child: _buildLadoPeca(peca.visivelDireito)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _processandoJogada || estado.fimDeJogo
                              ? null
                              : () => _mostrarEscolhaDePonta(peca), // CHAMA O NOVO MENU AQUI
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