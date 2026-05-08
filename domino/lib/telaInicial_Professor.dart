import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importações das telas que o professor pode acessar
import 'telaLogin.dart';
import 'cadastrarAluno.dart';
import 'relatoriosProfessor.dart';

// ─── TELA INICIAL DO PROFESSOR (MENU PRINCIPAL) ──────────────────────────
class TelaInicialProfessor extends StatelessWidget {
  const TelaInicialProfessor({super.key});

  // Paleta de cores definida anteriormente
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    // Verificação de responsividade (Web vs Mobile)
    final isWide = MediaQuery.of(context).size.width > 600;
    
    // Define o tamanho do logo central baseado na largura da tela
    final logoSize = isWide ? 90.0 : 70.0;

    return Scaffold(
      backgroundColor: _cinzaFundo,
      body: Column(
        children: [
          // ─── BARRA SUPERIOR VERMELHA ────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 255, 126, 112), // Vermelho mais claro
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo da ETEC no canto esquerdo
                Image.asset(
                  'imagens/etec_santo_andre.png',
                  height: 75,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 75,
                    width: 150,
                    child: Placeholder(color: Colors.white),
                  ),
                ),
                
                // Texto de boas-vindas no canto direito (apenas em telas largas)
                if (isWide)
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Olá, Professor!',
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

          // ─── CONTEÚDO DO MENU (CENTRALIZADO) ─────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800), // Limita largura na Web
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ─── CORREÇÃO: ADICIONADO O LOGO DO BECKER AQUI ───
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Círculo externo vermelho com sombra
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: _vermelho,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(logoSize * 0.12),
                              child: Container(
                                // Círculo interno branco
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(logoSize * 0.12),
                                child: Image.asset(
                                  'imagens/logo_quimico.png', // Símbolo do Becker
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      // Fallback caso a imagem não carregue
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _vermelho.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.science,
                                          size: logoSize * 0.4,
                                          color: _vermelho,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Texto do Título ao lado do logo
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'DOMINÓ DA\nQUÍMICA',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: isWide ? 26 : 22,
                                    fontWeight: FontWeight.w900,
                                    color: _vermelho,
                                    letterSpacing: 1.5,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'FUNÇÕES INORGÂNICAS',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[500],
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ─── FIM DA CORREÇÃO DO LOGO ──────────────────────

                      const SizedBox(height: 40),
                      
                      // Título do Menu
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

                      // ─── BOTÕES DO MENU (CARDS) ────────────────────────────────
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          // Botão JOGAR
                          _buildMenuCard(
                            context: context,
                            title: 'Jogar',
                            subtitle: 'Testar ou demonstrar o jogo',
                            icon: Icons.sports_esports_rounded,
                            isPrimary: true, // Cor de destaque (vermelha)
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tela do Jogo em construção!')),
                              );
                            },
                          ),
                          
                          // Botão CADASTRAR ALUNO
                          _buildMenuCard(
                            context: context,
                            title: 'Cadastrar Aluno',
                            subtitle: 'Adicionar novos estudantes',
                            icon: Icons.person_add_alt_1_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CadastrarAlunoScreen(),
                                ),
                              );
                            },
                          ),
                          
                          // Botão RELATÓRIOS
                          _buildMenuCard(
                            context: context,
                            title: 'Relatórios',
                            subtitle: 'Acompanhar desempenho',
                            icon: Icons.bar_chart_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RelatoriosProfessorScreen(),
                                ),
                              );
                            },
                          ),
                          
                          // Botão SAIR
                          _buildMenuCard(
                            context: context,
                            title: 'Sair',
                            subtitle: 'Encerrar sessão',
                            icon: Icons.logout_rounded,
                            iconColor: Colors.grey[600],
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
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

  // ─── WIDGET AUXILIAR PARA CRIAR OS CARDS DO MENU ───────────────────────
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
          width: 300,
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
              // Ícone dentro de um círculo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : _cinzaFundo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isPrimary ? Colors.white : (iconColor ?? _vermelho),
                ),
              ),
              const SizedBox(width: 16),
              // Textos (Título e Subtítulo)
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