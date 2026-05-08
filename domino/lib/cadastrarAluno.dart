import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ─── MODELO DE USUÁRIO ──────────────────────────────────────────────────────
class Usuario {
  final int id;
  final String nome;
  final String email;
  final String perfil;
  final String dataCadastro;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.dataCadastro,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id_usuario'],
        nome: json['nome'],
        email: json['email'],
        perfil: json['perfil'] ?? 'aluno',
        dataCadastro: json['data_cadastro'] ?? '',
      );
}

// ─── SERVIÇO DE API ─────────────────────────────────────────────────────────
class UsuarioService {
  static const String _baseUrl = 'https://domino-api-production.up.railway.app';

  static Future<List<Usuario>> listarUsuarios() async {
    final response = await http.get(Uri.parse('$_baseUrl/usuarios'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Usuario.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar usuários: ${response.statusCode}');
  }

  static Future<String> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required bool aceiteLgpd,
    required String perfil,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'aceite_lgpd': aceiteLgpd,
        'perfil': perfil,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return body['mensagem'];
    }
    throw Exception(body['detail'] ?? 'Erro ao cadastrar.');
  }

  static Future<void> excluirUsuario(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/usuarios/$id'));
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Erro ao excluir.');
    }
  }
}

// ─── TELA CADASTRAR USUÁRIO ──────────────────────────────────────────────────
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
  bool _carregando = false;
  String _perfilSelecionado = 'aluno'; // ← novo

  List<Usuario> _usuarios = [];
  bool _carregandoUsuarios = true;
  String? _erroUsuarios;

  static const _vermelho = Color(0xFFC0392B);
  static const _vermelhoEscuro = Color(0xFFA93226);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuarios() async {
    setState(() {
      _carregandoUsuarios = true;
      _erroUsuarios = null;
    });
    try {
      final lista = await UsuarioService.listarUsuarios();
      setState(() => _usuarios = lista);
    } catch (e) {
      setState(() => _erroUsuarios = e.toString());
    } finally {
      setState(() => _carregandoUsuarios = false);
    }
  }

  Future<void> _confirmarExclusao(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Excluir ${usuario.perfil == 'professor' ? 'Professor' : 'Aluno'}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
          'Deseja realmente excluir "${usuario.nome}"?\nEsta ação não pode ser desfeita.',
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.nunito(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Excluir', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await UsuarioService.excluirUsuario(usuario.id);
        _mostrarSnack('"${usuario.nome}" excluído.', isErro: false);
        _carregarUsuarios();
      } catch (e) {
        _mostrarSnack(e.toString(), isErro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          // ─── BARRA VERMELHA ──────────────────────────────────────────
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
                if (MediaQuery.of(context).size.width > 600)
                  Row(
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
                  ),
              ],
            ),
          ),

          // ─── SETA DE VOLTAR ──────────────────────────────────────────
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

          // ─── CONTEÚDO ────────────────────────────────────────────────
          Expanded(
            child: Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Column(
                      children: [
                        _buildFormulario(),
                        const SizedBox(height: 40),
                        _buildTabela(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FORMULÁRIO ─────────────────────────────────────────────────────────
  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            _perfilSelecionado == 'professor'
                ? Icons.school_rounded
                : Icons.person_add_alt_1_rounded,
            size: 48,
            color: _vermelho,
          ),
          const SizedBox(height: 16),
          Text(
            'Cadastrar Usuário',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha os dados abaixo para criar um novo acesso.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 28),

          // ─── SELETOR DE PERFIL ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _cinzaFundo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                _buildPerfilOpcao('aluno', 'Aluno', Icons.person_rounded),
                _buildPerfilOpcao('professor', 'Professor', Icons.school_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildCampo(controller: _nomeCtrl, hint: 'Nome Completo', icon: Icons.badge_outlined),
          const SizedBox(height: 16),
          _buildCampo(controller: _emailCtrl, hint: 'E-mail', icon: Icons.email_outlined),
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
                    onChanged: (val) => setState(() => _aceiteLgpd = val ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O usuário autoriza a coleta e o armazenamento de dados de desempenho no jogo para fins pedagógicos, conforme a LGPD.',
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _carregando ? null : _handleCadastro,
            style: ElevatedButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _carregando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Concluir Cadastro',
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── BOTÃO DE SELEÇÃO DE PERFIL ─────────────────────────────────────────
  Widget _buildPerfilOpcao(String valor, String label, IconData icon) {
    final selecionado = _perfilSelecionado == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _perfilSelecionado = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selecionado ? _vermelho : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selecionado ? Colors.white : Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selecionado ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TABELA DE USUÁRIOS ─────────────────────────────────────────────────
  Widget _buildTabela() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuários Cadastrados',
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  Text(
                    '${_usuarios.length} usuário${_usuarios.length != 1 ? 's' : ''} no sistema',
                    style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Atualizar lista',
                icon: const Icon(Icons.refresh_rounded, color: _vermelho),
                onPressed: _carregandoUsuarios ? null : _carregarUsuarios,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_carregandoUsuarios)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _vermelho)))
          else if (_erroUsuarios != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Não foi possível carregar os usuários.', style: GoogleFonts.nunito(color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _carregarUsuarios,
                      icon: const Icon(Icons.refresh, color: _vermelho),
                      label: Text('Tentar novamente', style: GoogleFonts.nunito(color: _vermelho, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            )
          else if (_usuarios.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.group_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Nenhum usuário cadastrado ainda.', style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(2),
                  4: FixedColumnWidth(56),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: _vermelho),
                    children: [
                      _headerCell('Nome'),
                      _headerCell('E-mail'),
                      _headerCell('Perfil'),
                      _headerCell('Cadastro'),
                      _headerCell(''),
                    ],
                  ),
                  ..._usuarios.asMap().entries.map((entry) {
                    final i = entry.key;
                    final usuario = entry.value;
                    final isEven = i % 2 == 0;
                    return TableRow(
                      decoration: BoxDecoration(color: isEven ? _cinzaFundo : Colors.white),
                      children: [
                        _dataCell(usuario.nome),
                        _dataCell(usuario.email),
                        // Badge de perfil
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: usuario.perfil == 'professor'
                                    ? Colors.blue[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: usuario.perfil == 'professor'
                                      ? Colors.blue[200]!
                                      : Colors.green[200]!,
                                ),
                              ),
                              child: Text(
                                usuario.perfil == 'professor' ? 'Professor' : 'Aluno',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: usuario.perfil == 'professor'
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _dataCell(usuario.dataCadastro),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Center(
                            child: IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: Colors.red[400],
                              onPressed: () => _confirmarExclusao(usuario),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TableCell _headerCell(String text) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text,
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ),
      );

  TableCell _dataCell(String text) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text,
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
        ),
      );

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _vermelho, width: 1.5)),
      ),
    );
  }

  Future<void> _handleCadastro() async {
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

    setState(() => _carregando = true);
    try {
      final msg = await UsuarioService.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
        aceiteLgpd: _aceiteLgpd,
        perfil: _perfilSelecionado,
      );
      _mostrarSnack(msg, isErro: false);
      _nomeCtrl.clear();
      _emailCtrl.clear();
      _senhaCtrl.clear();
      _confirmaSenhaCtrl.clear();
      setState(() => _aceiteLgpd = false);
      _carregarUsuarios();
    } catch (e) {
      _mostrarSnack(e.toString().replaceAll('Exception: ', ''), isErro: true);
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _mostrarSnack(String mensagem, {required bool isErro}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        backgroundColor: isErro ? _vermelhoEscuro : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}