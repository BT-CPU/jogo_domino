import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogo_models.dart';
import 'telaJogo.dart';

class TelaDificuldade extends StatefulWidget {
  const TelaDificuldade({super.key});

  @override
  State<TelaDificuldade> createState() => _TelaDificuldadeState();
}

class _TelaDificuldadeState extends State<TelaDificuldade> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  int? _dificuldadeSelecionada;

  DificuldadeJogo? get _dificuldadeAtual {
    if (_dificuldadeSelecionada == null) {
      return null;
    }
    return DificuldadeJogo.fromId(_dificuldadeSelecionada!);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 255, 126, 112),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'imagens/etec_santo_andre.png',
                  height: 75,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 75,
                    width: 150,
                    child: Placeholder(color: Colors.white),
                  ),
                ),
                if (isWide)
                  Text(
                    'Selecione a dificuldade',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      Text(
                        'Escolha a Dificuldade',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cada modo trabalha um tipo diferente de relação entre as peças.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _DifficultyCard(
                            titulo: 'Dificuldade 1',
                            subtitulo: 'Fórmula ↔ Função',
                            descricao:
                                'Relacione a fórmula química com a função inorgânica correspondente.',
                            icon: Icons.science_outlined,
                            destaque: _dificuldadeSelecionada == 1,
                            onTap: () => setState(() {
                              _dificuldadeSelecionada = 1;
                            }),
                          ),
                          _DifficultyCard(
                            titulo: 'Dificuldade 2',
                            subtitulo: 'Propriedades ↔ Classificação',
                            descricao:
                                'Associe as propriedades observadas à classificação correta da substância.',
                            icon: Icons.category_outlined,
                            destaque: _dificuldadeSelecionada == 2,
                            onTap: () => setState(() {
                              _dificuldadeSelecionada = 2;
                            }),
                          ),
                          _DifficultyCard(
                            titulo: 'Dificuldade 3',
                            subtitulo: 'Classificação ↔ Reação',
                            descricao:
                                'Relacione classes químicas que reagem entre si.',
                            icon: Icons.hub_outlined,
                            destaque: _dificuldadeSelecionada == 3,
                            onTap: () => setState(() {
                              _dificuldadeSelecionada = 3;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(
                          'Voltar ao menu',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _vermelho,
                          side: const BorderSide(color: _vermelho),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _dificuldadeAtual == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TelaJogo(
                                      dificuldade: _dificuldadeAtual!,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'Iniciar partida',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vermelho,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.titulo,
    required this.subtitulo,
    required this.descricao,
    required this.icon,
    required this.onTap,
    this.destaque = false,
  });

  final String titulo;
  final String subtitulo;
  final String descricao;
  final IconData icon;
  final VoidCallback onTap;
  final bool destaque;

  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 290,
          height: 272,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: destaque ? _vermelho : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: destaque ? _vermelho : Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: destaque
                      ? Colors.white.withValues(alpha: 0.18)
                      : _cinzaFundo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: destaque ? Colors.white : _vermelho,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: destaque ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitulo,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: destaque ? Colors.white70 : _vermelho,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                descricao,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  height: 1.45,
                  color: destaque ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
