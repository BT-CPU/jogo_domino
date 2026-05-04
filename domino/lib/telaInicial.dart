import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'telaLogin.dart';

// ─── TELA INICIAL (MENU PRINCIPAL) ────────────────────────────────────────
class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          // Barra Vermelha
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
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Olá, Aluno!',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Conteúdo do Menu
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Menu Principal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha uma das opções abaixo para continuar',
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
                          _buildMenuCard(
                            context: context,
                            title: 'Nova Partida',
                            subtitle: 'Iniciar jogo de classificação',
                            icon: Icons.play_arrow_rounded,
                            isPrimary: true,
                            onTap: () {
                              debugPrint('Navegar para a tela do jogo');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Meus Relatórios',
                            subtitle: 'Veja seu desempenho',
                            icon: Icons.bar_chart_rounded,
                            onTap: () {
                              debugPrint('Navegar para relatórios');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Regras do Jogo',
                            subtitle: 'Como jogar o dominó',
                            icon: Icons.menu_book_rounded,
                            onTap: () {
                              Navigator.pushNamed(context, '/howToPlay');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Sair',
                            subtitle: 'Desconectar da conta',
                            icon: Icons.logout_rounded,
                            iconColor: Colors.grey[600],
                            onTap: () {
                              // Volta para a tela de Login
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ],
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

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? iconColor,
  }) {
    return Material(
      color: isPrimary ? _vermelho : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: isPrimary ? Colors.red[800] : Colors.grey[100],
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? _vermelho : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : _cinzaFundo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isPrimary ? Colors.white : (iconColor ?? _vermelho),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isPrimary ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
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
      ..color = Colors.white.withOpacity(0.95)
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
      Paint()..color = const Color(0xFFE74C3C).withOpacity(0.75),
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
