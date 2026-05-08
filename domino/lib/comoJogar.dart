import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          // ─── SETA NO CANTO SUPERIOR ESQUERDO ────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: _vermelho, size: 36), // Seta colorida
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ─── CONTEÚDO ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isWide ? 36 : 16, 8, isWide ? 36 : 16, 36),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título Colorido
                      Text(
                        'Como Jogar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _vermelho, 
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Saiba como o Dominó Química funciona.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── LAYOUT ESQUERDA / DIREITA ───────────
                      isWide
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildEsquerda()),
                                  const SizedBox(width: 32),
                                  Expanded(child: _buildDireita()),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                _buildEsquerda(),
                                const SizedBox(height: 24),
                                _buildDireita(),
                              ],
                            ),

                      const SizedBox(height: 48),

                      // ─── BOTÃO ENTENDI ───────────────────────
                      Center(
                        child: SizedBox(
                          width: isWide ? 360 : double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vermelho,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4, 
                            ),
                            child: Text(
                              'Entendi!',
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
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

  // ─── LADO ESQUERDO (Exemplo do Dominó Colorido) ───────────────────
  Widget _buildEsquerda() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _vermelho.withOpacity(0.3), width: 2), // Borda com cor
        boxShadow: [
          BoxShadow(
            color: _vermelho.withOpacity(0.1), // Sombra colorida
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPecaDomino('H₂SO₄', 'Ácido'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, color: _vermelho, size: 28),
                      ...List.generate(
                        6,
                        (i) => Container(
                          width: 8,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          color: _vermelho,
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: _vermelho, size: 28),
                    ],
                  ),
                ),
                _buildPecaDomino('NaOH', 'Base'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _vermelho.withOpacity(0.1), // Fundo suave para o texto
              borderRadius: BorderRadius.circular(8)
            ),
            child: Text(
              'Conecte peças que tenham\ncorrespondência conceitual.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _vermelho,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPecaDomino(String formula, String funcao) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildMetadePeca(formula, bold: true, isFormula: true),
            VerticalDivider(width: 2, color: Colors.grey[400], thickness: 2),
            _buildMetadePeca(funcao, isFormula: false),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadePeca(String texto, {bool bold = false, required bool isFormula}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Text(
        texto,
        style: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          color: isFormula ? _vermelho : Colors.black87, // Fórmulas em vermelho
        ),
      ),
    );
  }

  // ─── LADO DIREITO (Regras com Ícones Coloridos) ───────────────────
  Widget _buildDireita() {
    final itens = [
      _RegraItem(Icons.grid_view_rounded, 'O objetivo é formar uma cadeia com todas as peças.'),
      _RegraItem(Icons.text_fields_rounded, 'Você só pode conectar peças que tenham relação correta.'),
      _RegraItem(Icons.lightbulb_outline_rounded, 'Use a lógica e o conhecimento sobre funções inorgânicas.'),
      _RegraItem(Icons.handshake_outlined, 'Complete os níveis e desafie seus conhecimentos!'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _vermelho.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: _vermelho.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: itens.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Círculo colorido atrás do ícone
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _vermelho.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icone, size: 28, color: _vermelho),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.texto,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _RegraItem {
  final IconData icone;
  final String texto;
  _RegraItem(this.icone, this.texto);
}