import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CadastrarAlunoScreen extends StatefulWidget {
  const CadastrarAlunoScreen({super.key});

  @override
  State<CadastrarAlunoScreen> createState() => _CadastrarAlunoScreenState();
}

class _CadastrarAlunoScreenState extends State<CadastrarAlunoScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();

  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _aceiteLgpd = false;

  static const _vermelho = Color(0xFFC0392B);
  static const _vermelhoEscuro = Color(0xFFA93226);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          // ─── BARRA VERMELHA ─────────────────────────────────
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
                // Opcional: Mostrar quem está logado
                MediaQuery.of(context).size.width > 600
                    ? Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Olá, Professor!',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),

          // ─── SETA DE VOLTAR ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ─── CONTEÚDO / FORMULÁRIO ──────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550), // Limita largura na Web
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho do Card
                      Icon(Icons.person_add_alt_1_rounded, size: 48, color: _vermelho),
                      const SizedBox(height: 16),
                      Text(
                        'Cadastrar Aluno',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os dados abaixo para criar um novo acesso.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Campos do Formulário
                      _buildCampo(
                        controller: _nomeCtrl,
                        hint: 'Nome Completo',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildCampo(
                        controller: _emailCtrl,
                        hint: 'E-mail do aluno',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildCampo(
                        controller: _senhaCtrl,
                        hint: 'Senha',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureToggle: _obscureSenha,
                        onToggleObscure: () => setState(() => _obscureSenha = !_obscureSenha),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildCampo(
                        controller: _confirmaSenhaCtrl,
                        hint: 'Confirmar Senha',
                        icon: Icons.lock_reset_outlined,
                        isPassword: true,
                        obscureToggle: _obscureConfirma,
                        onToggleObscure: () => setState(() => _obscureConfirma = !_obscureConfirma),
                      ),
                      const SizedBox(height: 24),

                      // Checkbox LGPD
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _cinzaFundo,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _aceiteLgpd,
                                activeColor: _vermelho,
                                onChanged: (val) {
                                  setState(() => _aceiteLgpd = val ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'O aluno (ou responsável) autoriza a coleta e o armazenamento de dados de desempenho no jogo para fins pedagógicos, conforme a LGPD.',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botão Cadastrar
                      ElevatedButton(
                        onPressed: _handleCadastro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vermelho,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Concluir Cadastro',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
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

  // ─── WIDGET DE CAMPO DE TEXTO ───────────────────────────────────────
  Widget _buildCampo({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureToggle = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscureToggle,
      style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureToggle ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey[400],
                ),
                onPressed: onToggleObscure,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
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

  // ─── VALIDAÇÃO DO FORMULÁRIO ────────────────────────────────────────
  void _handleCadastro() {
    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    final confirma = _confirmaSenhaCtrl.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirma.isEmpty) {
      _mostrarSnack('Preencha todos os campos.', isErro: true);
      return;
    }

    if (senha != confirma) {
      _mostrarSnack('As senhas não coincidem.', isErro: true);
      return;
    }

    if (!_aceiteLgpd) {
      _mostrarSnack('É necessário aceitar os termos da LGPD para cadastrar.', isErro: true);
      return;
    }

    // Sucesso
    debugPrint('Aluno Cadastrado: $nome | $email');
    _mostrarSnack('Aluno cadastrado com sucesso!', isErro: false);
    
    // Limpa os campos após o sucesso
    _nomeCtrl.clear();
    _emailCtrl.clear();
    _senhaCtrl.clear();
    _confirmaSenhaCtrl.clear();
    setState(() => _aceiteLgpd = false);
  }

  void _mostrarSnack(String mensagem, {required bool isErro}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem, 
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600)
        ),
        backgroundColor: isErro ? _vermelhoEscuro : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}