import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'telaInicial.dart';
import 'telaInicial_Professor.dart';
import 'usuario_sessao.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dominó Química',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFC0392B),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool _obscureSenha = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _vermelho = Color(0xFFC0392B);
  static const _vermelhoEscuro = Color(0xFFA93226);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ─── BARRA VERMELHA SUPERIOR ─────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFFFF7E70),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Image.asset(
                  'imagens/etec_santo_andre.png',
                  height: 75,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 75,
                    width: 150,
                    color: Colors.white.withValues(alpha: 0.3),
                    child: const Center(
                      child: Text(
                        'ETEC',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ─── CONTEÚDO ────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 900;
                final isTablet =
                    constraints.maxWidth > 600 && constraints.maxWidth <= 900;
                final isMobile = constraints.maxWidth <= 600;

                return Container(
                  color: _cinzaFundo,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen
                              ? 1200
                              : (isTablet ? 800 : double.infinity),
                        ),
                        child: isWideScreen
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildLeftPanel(
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildRightPanel(
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    height: isMobile ? 280 : 320,
                                    child: _buildLeftPanel(isMobile, isTablet),
                                  ),
                                  _buildRightPanel(isMobile, isTablet),
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

  Widget _buildLeftPanel(bool isMobile, bool isTablet) {
    final logoSize = isMobile ? 120.0 : (isTablet ? 150.0 : 180.0);
    final titleFontSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
    final subtitleFontSize = isMobile ? 10.0 : (isTablet ? 11.0 : 12.0);
    final padding = isMobile ? 24.0 : (isTablet ? 32.0 : 40.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          // Moléculas decorativas de fundo (apenas em telas maiores)
          if (!isMobile) ...[
            Positioned(
              top: 20,
              left: 20,
              child: _buildMolecule('H₂O', 0.6, isMobile),
            ),
            Positioned(
              top: 60,
              right: 40,
              child: _buildMolecule('NaCl', 0.5, isMobile),
            ),
            Positioned(
              bottom: 100,
              left: 30,
              child: _buildMolecule('H₂SO₄', 0.7, isMobile),
            ),
            Positioned(
              bottom: 40,
              right: 60,
              child: _buildMolecule('Ca(OH)₂', 0.55, isMobile),
            ),
          ],
          // Conteúdo principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: _vermelho,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(logoSize * 0.12),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(logoSize * 0.12),
                    child: Image.asset(
                      'imagens/logo_quimico.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: _vermelho.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.science,
                          size: 60,
                          color: _vermelho,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 20),
                // Título
                Text(
                  'DOMINÓ DA\nQUÍMICA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    color: _vermelho,
                    letterSpacing: 1.5,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Text(
                  'FUNÇÕES INORGÂNICAS',
                  style: GoogleFonts.nunito(
                    fontSize: subtitleFontSize,
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

  Widget _buildRightPanel(bool isMobile, bool isTablet) {
    final padding = isMobile ? 24.0 : (isTablet ? 35.0 : 40.0);
    final titleSize = isMobile ? 28.0 : (isTablet ? 30.0 : 32.0);
    final subtitleSize = isMobile ? 13.0 : 14.0;
    final buttonVerticalPadding = isMobile ? 14.0 : 16.0;
    final inputVerticalPadding = isMobile ? 14.0 : 15.0;

    return Container(
      padding: EdgeInsets.all(padding),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bem-vindo!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            'Faça login para continuar',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: subtitleSize,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Toggle Aluno/Professor
          Row(
            children: [
              Expanded(
                child: _buildToggleButton('Aluno', isStudent, isMobile, () {
                  setState(() => isStudent = true);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToggleButton(
                  'Professor',
                  !isStudent,
                  isMobile,
                  () {
                    setState(() => isStudent = false);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Campo de usuário/email
          _buildCampo(
            controller: _emailController,
            hint: isStudent
                ? 'xxxxxx@aluno.cps.sp.gov.br'
                : 'xxxxxx@cps.sp.gov.br',
            icon: Icons.person_outline,
            isMobile: isMobile,
            verticalPadding: inputVerticalPadding,
          ),
          const SizedBox(height: 12),

          // Campo de senha
          _buildCampo(
            controller: _passwordController,
            hint: 'Senha',
            icon: Icons.lock_outline,
            isPassword: true,
            isMobile: isMobile,
            verticalPadding: inputVerticalPadding,
          ),
          SizedBox(height: isMobile ? 20 : 28),

          // Botão Entrar
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Entrar',
              style: GoogleFonts.nunito(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isActive,
    bool isMobile,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: isActive ? _vermelho : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: isActive ? Colors.white : Colors.black54,
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isMobile,
    required double verticalPadding,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureSenha,
      style: GoogleFonts.nunito(
        fontSize: isMobile ? 13 : 14,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          fontSize: isMobile ? 13 : 14,
          color: Colors.grey[350],
        ),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.grey[400],
                ),
                onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: verticalPadding,
        ),
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

  Widget _buildMolecule(String formula, double opacity, bool isMobile) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Text(
          formula,
          style: GoogleFonts.nunito(
            fontSize: isMobile ? 14 : 16,
            color: Colors.black.withValues(alpha: 0.3),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preencha todos os campos',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _vermelhoEscuro,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      if (!mounted) {
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final perfil = data['perfil'];
        final sessao = UsuarioSessao(
          idUsuario: data['id_usuario'] as int,
          nome: data['nome'] as String,
          email: data['email'] as String,
          perfil: perfil as String,
        );

        if (perfil == 'aluno') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TelaInicial(sessao: sessao)),
          );
        } else if (perfil == 'professor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TelaInicialProfessor(sessao: sessao),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['detail'] ?? 'Erro no login',
              style: GoogleFonts.nunito(),
            ),
            backgroundColor: _vermelhoEscuro,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro de conexão com servidor',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _vermelhoEscuro,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
