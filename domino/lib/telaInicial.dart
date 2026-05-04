import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    // Verifica se a tela é larga (Web/Tablet) para ajustar o tamanho dos botões
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          // ─── BARRA VERMELHA (Mesmo padrão do Login) ────────────
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 255, 126, 112),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo Etec
                Image.asset('imagens/etec_santo_andre.png', height: 75, errorBuilder: (context, error, stackTrace) => const SizedBox(height: 75, width: 150, child: Placeholder(color: Colors.white))),
                
                // Informação do usuário logado (Aparece apenas em telas maiores)
                if (isWide)
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Olá, Aluno!',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ─── CONTEÚDO PRINCIPAL ────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800), // Limita a largura na Web
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Menu Principal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha uma das opções abaixo para continuar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ─── OPÇÕES DO MENU ──────────────────────────
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildMenuCard(
                            context: context,
                            title: 'Nova Partida',
                            subtitle: 'Iniciar jogo de classificação',
                            icon: Icons.play_arrow_rounded,
                            isPrimary: true,
                            onTap: () {
                              debugPrint('Navegar para a tela do jogo');
                              // Navigator.pushNamed(context, '/jogo');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Meus Relatórios',
                            subtitle: 'Veja seu desempenho',
                            icon: Icons.bar_chart_rounded,
                            onTap: () {
                              debugPrint('Navegar para relatórios');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Regras do Jogo',
                            subtitle: 'Como jogar o dominó',
                            icon: Icons.menu_book_rounded,
                            onTap: () {
                              debugPrint('Navegar para regras');
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            title: 'Sair',
                            subtitle: 'Desconectar da conta',
                            icon: Icons.logout_rounded,
                            iconColor: Colors.grey[600],
                            onTap: () {
                              debugPrint('Fazer logout');
                              // Navigator.pushReplacementNamed(context, '/login');
                            },
                          ),
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

  //WIDGET REUTILIZÁVEL PARA OS BOTÕES DO MENU
  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? iconColor,
  }) {
    return Material(
      color: isPrimary ? _vermelho : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: isPrimary ? Colors.red[800] : Colors.grey[100],
        child: Container(
          width: 300, // Largura fixa para manter o grid alinhado
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? _vermelho : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withOpacity(0.2) : _cinzaFundo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isPrimary 
                      ? Colors.white 
                      : (iconColor ?? _vermelho),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isPrimary ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}