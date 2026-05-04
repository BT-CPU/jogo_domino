import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAluno = true;
  bool _obscureSenha = true;
  final _usuarioCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  static const _vermelho = Color(0xFFC0392B);
  static const _vermelhoEscuro = Color(0xFFA93226);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final isWide = MediaQuery.of(context).size.width > 600;

  return Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        // ─── BARRA VERMELHA ─────────────────────────────────
        Container(
          width: double.infinity,
          color: const Color.fromARGB(255, 255, 126, 112),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Image.asset('imagens/etec_santo_andre.png', height: 75),
            ],
          ),
        ),
        // ─── CONTEÚDO ────────────────────────────────────────
        Expanded(
          child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
        ),
      ],
    ),
  );
}

  // Layout lado a lado (tablet/desktop)
  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildLeftPanel()),
        Expanded(flex: 5, child: _buildRightPanel()),
      ],
    );
  }

  // Layout empilhado (celular)
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 220, child: _buildLeftPanel()),
          _buildRightPanel(),
        ],
      ),
    );
  }

  // ─── PAINEL ESQUERDO ───────────────────────────────────────────────
  Widget _buildLeftPanel() {
    return Container(
      color: _cinzaFundo,
      child: Stack(
        children: [
          // Conteúdo central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogoHexagono(),
                const SizedBox(height: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHexagono() {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(painter: _HexLogoPainter()),
    );
  }

  // ─── PAINEL DIREITO ────────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bem-vindo!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Faça login para continuar',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Campo usuário
          _buildCampo(
            controller: _usuarioCtrl,
            hint: 'Usuário ou e-mail',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          // Campo senha
          _buildCampo(
            controller: _senhaCtrl,
            hint: 'Senha',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 50),

          // Botão entrar
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Entrar',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureSenha,
      style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[350]),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.grey[400],
                ),
                onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _vermelho, width: 1.5),
        ),
      ),
    );
  }

  void _handleLogin() {
    final usuario = _usuarioCtrl.text.trim();
    final senha = _senhaCtrl.text;
    final role = _isAluno ? 'aluno' : 'professor';

    if (usuario.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha todos os campos',
              style: GoogleFonts.nunito()),
          backgroundColor: _vermelhoEscuro,
        ),
      );
      return;
    }

    debugPrint('Login: $usuario | Role: $role');
    // Navigator.pushReplacementNamed(context, '/home');
  }
}

// ─── HEXÁGONO COM FRASCO ──────────────────────────────────────────────
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

    // sombra interna
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

    // Frasco (simplificado com ícone embutido)
    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // corpo do frasco
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

    // líquido
    final liquid = Path()
      ..moveTo(cx - 14, cy + 10)
      ..quadraticBezierTo(cx, cy + 8, cx + 14, cy + 10)
      ..lineTo(cx + 18, cy + 14)
      ..quadraticBezierTo(cx + 20, cy + 20, cx, cy + 20)
      ..quadraticBezierTo(cx - 20, cy + 20, cx - 18, cy + 14)
      ..close();
    canvas.drawPath(liquid, Paint()..color = const Color(0xFFE74C3C).withOpacity(0.75));

    // boca do frasco
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
