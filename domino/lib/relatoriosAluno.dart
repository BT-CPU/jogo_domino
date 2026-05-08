import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PartidaReporte {
  final int nivel;
  final String data;
  final int acertos;
  final int erros;
  final String tempo;

  PartidaReporte({
    required this.nivel,
    required this.data,
    required this.acertos,
    required this.erros,
    required this.tempo,
  });
}

class RelatoriosAlunoScreen extends StatelessWidget {
  final String nomeAluno;
  final String turmaAluno;

  const RelatoriosAlunoScreen({
    super.key, 
    this.nomeAluno = 'Aluno', 
    this.turmaAluno = 'Turma não informada'
  });

  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);
  static const _preto87 = Colors.black87;
  static const _cinzaTexto = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    final List<PartidaReporte> historicoPartidas = [
      PartidaReporte(nivel: 1, data: "05/05/2026", acertos: 10, erros: 2, tempo: "02:15"),
      PartidaReporte(nivel: 1, data: "03/05/2026", acertos: 12, erros: 0, tempo: "01:58"),
      PartidaReporte(nivel: 2, data: "01/05/2026", acertos: 8, erros: 4, tempo: "03:10"),
      PartidaReporte(nivel: 1, data: "28/04/2026", acertos: 11, erros: 1, tempo: "02:05"),
    ];

    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: AppBar(
        title: Text(
          'Relatório do Aluno',
          style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _vermelho,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPerfilAlunoCard(),
                const SizedBox(height: 24),
                Text(
                  'Histórico de Partidas',
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: _preto87),
                ),
                const SizedBox(height: 12),
                _buildTabelaPartidasCard(historicoPartidas),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilAlunoCard() {
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
            child: const Icon(Icons.account_circle_outlined, size: 50, color: _vermelho),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomeAluno, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: _preto87)),
                Text(turmaAluno, style: GoogleFonts.nunito(fontSize: 14, color: _cinzaTexto, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelaPartidasCard(List<PartidaReporte> partidas) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0x08C0392B)), 
            dataRowMaxHeight: 60,
            dataRowMinHeight: 60,
            horizontalMargin: 20,
            columnSpacing: 24,
            columns: [
              _buildDataColumn('Nível'),
              _buildDataColumn('Data'),
              _buildDataColumn('Acertos', isNumeric: true),
              _buildDataColumn('Erros', isNumeric: true),
              _buildDataColumn('Tempo'),
            ],
            rows: partidas.map((partida) {
              return DataRow(cells: [
                DataCell(Text('Lvl ${partida.nivel}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: _preto87))),
                DataCell(Text(partida.data, style: GoogleFonts.nunito(color: _cinzaTexto))),
                DataCell(Center(child: Text('${partida.acertos}', style: GoogleFonts.nunito(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)))),
                DataCell(Center(child: Text('${partida.erros}', style: GoogleFonts.nunito(color: _vermelho, fontWeight: FontWeight.bold, fontSize: 16)))),
                DataCell(Text(partida.tempo, style: GoogleFonts.nunito(color: _cinzaTexto, fontWeight: FontWeight.w600))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, {bool isNumeric = false}) {
    return DataColumn(
      numeric: isNumeric,
      label: Text(label.toUpperCase(), style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: _vermelho, letterSpacing: 1.2)),
    );
  }
}