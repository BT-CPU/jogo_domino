import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogo_models.dart';
import 'telaJogo.dart';

class TelaDificuldade extends StatefulWidget {
  const TelaDificuldade({super.key});

  @override
  State<TelaDificuldade> createState() => _TelaDificuldadeState();
}

class _TelaDificuldadeState extends State<TelaDificuldade> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  int? _dificuldadeSelecionada;

  DificuldadeJogo? get _dificuldadeAtual {
    if (_dificuldadeSelecionada == null) {
      return null;
    }
    return DificuldadeJogo.fromId(_dificuldadeSelecionada!);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 255, 126, 112),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'imagens/etec_santo_andre.png',
                  height: 75,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 75,
                    width: 150,
                    child: Placeholder(color: Colors.white),
                  ),
                ),
                if (isWide)
                  Text(
                    'Selecione a dificuldade',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogoHexagono(),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'DOMINÓ DA\nQUÍMICA',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: _vermelho,
                                  letterSpacing: 1.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'FUNÇÕES INORGÂNICAS',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[500],
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Escolha a Dificuldade',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cada modo trabalha um tipo diferente de relação entre as peças.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _DifficultyCard(
                            titulo: 'Dificuldade 1',
                            subtitulo: 'Fórmula ↔ Função',
                            descricao:
                                'Relacione a fórmula química com a função inorgânica correspondente.',
                            icon: Icons.science_outlined,
                            destaque: _dificuldadeSelecionada == 1,
                            onTap: () => setState(() {
                              _dificuldadeSelecionada = 1;
                            }),
                          ),
                          _DifficultyCard(
                            titulo: 'Dificuldade 2',
                            subtitulo: 'Propriedades ↔ Classificação',
                            descricao:
                                'Associe as propriedades observadas à classificação correta da substância.',
                            icon: Icons.category_outlined,
                            destaque: _dificuldadeSelecionada == 2,
                            onTap: () => setState(() {
                              _dificuldadeSelecionada = 2;
                            }),
                          ),
                          _DifficultyCard(
                            titulo: 'Dificuldade 3',
                            subtitulo: 'Classificação ↔ Reação',
                            descricao:
                                'Relacione classes químicas que reagem entre si.',
                            icon: Icons.hub_outlined,
                            destaque: _dificuldadeSelecionada == 3,
                            onTap: () => setState(() {
                              _dificuldadeSelecionada = 3;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(
                          'Voltar ao menu',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _vermelho,
                          side: const BorderSide(color: _vermelho),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _dificuldadeAtual == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TelaJogo(
                                      dificuldade: _dificuldadeAtual!,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'Iniciar partida',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vermelho,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.titulo,
    required this.subtitulo,
    required this.descricao,
    required this.icon,
    required this.onTap,
    this.destaque = false,
  });

  final String titulo;
  final String subtitulo;
  final String descricao;
  final IconData icon;
  final VoidCallback onTap;
  final bool destaque;

  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 290,
          height: 272,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: destaque ? _vermelho : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: destaque ? _vermelho : Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: destaque
                      ? Colors.white.withValues(alpha: 0.18)
                      : _cinzaFundo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: destaque ? Colors.white : _vermelho,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: destaque ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitulo,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: destaque ? Colors.white70 : _vermelho,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                descricao,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  height: 1.45,
                  color: destaque ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildLogoHexagono() {
  return SizedBox(
    width: 90,
    height: 90,
    child: CustomPaint(painter: _HexLogoPainter()),
  );
}

class _HexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.14159 / 180;
      final x = cx + r * 0.95 * cos(angle);
      final y = cy + r * 0.95 * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFC0392B));

    final innerPath = Path();
    final ir = r * 0.82;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.14159 / 180;
      final x = cx + ir * cos(angle);
      final y = cy + ir * sin(angle);
      i == 0 ? innerPath.moveTo(x, y) : innerPath.lineTo(x, y);
    }
    innerPath.close();
    canvas.drawPath(innerPath, Paint()..color = const Color(0xFFA93226));

    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final flask = Path()
      ..moveTo(cx - 10, cy - 16)
      ..lineTo(cx - 10, cy - 4)
      ..lineTo(cx - 18, cy + 14)
      ..quadraticBezierTo(cx - 20, cy + 20, cx, cy + 20)
      ..quadraticBezierTo(cx + 20, cy + 20, cx + 18, cy + 14)
      ..lineTo(cx + 10, cy - 4)
      ..lineTo(cx + 10, cy - 16)
      ..close();
    canvas.drawPath(flask, iconPaint);

    final liquid = Path()
      ..moveTo(cx - 14, cy + 10)
      ..quadraticBezierTo(cx, cy + 8, cx + 14, cy + 10)
      ..lineTo(cx + 18, cy + 14)
      ..quadraticBezierTo(cx + 20, cy + 20, cx, cy + 20)
      ..quadraticBezierTo(cx - 20, cy + 20, cx - 18, cy + 14)
      ..close();
    canvas.drawPath(
      liquid,
      Paint()..color = const Color(0xFFE74C3C).withValues(alpha: 0.75),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 18), width: 22, height: 5),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white,
    );
  }

  double cos(double a) => math.cos(a);
  double sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
