import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PartidaResumoAluno {
  const PartidaResumoAluno({
    required this.nivel,
    required this.data,
    required this.tempo,
    required this.acertos,
    required this.erros,
    required this.corNivel,
  });

  final String nivel;
  final String data;
  final String tempo;
  final int acertos;
  final int erros;
  final Color corNivel;
}

class TelaDesempenho extends StatefulWidget {
  const TelaDesempenho({super.key});

  @override
  State<TelaDesempenho> createState() => _TelaDesempenhoState();
}

class _TelaDesempenhoState extends State<TelaDesempenho> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF9F9F9);

  final List<PartidaResumoAluno> _ultimasPartidas = const [
    PartidaResumoAluno(
      nivel: 'Nivel 1',
      data: '26/05/2026',
      tempo: '01:12',
      acertos: 11,
      erros: 1,
      corNivel: Colors.green,
    ),
    PartidaResumoAluno(
      nivel: 'Nivel 1',
      data: '24/05/2026',
      tempo: '01:45',
      acertos: 9,
      erros: 2,
      corNivel: Colors.amber,
    ),
    PartidaResumoAluno(
      nivel: 'Nivel 2',
      data: '23/05/2026',
      tempo: '02:10',
      acertos: 8,
      erros: 3,
      corNivel: _vermelho,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 24,
              right: 16,
              bottom: 8,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: _vermelho,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Voltar para o Menu',
                  ),
                ),
                Text(
                  'Meu Desempenho',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _vermelho,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      _buildEstatisticasGerais(isWide),
                      const SizedBox(height: 32),
                      _buildUltimasPartidas(),
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

  Widget _buildEstatisticasGerais(bool isWide) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isWide ? 1.5 : 1.2,
      children: [
        _buildStatCard(
          Icons.sports_esports_rounded,
          'Partidas',
          '47',
          Colors.blue,
        ),
        _buildStatCard(
          Icons.timer_rounded,
          'Melhor Tempo',
          '01:12',
          Colors.amber[600]!,
        ),
        _buildStatCard(
          Icons.check_circle_rounded,
          'Acertos',
          '82%',
          Colors.green,
        ),
        _buildStatCard(
          Icons.history_toggle_off_rounded,
          'Ultima Jogada',
          'Hoje',
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
        border: Border.all(color: cor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: cor),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimasPartidas() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _vermelho.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: _vermelho.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: _vermelho, size: 28),
              const SizedBox(width: 8),
              Text(
                'Ultimas Partidas',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _vermelho,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < _ultimasPartidas.length; i++) ...[
            _buildLinhaPartida(_ultimasPartidas[i]),
            if (i != _ultimasPartidas.length - 1)
              const Divider(height: 24, thickness: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildLinhaPartida(PartidaResumoAluno partida) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: partida.corNivel.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                partida.nivel,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: partida.corNivel,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partida.data,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${partida.acertos} acertos • ${partida.erros} erros',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          partida.tempo,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
