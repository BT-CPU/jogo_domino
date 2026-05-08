import 'package:flutter/material.dart';
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

class RelatoriosProfessorPage extends StatefulWidget {
  final String nomeProfessor;
  const RelatoriosProfessorPage({super.key, this.nomeProfessor = 'Professor'});

  @override
  State<RelatoriosProfessorPage> createState() => _RelatoriosProfessorPageState();
}

class _RelatoriosProfessorPageState extends State<RelatoriosProfessorPage> {
  static const Color _azulPrincipal = Color(0xFF003F8A);
  static const Color _azulClaro     = Color(0xFF1565C0);
  static const Color _laranja       = Color(0xFFFF6B00);
  static const Color _cinzaFundo    = Color(0xFFF4F6FA);
  static const Color _branco        = Colors.white;
  static const Color _verde         = Color(0xFF2E7D32);
  static const Color _vermelho      = Color(0xFFC62828);

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
    await Future.delayed(const Duration(milliseconds: 700));
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
        backgroundColor: _azulPrincipal,
        foregroundColor: _branco,
        elevation: 0,
        title: const Text(
          'Relatórios dos Alunos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5),
        ),
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
          CircularProgressIndicator(color: _azulPrincipal),
          SizedBox(height: 16),
          Text('Carregando dados dos alunos...', style: TextStyle(color: _azulPrincipal)),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    return RefreshIndicator(
      color: _azulPrincipal,
      onRefresh: _carregarDados,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCabecalhoProfessor(),
          const SizedBox(height: 20),
          _buildTituloSecao('Resumo Geral'),
          const SizedBox(height: 12),
          _buildCardsResumo(),
          const SizedBox(height: 24),
          _buildTituloSecao('Lista de Alunos'),
          const SizedBox(height: 12),
          _buildBarraFiltros(),
          const SizedBox(height: 12),
          _buildTabelaAlunos(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCabecalhoProfessor() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_azulPrincipal, _azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _azulPrincipal.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _laranja,
            child: Text(
              widget.nomeProfessor.isNotEmpty ? widget.nomeProfessor[0].toUpperCase() : 'P',
              style: const TextStyle(color: _branco, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prof. ${widget.nomeProfessor}',
                  style: const TextStyle(color: _branco, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_todos.length} aluno${_todos.length != 1 ? 's' : ''} cadastrado${_todos.length != 1 ? 's' : ''}',
                  style: TextStyle(color: _branco.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _laranja, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.school_rounded, color: _branco, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsResumo() {
    final comPartidas = _todos.where((a) => a.totalPartidas > 0).toList();
    final mediaGeral = comPartidas.isEmpty
        ? 0.0
        : comPartidas.map((a) => a.taxaAcertoMedia).reduce((x, y) => x + y) / comPartidas.length;
    final semJogar = _todos.where((a) => a.totalPartidas == 0).length;
    final totalPartidas = _todos.fold(0, (sum, a) => sum + a.totalPartidas);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildCardResumo(icone: Icons.people_rounded,          valor: '${_todos.length}',                  label: 'Total de Alunos',  cor: _azulPrincipal),
        _buildCardResumo(icone: Icons.trending_up_rounded,     valor: '${mediaGeral.toStringAsFixed(0)}%', label: 'Média de Acerto',  cor: _verde),
        _buildCardResumo(icone: Icons.sports_esports_rounded,  valor: '$totalPartidas',                    label: 'Total Partidas',   cor: _laranja),
        _buildCardResumo(icone: Icons.hourglass_empty_rounded, valor: '$semJogar',                         label: 'Sem Partidas',     cor: _vermelho),
      ],
    );
  }

  Widget _buildCardResumo({
    required IconData icone,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: cor, size: 26),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(color: cor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _buildTituloSecao(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _azulPrincipal, letterSpacing: 0.3),
    );
  }

  Widget _buildBarraFiltros() {
    return Column(
      children: [
        TextField(
          controller: _buscaCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar aluno pelo nome...',
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45),
            suffixIcon: _busca.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _buscaCtrl.clear();
                      setState(() { _busca = ''; _aplicarFiltros(); });
                    },
                  )
                : null,
            filled: true,
            fillColor: _branco,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() { _busca = v; _aplicarFiltros(); }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildDropdown(
              value: _turmaSel,
              items: _turmas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() { _turmaSel = v!; _aplicarFiltros(); }),
            )),
            const SizedBox(width: 10),
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

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _branco, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTabelaAlunos() {
    if (_filtrados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: _branco, borderRadius: BorderRadius.circular(14)),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text('Nenhum aluno encontrado.', style: TextStyle(color: Colors.black45, fontSize: 14)),
          ],
        ),
      );
    }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _azulPrincipal.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('Aluno / Turma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          _buildHeaderCol('Acerto'),
          _buildHeaderCol('Partidas'),
          _buildHeaderCol('Melhor\nTempo'),
          _buildHeaderCol('Última\nJogada'),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String label) {
    return Expanded(
      flex: 2,
      child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildLinhaAluno(AlunoResumo aluno) {
    final cor = aluno.taxaAcertoMedia >= 70
        ? _verde
        : aluno.taxaAcertoMedia >= 50
            ? _laranja
            : aluno.totalPartidas == 0
                ? Colors.black38
                : _vermelho;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RelatoriosAlunoPage(nomeAluno: aluno.nome)),
      ),
      borderRadius: BorderRadius.circular(14),
      hoverColor: _azulPrincipal.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cor.withOpacity(0.12),
                    child: Text(aluno.nome[0].toUpperCase(),
                        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        Text(aluno.turma, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    aluno.totalPartidas == 0 ? '--' : '${aluno.taxaAcertoMedia.toStringAsFixed(0)}%',
                    style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
            Expanded(flex: 2, child: Center(child: Text('${aluno.totalPartidas}', style: const TextStyle(fontSize: 13)))),
            Expanded(flex: 2, child: Center(child: Text(aluno.melhorTempoFormatado, style: const TextStyle(fontSize: 13)))),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(aluno.ultimaPartidaStr, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: aluno.ultimaPartida == null ? Colors.black38 : Colors.black54)),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}