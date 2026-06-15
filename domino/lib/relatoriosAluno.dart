import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'relatorio_models.dart';
import 'relatorio_service.dart';

class RelatoriosAlunoScreen extends StatefulWidget {
  const RelatoriosAlunoScreen({
    super.key,
    required this.idUsuario,
    this.nomeAluno,
    this.turmaAluno,
  });

  final int idUsuario;
  final String? nomeAluno;
  final String? turmaAluno;

  @override
  State<RelatoriosAlunoScreen> createState() => _RelatoriosAlunoScreenState();
}

class _RelatoriosAlunoScreenState extends State<RelatoriosAlunoScreen> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  final RelatorioService _service = const RelatorioService();

  RelatorioAluno? _relatorio;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final relatorio = await _service.obterRelatorioAluno(widget.idUsuario);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: AppBar(
        title: Text(
          'Relatorio do Aluno',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: _vermelho,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
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
            const Icon(Icons.error_outline, color: _vermelho, size: 44),
            const SizedBox(height: 12),
            Text(
              _erro ?? 'Nao foi possivel carregar o relatorio.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _carregarRelatorio,
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
    final relatorio = _relatorio!;
    final isWide = MediaQuery.of(context).size.width > 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPerfilAlunoCard(relatorio),
              const SizedBox(height: 24),
              _buildCardsResumo(relatorio, isWide),
              const SizedBox(height: 24),
              Text(
                'Historico de Partidas',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildTabelaPartidasCard(relatorio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilAlunoCard(RelatorioAluno relatorio) {
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
            child: const Icon(
              Icons.account_circle_outlined,
              size: 50,
              color: _vermelho,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relatorio.nome,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  relatorio.turma,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: const Color(0xFF757575),
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

  Widget _buildCardsResumo(RelatorioAluno relatorio, bool isWide) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isWide ? 1.5 : 1.2,
      children: [
        _buildStatCard(
          Icons.check_circle_rounded,
          'Acerto',
          relatorio.totalPartidas == 0
              ? '--'
              : '${relatorio.taxaAcertoMedia.toStringAsFixed(0)}%',
          Colors.green,
        ),
        _buildStatCard(
          Icons.sports_esports_rounded,
          'Partidas',
          '${relatorio.totalPartidas}',
          Colors.blue,
        ),
        _buildStatCard(
          Icons.timer_rounded,
          'Melhor Tempo',
          relatorio.melhorTempoFormatado,
          Colors.amber[700]!,
        ),
        _buildStatCard(
          Icons.history_toggle_off_rounded,
          'Ultima Jogada',
          relatorio.ultimaJogadaLabel,
          _vermelho,
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color cor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.28), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: cor),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaPartidasCard(RelatorioAluno relatorio) {
    if (relatorio.historico.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        child: Center(
          child: Text(
            'Este aluno ainda nao possui partidas registradas.',
            style: GoogleFonts.nunito(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0x08C0392B)),
            dataRowMaxHeight: 60,
            dataRowMinHeight: 60,
            horizontalMargin: 20,
            columnSpacing: 24,
            columns: [
              _buildDataColumn('Nivel'),
              _buildDataColumn('Data'),
              _buildDataColumn('Acertos', isNumeric: true),
              _buildDataColumn('Erros', isNumeric: true),
              _buildDataColumn('Tempo'),
            ],
            rows: relatorio.historico.map((partida) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      partida.nivelLabel,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      partida.dataFormatada,
                      style: GoogleFonts.nunito(color: Colors.grey[700]),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        '${partida.qtdAcertos}',
                        style: GoogleFonts.nunito(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        '${partida.qtdErros}',
                        style: GoogleFonts.nunito(
                          color: _vermelho,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      partida.tempoFormatado,
                      style: GoogleFonts.nunito(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, {bool isNumeric = false}) {
    return DataColumn(
      numeric: isNumeric,
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _vermelho,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
