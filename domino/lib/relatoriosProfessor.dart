import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'relatorio_models.dart';
import 'relatorio_service.dart';
import 'relatoriosAluno.dart';

class RelatoriosProfessorScreen extends StatefulWidget {
  const RelatoriosProfessorScreen({
    super.key,
    required this.idProfessor,
    this.nomeProfessor = 'Professor',
  });

  final int idProfessor;
  final String nomeProfessor;

  @override
  State<RelatoriosProfessorScreen> createState() =>
      _RelatoriosProfessorScreenState();
}

class _RelatoriosProfessorScreenState extends State<RelatoriosProfessorScreen> {
  static const Color _vermelho = Color(0xFFC0392B);
  static const Color _cinzaFundo = Color(0xFFF0F0F0);
  static const Color _branco = Colors.white;
  static const Color _verde = Color(0xFF27AE60);
  static const Color _laranja = Color(0xFFF39C12);

  final RelatorioService _service = const RelatorioService();
  final TextEditingController _buscaCtrl = TextEditingController();

  RelatorioProfessor? _relatorio;
  bool _carregando = true;
  String? _erro;
  String _turmaSel = 'Todas';
  String _busca = '';
  String _ordenarPor = 'nome';

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
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final relatorio = await _service.obterRelatorioProfessor(
        widget.idProfessor,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _relatorio = relatorio;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _carregando = false;
      });
    }
  }

  List<RelatorioAluno> get _alunosFiltrados {
    final alunos = _relatorio?.alunos ?? const <RelatorioAluno>[];
    final filtrados = alunos.where((aluno) {
      final matchTurma = _turmaSel == 'Todas' || aluno.turma == _turmaSel;
      final matchBusca =
          _busca.isEmpty ||
          aluno.nome.toLowerCase().contains(_busca.toLowerCase());
      return matchTurma && matchBusca;
    }).toList();

    filtrados.sort((a, b) {
      switch (_ordenarPor) {
        case 'taxa':
          return b.taxaAcertoMedia.compareTo(a.taxaAcertoMedia);
        case 'partidas':
          return b.totalPartidas.compareTo(a.totalPartidas);
        default:
          return a.nome.compareTo(b.nome);
      }
    });

    return filtrados;
  }

  List<String> get _turmasDisponiveis {
    final turmas = {
      for (final aluno in _relatorio?.alunos ?? const <RelatorioAluno>[])
        aluno.turma,
    }.toList()..sort();
    return ['Todas', ...turmas];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: AppBar(
        backgroundColor: _vermelho,
        foregroundColor: _branco,
        elevation: 0,
        title: Text(
          'Visao da Turma',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? _buildLoading()
          : _erro != null
          ? _buildErro()
          : _buildConteudo(),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: _vermelho));
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _vermelho, size: 48),
            const SizedBox(height: 12),
            Text(
              _erro ?? 'Nao foi possivel carregar os relatorios.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _carregarDados,
              icon: const Icon(Icons.refresh_rounded, color: _vermelho),
              label: Text(
                'Tentar novamente',
                style: GoogleFonts.nunito(
                  color: _vermelho,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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
          Text(
            'Lista de Alunos',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildBarraFiltros(),
          const SizedBox(height: 16),
          _buildTabelaAlunos(),
        ],
      ),
    );
  }

  Widget _buildCabecalhoProfessor() {
    final relatorio = _relatorio!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0x15C0392B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, size: 40, color: _vermelho),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prof. ${relatorio.nomeProfessor}',
                  style: GoogleFonts.nunito(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${relatorio.alunos.length} aluno${relatorio.alunos.length == 1 ? '' : 's'} carregado${relatorio.alunos.length == 1 ? '' : 's'}',
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsResumo() {
    final relatorio = _relatorio!;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildCardResumo(
          Icons.trending_up_rounded,
          '${relatorio.mediaAcertoTurma.toStringAsFixed(0)}%',
          'Media da Turma',
          _verde,
        ),
        _buildCardResumo(
          Icons.sports_esports_rounded,
          '${relatorio.totalPartidasTurma}',
          'Partidas Jogadas',
          _laranja,
        ),
      ],
    );
  }

  Widget _buildCardResumo(
    IconData icone,
    String valor,
    String label,
    Color cor,
  ) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 12),
          Text(
            valor,
            style: GoogleFonts.nunito(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            hintStyle: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45),
            filled: true,
            fillColor: _branco,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _busca = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _turmaSel,
                items: _turmasDisponiveis
                    .map(
                      (turma) =>
                          DropdownMenuItem(value: turma, child: Text(turma)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _turmaSel = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _ordenarPor,
                items: const [
                  DropdownMenuItem(value: 'nome', child: Text('A -> Z')),
                  DropdownMenuItem(value: 'taxa', child: Text('Maior acerto')),
                  DropdownMenuItem(
                    value: 'partidas',
                    child: Text('Mais partidas'),
                  ),
                ],
                onChanged: (value) => setState(() => _ordenarPor = value!),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTabelaAlunos() {
    final alunos = _alunosFiltrados;
    if (alunos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _branco,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum aluno encontrado.',
              style: GoogleFonts.nunito(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderTabela(),
          const Divider(height: 1),
          ...alunos.asMap().entries.map((entry) {
            final isUltimo = entry.key == alunos.length - 1;
            return Column(
              children: [
                _buildLinhaAluno(entry.value),
                if (!isUltimo)
                  const Divider(height: 1, indent: 16, endIndent: 16),
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
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ALUNO / TURMA',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildHeaderCol('ACERTO'),
          _buildHeaderCol('PARTIDAS'),
          _buildHeaderCol('MELHOR TEMPO'),
          _buildHeaderCol('ULTIMA JOGADA'),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String label) {
    return Expanded(
      flex: 2,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildLinhaAluno(RelatorioAluno aluno) {
    final cor = aluno.totalPartidas == 0
        ? Colors.grey[400]!
        : aluno.taxaAcertoMedia >= 70
        ? _verde
        : aluno.taxaAcertoMedia >= 50
        ? _laranja
        : _vermelho;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RelatoriosAlunoScreen(idUsuario: aluno.idUsuario),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      hoverColor: _vermelho.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cor.withValues(alpha: 0.12),
                    child: Text(
                      aluno.nome[0].toUpperCase(),
                      style: GoogleFonts.nunito(
                        color: cor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aluno.nome,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          aluno.turma,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    aluno.totalPartidas == 0
                        ? '--'
                        : '${aluno.taxaAcertoMedia.toStringAsFixed(0)}%',
                    style: GoogleFonts.nunito(
                      color: cor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '${aluno.totalPartidas}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  aluno.melhorTempoFormatado,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  aluno.ultimaJogadaLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: aluno.ultimaJogada == null
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
