import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Importando o arquivo do aluno exatamente com o nome que está na sua pasta
import 'relatoriosAluno.dart'; 

class AlunoResumo {
  final int idUsuario;
  final String nome;
  final String turma;
  final int totalPartidas;
  final double taxaAcertoMedia;
  final int melhorTempoSegundos;
  final DateTime? ultimaPartida;

  const AlunoResumo({
    required this.idUsuario,
    required this.nome,
    required this.turma,
    required this.totalPartidas,
    required this.taxaAcertoMedia,
    required this.melhorTempoSegundos,
    this.ultimaPartida,
  });

  String get melhorTempoFormatado {
    if (totalPartidas == 0) return '--:--';
    final m = melhorTempoSegundos ~/ 60;
    final s = melhorTempoSegundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get ultimaPartidaStr {
    if (ultimaPartida == null) return 'Nunca jogou';
    final diff = DateTime.now().difference(ultimaPartida!);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    return 'Há ${diff.inDays} dias';
  }
}

List<AlunoResumo> _mockAlunos() {
  final now = DateTime.now();
  return [
    AlunoResumo(idUsuario: 1, nome: 'Ana Beatriz Silva',     turma: '1º Ano A', totalPartidas: 8,  taxaAcertoMedia: 87.5, melhorTempoSegundos: 72,  ultimaPartida: now.subtract(const Duration(hours: 3))),
    AlunoResumo(idUsuario: 2, nome: 'Bruno Henrique Costa',  turma: '1º Ano A', totalPartidas: 5,  taxaAcertoMedia: 64.0, melhorTempoSegundos: 105, ultimaPartida: now.subtract(const Duration(days: 1))),
    AlunoResumo(idUsuario: 3, nome: 'Carla Mendes Oliveira', turma: '1º Ano B', totalPartidas: 12, taxaAcertoMedia: 92.3, melhorTempoSegundos: 58,  ultimaPartida: now.subtract(const Duration(hours: 1))),
    AlunoResumo(idUsuario: 4, nome: 'Diego Ferreira Souza',  turma: '1º Ano B', totalPartidas: 3,  taxaAcertoMedia: 50.0, melhorTempoSegundos: 140, ultimaPartida: now.subtract(const Duration(days: 4))),
    AlunoResumo(idUsuario: 5, nome: 'Eduarda Lima Martins',  turma: '2º Ano A', totalPartidas: 0,  taxaAcertoMedia: 0,    melhorTempoSegundos: 0,   ultimaPartida: null),
    AlunoResumo(idUsuario: 6, nome: 'Felipe Rodrigues Neto', turma: '2º Ano A', totalPartidas: 7,  taxaAcertoMedia: 75.0, melhorTempoSegundos: 88,  ultimaPartida: now.subtract(const Duration(days: 2))),
    AlunoResumo(idUsuario: 7, nome: 'Gabriela Santos Cruz',  turma: '2º Ano B', totalPartidas: 10, taxaAcertoMedia: 80.0, melhorTempoSegundos: 65,  ultimaPartida: now.subtract(const Duration(days: 1))),
    AlunoResumo(idUsuario: 8, nome: 'Hugo Alves Pereira',    turma: '2º Ano B', totalPartidas: 2,  taxaAcertoMedia: 45.0, melhorTempoSegundos: 180, ultimaPartida: now.subtract(const Duration(days: 6))),
  ];
}

class RelatoriosProfessorScreen extends StatefulWidget {
  final String nomeProfessor;
  const RelatoriosProfessorScreen({super.key, this.nomeProfessor = 'Professor'});

  @override
  State<RelatoriosProfessorScreen> createState() => _RelatoriosProfessorScreenState();
}

class _RelatoriosProfessorScreenState extends State<RelatoriosProfessorScreen> {
  static const Color _vermelho      = Color(0xFFC0392B);
  static const Color _cinzaFundo    = Color(0xFFF0F0F0);
  static const Color _branco        = Colors.white;
  static const Color _verde         = Color(0xFF27AE60);
  static const Color _laranja       = Color(0xFFF39C12);

  List<AlunoResumo> _todos     = [];
  List<AlunoResumo> _filtrados = [];
  List<String>      _turmas    = [];
  String  _turmaSel   = 'Todas';
  String  _busca      = '';
  bool    _carregando = true;
  String  _ordenarPor = 'nome';

  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lista = _mockAlunos();
    final turmas = ['Todas', ...{...lista.map((a) => a.turma)}];
    setState(() {
      _todos      = lista;
      _turmas     = turmas;
      _carregando = false;
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    var lista = _todos.where((a) {
      final matchTurma = _turmaSel == 'Todas' || a.turma == _turmaSel;
      final matchBusca = _busca.isEmpty || a.nome.toLowerCase().contains(_busca.toLowerCase());
      return matchTurma && matchBusca;
    }).toList();

    lista.sort((a, b) {
      switch (_ordenarPor) {
        case 'taxa':     return b.taxaAcertoMedia.compareTo(a.taxaAcertoMedia);
        case 'partidas': return b.totalPartidas.compareTo(a.totalPartidas);
        default:         return a.nome.compareTo(b.nome);
      }
    });
    _filtrados = lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: AppBar(
        backgroundColor: _vermelho,
        foregroundColor: _branco,
        elevation: 0,
        title: Text('Visão da Turma', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _carregando = true);
              _carregarDados();
            },
          ),
        ],
      ),
      body: _carregando ? _buildLoading() : _buildConteudo(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _vermelho),
          SizedBox(height: 16),
          Text('Carregando dados dos alunos...', style: TextStyle(color: _vermelho)),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    return RefreshIndicator(
      color: _vermelho,
      onRefresh: _carregarDados,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildCabecalhoProfessor(),
          const SizedBox(height: 24),
          _buildCardsResumo(),
          const SizedBox(height: 32),
          Text('Lista de Alunos', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 12),
          _buildBarraFiltros(),
          const SizedBox(height: 16),
          _buildTabelaAlunos(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCabecalhoProfessor() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0x15C0392B), shape: BoxShape.circle),
            child: const Icon(Icons.school_rounded, size: 40, color: _vermelho),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prof. ${widget.nomeProfessor}', style: GoogleFonts.nunito(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_todos.length} aluno${_todos.length != 1 ? 's' : ''} cadastrado${_todos.length != 1 ? 's' : ''}', style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsResumo() {
    final comPartidas = _todos.where((a) => a.totalPartidas > 0).toList();
    final mediaGeral = comPartidas.isEmpty ? 0.0 : comPartidas.map((a) => a.taxaAcertoMedia).reduce((x, y) => x + y) / comPartidas.length;
    final totalPartidas = _todos.fold(0, (sum, a) => sum + a.totalPartidas);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildCardResumo(Icons.trending_up_rounded, '${mediaGeral.toStringAsFixed(0)}%', 'Média da Turma', _verde),
        _buildCardResumo(Icons.sports_esports_rounded, '$totalPartidas', 'Partidas Jogadas', _laranja),
      ],
    );
  }

  Widget _buildCardResumo(IconData icone, String valor, String label, Color cor) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 12),
          Text(valor, style: GoogleFonts.nunito(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBarraFiltros() {
    return Column(
      children: [
        TextField(
          controller: _buscaCtrl,
          style: GoogleFonts.nunito(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar aluno pelo nome...',
            hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45),
            filled: true,
            fillColor: _branco,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() { _busca = v; _aplicarFiltros(); }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown(
              value: _turmaSel,
              items: _turmas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() { _turmaSel = v!; _aplicarFiltros(); }),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown(
              value: _ordenarPor,
              items: const [
                DropdownMenuItem(value: 'nome',     child: Text('A → Z')),
                DropdownMenuItem(value: 'taxa',     child: Text('Maior acerto')),
                DropdownMenuItem(value: 'partidas', child: Text('Mais partidas')),
              ],
              onChanged: (v) => setState(() { _ordenarPor = v!; _aplicarFiltros(); }),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: _branco, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTabelaAlunos() {
    return Container(
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildHeaderTabela(),
          const Divider(height: 1),
          ..._filtrados.asMap().entries.map((entry) {
            final isUltimo = entry.key == _filtrados.length - 1;
            return Column(
              children: [
                _buildLinhaAluno(entry.value),
                if (!isUltimo) const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderTabela() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('ALUNO / TURMA', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[600]))),
          _buildHeaderCol('ACERTO'),
          _buildHeaderCol('PARTIDAS'),
          _buildHeaderCol('MELHOR TEMPO'),
          _buildHeaderCol('ÚLTIMA JOGADA'),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String label) {
    return Expanded(flex: 2, child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[600])));
  }

  Widget _buildLinhaAluno(AlunoResumo aluno) {
    final cor = aluno.taxaAcertoMedia >= 70 ? _verde : aluno.taxaAcertoMedia >= 50 ? _laranja : aluno.totalPartidas == 0 ? Colors.grey[400]! : _vermelho;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        // Conexão exata com a classe que criamos no arquivo relatoriosAluno.dart
        MaterialPageRoute(builder: (_) => RelatoriosAlunoScreen(nomeAluno: aluno.nome, turmaAluno: aluno.turma)),
      ),
      borderRadius: BorderRadius.circular(14),
      hoverColor: _vermelho.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: cor.withOpacity(0.12), child: Text(aluno.nome[0].toUpperCase(), style: GoogleFonts.nunito(color: cor, fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(aluno.nome, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                        Text(aluno.turma, style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(aluno.totalPartidas == 0 ? '--' : '${aluno.taxaAcertoMedia.toStringAsFixed(0)}%', style: GoogleFonts.nunito(color: cor, fontWeight: FontWeight.w800, fontSize: 13))))),
            Expanded(flex: 2, child: Center(child: Text('${aluno.totalPartidas}', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)))),
            Expanded(flex: 2, child: Center(child: Text(aluno.melhorTempoFormatado, style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600])))),
            Expanded(flex: 2, child: Center(child: Text(aluno.ultimaPartidaStr, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 12, color: aluno.ultimaPartida == null ? Colors.grey[400] : Colors.grey[600])))),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 24),
          ],
        ),
      ),
    );
  }
}