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
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ─── CONTEÚDO ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(36, 8, 36, 36),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título
                      Text(
                        'Como Jogar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Saiba como o Dominó Química funciona.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),

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
                          width: 360,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vermelho,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
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

  // ─── LADO ESQUERDO ────────────────────────────────────────────────
  Widget _buildEsquerda() {
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPecaDomino('H₂SO₄', 'Base'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: _vermelho, size: 28),
                      ...List.generate(
                        6,
                        (i) => Container(
                          width: 8,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          color: _vermelho,
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: _vermelho, size: 28),
                    ],
                  ),
                ),
                _buildPecaDomino('NaOH', 'Ácido'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Conecte peças que tenham\ncorrespondência conceitual.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 20,
              color: Colors.black54,
              height: 1.5,
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
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildMetadePeca(formula, bold: true),
            VerticalDivider(width: 1, color: Colors.grey[300]),
            _buildMetadePeca(funcao),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadePeca(String texto, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      child: Text(
        texto,
        style: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ─── LADO DIREITO ─────────────────────────────────────────────────
  Widget _buildDireita() {
    final itens = [
      _RegraItem(
        Icons.grid_view_rounded,
        'O objetivo é formar uma cadeia com todas as peças.',
      ),
      _RegraItem(
        Icons.text_fields_rounded,
        'Você só pode conectar peças que tenham relação correta.',
      ),
      _RegraItem(
        Icons.lightbulb_outline_rounded,
        'Use a lógica e o conhecimento sobre funções inorgânicas.',
      ),
      _RegraItem(
        Icons.handshake_outlined,
        'Complete os níveis e desafie seus conhecimentos!',
      ),
    ];

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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: itens
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icone, size: 36, color: Colors.black54),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        item.texto,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RegraItem {
  final IconData icone;
  final String texto;
  _RegraItem(this.icone, this.texto);
}