import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ─── MODELO DE ALUNO ────────────────────────────────────────────────────────
class Aluno {
  final int id;
  final String nome;
  final String email;
  final String dataCadastro;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    required this.dataCadastro,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
        id: json['id_usuario'],
        nome: json['nome'],
        email: json['email'],
        dataCadastro: json['data_cadastro'] ?? '',
      );
}

// ─── SERVIÇO DE API ─────────────────────────────────────────────────────────
class AlunoService {
  // Troque pela URL do seu servidor (ex: http://192.168.1.10:8000)
  static const String _baseUrl = 'https://domino-api-production.up.railway.app';

  static Future<List<Aluno>> listarAlunos() async {
    final response = await http.get(Uri.parse('$_baseUrl/alunos'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Aluno.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar alunos: ${response.statusCode}');
  }

  static Future<String> cadastrarAluno({
    required String nome,
    required String email,
    required String senha,
    required bool aceiteLgpd,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/alunos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'aceite_lgpd': aceiteLgpd,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return body['mensagem'];
    }
    throw Exception(body['detail'] ?? 'Erro ao cadastrar aluno.');
  }

  static Future<void> excluirAluno(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/alunos/$id'));
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Erro ao excluir aluno.');
    }
  }
}

// ─── TELA CADASTRAR ALUNO ────────────────────────────────────────────────────
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

  List<Aluno> _alunos = [];
  bool _carregandoAlunos = true;
  String? _erroAlunos;

  static const _vermelho = Color(0xFFC0392B);
  static const _vermelhoEscuro = Color(0xFFA93226);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  // ─── CARREGAR LISTA DE ALUNOS ──────────────────────────────────────────
  Future<void> _carregarAlunos() async {
    setState(() {
      _carregandoAlunos = true;
      _erroAlunos = null;
    });
    try {
      final lista = await AlunoService.listarAlunos();
      setState(() => _alunos = lista);
    } catch (e) {
      setState(() => _erroAlunos = e.toString());
    } finally {
      setState(() => _carregandoAlunos = false);
    }
  }

  // ─── EXCLUIR ALUNO COM CONFIRMAÇÃO ────────────────────────────────────
  Future<void> _confirmarExclusao(Aluno aluno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Excluir Aluno',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Deseja realmente excluir "${aluno.nome}"?\nEsta ação não pode ser desfeita.',
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
        await AlunoService.excluirAluno(aluno.id);
        _mostrarSnack('Aluno "${aluno.nome}" excluído.', isErro: false);
        _carregarAlunos();
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
                        // ── Formulário de Cadastro ──────────────────
                        _buildFormulario(),
                        const SizedBox(height: 40),

                        // ── Tabela de Alunos ────────────────────────
                        _buildTabelaAlunos(),
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

  // ─── CARD DO FORMULÁRIO ─────────────────────────────────────────────────
  Widget _buildFormulario() {
    return Container(
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
          const Icon(Icons.person_add_alt_1_rounded, size: 48, color: _vermelho),
          const SizedBox(height: 16),
          Text(
            'Cadastrar Aluno',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha os dados abaixo para criar um novo acesso.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),

          _buildCampo(controller: _nomeCtrl, hint: 'Nome Completo', icon: Icons.badge_outlined),
          const SizedBox(height: 16),
          _buildCampo(controller: _emailCtrl, hint: 'E-mail do aluno', icon: Icons.email_outlined),
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
                    'O aluno (ou responsável) autoriza a coleta e o armazenamento de dados de desempenho no jogo para fins pedagógicos, conforme a LGPD.',
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botão Cadastrar
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

  // ─── TABELA DE ALUNOS ───────────────────────────────────────────────────
  Widget _buildTabelaAlunos() {
    return Container(
      padding: const EdgeInsets.all(28),
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
          // Cabeçalho da tabela
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alunos Cadastrados',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_alunos.length} aluno${_alunos.length != 1 ? 's' : ''} no sistema',
                    style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Atualizar lista',
                icon: const Icon(Icons.refresh_rounded, color: _vermelho),
                onPressed: _carregandoAlunos ? null : _carregarAlunos,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estado de carregamento / erro / vazio
          if (_carregandoAlunos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _vermelho),
              ),
            )
          else if (_erroAlunos != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Não foi possível carregar os alunos.',
                      style: GoogleFonts.nunito(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _carregarAlunos,
                      icon: const Icon(Icons.refresh, color: _vermelho),
                      label: Text('Tentar novamente',
                          style: GoogleFonts.nunito(color: _vermelho, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            )
          else if (_alunos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum aluno cadastrado ainda.',
                      style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            // Tabela
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FixedColumnWidth(56),
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: const BoxDecoration(color: _vermelho),
                    children: [
                      _headerCell('Nome'),
                      _headerCell('E-mail'),
                      _headerCell('Cadastro'),
                      _headerCell(''),
                    ],
                  ),
                  // Data rows
                  ..._alunos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final aluno = entry.value;
                    final isEven = i % 2 == 0;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? _cinzaFundo : Colors.white,
                      ),
                      children: [
                        _dataCell(aluno.nome),
                        _dataCell(aluno.email),
                        _dataCell(aluno.dataCadastro),
                        // Botão excluir
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Center(
                            child: IconButton(
                              tooltip: 'Excluir aluno',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: Colors.red[400],
                              onPressed: () => _confirmarExclusao(aluno),
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
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

  TableCell _dataCell(String text) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            text,
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  // ─── CAMPO DE TEXTO ─────────────────────────────────────────────────────
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
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _vermelho, width: 1.5)),
      ),
    );
  }

  // ─── LÓGICA DE CADASTRO ─────────────────────────────────────────────────
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
      final msg = await AlunoService.cadastrarAluno(
        nome: nome,
        email: email,
        senha: senha,
        aceiteLgpd: _aceiteLgpd,
      );
      _mostrarSnack(msg, isErro: false);
      _nomeCtrl.clear();
      _emailCtrl.clear();
      _senhaCtrl.clear();
      _confirmaSenhaCtrl.clear();
      setState(() => _aceiteLgpd = false);
      _carregarAlunos(); // Atualiza a tabela
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