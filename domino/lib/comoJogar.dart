import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Como Jogar"),
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER MODERNO (SUBSTITUTO DO VERMELHO GRANDE)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.science, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dominó Química",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Aprenda jogando de forma simples",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // EXEMPLO
                  _sectionTitle("Exemplo de Conexão"),
                  const SizedBox(height: 12),

                  _card(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _tile("H₂SO₄", "Ácido"),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward,
                                color: Colors.red),
                            const SizedBox(width: 10),
                            _tile("NaOH", "Base"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Ácidos reagem com bases (neutralização).",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // OBJETIVO
                  _sectionTitle("Objetivo"),
                  const SizedBox(height: 10),

                  _card(
                    child: const Text(
                      "Conecte todas as peças corretamente formando uma cadeia completa de reações químicas.",
                    ),
                  ),

                  const SizedBox(height: 25),

                  // REGRAS
                  _sectionTitle("Regras do Jogo"),
                  const SizedBox(height: 10),

                  _card(
                    child: Column(
                      children: const [
                        _infoItem(
                          Icons.extension,
                          "Cada peça representa uma substância química.",
                        ),
                        _infoItem(
                          Icons.link,
                          "Conecte apenas peças com relação química válida.",
                        ),
                        _infoItem(
                          Icons.science,
                          "Exemplo: Ácido + Base → neutralização.",
                        ),
                        _infoItem(
                          Icons.block,
                          "Combinações incorretas não são permitidas.",
                        ),
                        _infoItem(
                          Icons.flag,
                          "Complete todas as conexões para vencer.",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // DICAS
                  _sectionTitle("Dicas"),
                  const SizedBox(height: 10),

                  _card(
                    child: Column(
                      children: const [
                        _infoItem(
                          Icons.lightbulb,
                          "Observe a função química das substâncias.",
                        ),
                        _infoItem(
                          Icons.psychology,
                          "Use lógica para prever as reações.",
                        ),
                        _infoItem(
                          Icons.school,
                          "Quanto mais você joga, mais aprende!",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // COMPONENTES

  static Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _tile(String top, String bottom) {
    return Container(
      width: 110,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            top,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 8),
          Text(bottom),
        ],
      ),
    );
  }
}

class _infoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _infoItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}