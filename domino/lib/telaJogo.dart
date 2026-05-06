import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Modelo simples da Peça de Dominó
class PecaDominoModel {
  final String ladoEsquerdo;
  final String ladoDireito;

  PecaDominoModel(this.ladoEsquerdo, this.ladoDireito);
}

class TelaJogo extends StatefulWidget {
  const TelaJogo({super.key});

  @override
  State<TelaJogo> createState() => _TelaJogoState();
}

class _TelaJogoState extends State<TelaJogo> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaEscuro = Color(0xFF333333);
  static const _cinzaFundo = Color(0xFFF9F9F9);

  // ─── ESTADO DO JOGO ──────────────────────────────────────────────
  int _tempoSegundos = 0; // Começando em 02:35 para bater com o protótipo
  int _pontos = 0;
  final int _erros = 0;
  Timer? _timer;

  // Peças já colocadas no tabuleiro
  final List<PecaDominoModel> _tabuleiro = [
    PecaDominoModel('HCl', 'Ácido'),
    PecaDominoModel('NaOH', 'Base'),
    PecaDominoModel('NaCl', 'Sal'),
  ];

  // Peças disponíveis para o jogador
  final List<PecaDominoModel> _maoJogador = [
    PecaDominoModel('Óxido', 'CO₂'),
    PecaDominoModel('H₂SO₄', 'Ácido'),
    PecaDominoModel('CaO', 'Óxido'),
  ];

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _tempoSegundos++;
      });
    });
  }

  String get _tempoFormatado {
    final minutos = (_tempoSegundos ~/ 60).toString().padLeft(2, '0');
    final segundos = (_tempoSegundos % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  // Lógica quando o jogador solta a peça no alvo
  void _aoSoltarPeca(PecaDominoModel peca) {
    setState(() {
      _maoJogador.remove(peca);
      _tabuleiro.add(peca);
      _pontos += 10; // Exemplo: ganha 10 pontos ao acertar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabuleiro(),
                _buildMaoJogador(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ─── CABEÇALHO (HEADER) ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _cinzaEscuro,
      height: 80,
      child: Row(
        children: [
          // Aba vermelha do Nível
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: _vermelho,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NÍVEL 1',
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
                Text(
                  'Fórmula ↔ Função',
                  style: GoogleFonts.nunito(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Status: Tempo, Pontos, Erros
          _buildStatusItem(Icons.access_time, 'TEMPO', _tempoFormatado),
          const SizedBox(width: 32),
          _buildStatusItem(Icons.emoji_events_outlined, 'PONTOS', '$_pontos', isGold: true),
          const SizedBox(width: 32),
          _buildStatusItem(Icons.highlight_off, 'ERROS', '$_erros', isRed: true),
          const Spacer(),

          // Botão Sair
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _vermelho,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sair',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value,
      {bool isGold = false, bool isRed = false}) {
    Color iconColor = Colors.white70;
    if (isGold) iconColor = Colors.amber;
    if (isRed) iconColor = _vermelho;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    color: Colors.white54, fontSize: 10, letterSpacing: 1)),
            Text(value,
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ─── ÁREA DO TABULEIRO (CIMA) ────────────────────────────────────
  Widget _buildTabuleiro() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Renderiza as peças já jogadas
          ..._tabuleiro.expand((peca) => [
                _buildPecaEstatica(peca),
                _buildSeta(),
              ]),
          
          // O espaço vazio para soltar a peça (DragTarget)
          DragTarget<PecaDominoModel>(
            onAcceptWithDetails: (details) => _aoSoltarPeca(details.data),
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return Container(
                width: 120,
                height: 70,
                decoration: BoxDecoration(
                  color: isHovered ? Colors.red.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _vermelho,
                    width: 2,
                    style: BorderStyle.solid, 
                    // No Flutter puro, borda tracejada requer package (ex: dotted_border). 
                    // Usando sólida por enquanto para não quebrar seu projeto.
                  ),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _vermelho,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── MÃO DO JOGADOR (BAIXO) ──────────────────────────────────────
  Widget _buildMaoJogador() {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: _maoJogador.map((peca) {
        return Draggable<PecaDominoModel>(
          data: peca,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.8,
              child: _buildPecaEstatica(peca, isDragging: true),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3, // Deixa a peça meio transparente onde ela estava
            child: _buildPecaEstatica(peca),
          ),
          child: _buildPecaEstatica(peca),
        );
      }).toList(),
    );
  }

  // ─── RODAPÉ (FOOTER) ─────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Arraste uma peça para jogar',
            style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ─── WIDGETS AUXILIARES ──────────────────────────────────────────
  Widget _buildPecaEstatica(PecaDominoModel peca, {bool isDragging = false}) {
    return Container(
      width: 160,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: isDragging
            ? [const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]
            : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                peca.ladoEsquerdo,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.grey[300]),
          Expanded(
            child: Center(
              child: Text(
                peca.ladoDireito,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ...List.generate(
            3,
            (i) => Container(
              width: 6,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: _vermelho,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: _vermelho, size: 12),
        ],
      ),
    );
  }
}