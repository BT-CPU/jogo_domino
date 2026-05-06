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
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 32),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Voltar para o Menu',
                  ),
                ),
                Text(
                  'Meu Desempenho',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // ─── CONTEÚDO SCROLLÁVEL ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      // ABAS (Tabs)
                      const SizedBox(height: 20),

                      // CARDS DE ESTATÍSTICAS
                      _buildCardsEstatisticas(isWide),
                      const SizedBox(height: 32),

                      // ÁREA INFERIOR (GRÁFICO E LISTA)
                      if (isWide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 2, child: _buildGrafico()),
                              const SizedBox(width: 32),
                              Expanded(flex: 1, child: _buildUltimasPartidas()),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            _buildGrafico(),
                            const SizedBox(height: 32),
                            _buildUltimasPartidas(),
                          ],
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

  Widget _buildCardsEstatisticas(bool isWide) {
    final cards = [
      _buildCard('Partidas Jogadas', '12'),
      _buildCard('Taxa de Acerto', '85%'),
      _buildCard('Pontuação Média', '210'),
      _buildCard('Tempo Médio', '04:15'),
    ];

    if (isWide) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
      );
    } else {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: cards.map((c) => SizedBox(width: 160, child: c)).toList(),
      );
    }
  }

  Widget _buildCard(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: GoogleFonts.nunito(fontSize: 36, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Gráfico construído de forma nativa com Flutter
  Widget _buildGrafico() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Desempenho por Nível',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Row(
                children: [
                  Container(width: 12, height: 12, color: _vermelho),
                  const SizedBox(width: 8),
                  Text('Taxa de Acerto (%)', style: GoogleFonts.nunito(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200, // Altura fixa para o gráfico
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Eixo Y
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('100', style: GoogleFonts.nunito(color: Colors.black54, fontSize: 12)),
                    Text('50', style: GoogleFonts.nunito(color: Colors.black54, fontSize: 12)),
                    Text('0', style: GoogleFonts.nunito(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 20), // Espaço para alinhar com o eixo X
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, color: Colors.grey[300]), // Linha do eixo Y
                const SizedBox(width: 16),
                
                // Barras (Eixo X)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarraGrafico('Nível 1', 85),
                      _buildBarraGrafico('Nível 2', 65),
                      _buildBarraGrafico('Nível 3', 75),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraGrafico(String label, double porcentagem) {
    // Calcula a altura da barra baseado no tamanho máximo de 160 pixels (para caber nos 200 do container)
    final alturaBarra = 160 * (porcentagem / 100);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 48,
          height: alturaBarra,
          color: _vermelho,
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildUltimasPartidas() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimas Partidas',
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          _buildLinhaPartida('Nível 1', '26/05/2026', '260 pts'),
          const Divider(height: 24),
          _buildLinhaPartida('Nível 1', '24/05/2026', '180 pts'),
          const Divider(height: 24),
          _buildLinhaPartida('Nível 2', '23/05/2026', '210 pts'),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLinhaPartida(String nivel, String data, String pontos) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(nivel, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(data, style: GoogleFonts.nunito(color: Colors.black54)),
        Text(pontos, style: GoogleFonts.nunito(color: Colors.black54)),
      ],
    );
  }
}