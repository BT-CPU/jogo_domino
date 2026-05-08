import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TelaDesempenho extends StatefulWidget {
  const TelaDesempenho({super.key});

  @override
  State<TelaDesempenho> createState() => _TelaDesempenhoState();
}

class _TelaDesempenhoState extends State<TelaDesempenho> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF9F9F9);
  
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── CABEÇALHO (BOTÃO VOLTAR E TÍTULO) ──────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 24, right: 16, bottom: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: _vermelho, size: 32), // Ícone Vermelho
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Voltar para o Menu',
                  ),
                ),
                Text(
                  'Meu Desempenho',
                  style: GoogleFonts.nunito(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: _vermelho // Título Vermelho
                  ),
                ),
              ],
            ),
          ),
          
          // ─── CONTEÚDO ORIGINAL ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // Quadrados de resumo geral (Bem coloridos)
                      _buildEstatisticasGerais(isWide),
                      const SizedBox(height: 32),
                      // Sua lista original de Últimas Partidas
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
        _buildStatCard(Icons.sports_esports_rounded, 'Partidas', '47', Colors.blue),
        _buildStatCard(Icons.emoji_events_rounded, 'Pontos', '1.240', Colors.amber[600]!),
        _buildStatCard(Icons.check_circle_rounded, 'Acertos', '82%', Colors.green),
        _buildStatCard(Icons.timer_rounded, 'Tempo Médio', '01:45', _vermelho),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color cor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withOpacity(0.3), width: 2), // Borda da cor do card
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.1), // Sombra da cor do card
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
            style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Mantive a sua estrutura original para essa lista, apenas adicionei destaques!
  Widget _buildUltimasPartidas() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _vermelho.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: _vermelho.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
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
                'Últimas Partidas',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: _vermelho),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLinhaPartida('Nível 1', '26/05/2026', '260 pts', Colors.green),
          const Divider(height: 24, thickness: 1),
          _buildLinhaPartida('Nível 1', '24/05/2026', '180 pts', Colors.amber[600]!),
          const Divider(height: 24, thickness: 1),
          _buildLinhaPartida('Nível 2', '23/05/2026', '210 pts', _vermelho),
        ],
      ),
    );
  }

  Widget _buildLinhaPartida(String nivel, String data, String pontos, Color corNivel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Caixinha colorida de destaque para o Nível
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: corNivel.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                nivel,
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: corNivel),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              data,
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ],
        ),
        Text(
          pontos,
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
        ),
      ],
    );
  }
}