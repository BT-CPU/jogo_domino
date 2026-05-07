// relatoriosAluno.dart
// Tela de relatórios de desempenho do aluno no Dominó Químico.
// Usa dados mockados — substitua as chamadas em _carregarDados() pela sua API futura.

import 'package:flutter/material.dart';
class Partida {
  final int nivelDificuldade;
  final int tempoSegundos;
  final int qtdAcertos;
  final int qtdErros;
  final DateTime dataPartida;

  const Partida({
    required this.nivelDificuldade,
    required this.tempoSegundos,
    required this.qtdAcertos,
    required this.qtdErros,
    required this.dataPartida,
  });

  int get totalPecas => qtdAcertos + qtdErros;

  double get taxaAcerto =>
      totalPecas == 0 ? 0 : (qtdAcertos / totalPecas) * 100;

  String get nivelLabel {
    switch (nivelDificuldade) {
      case 1:
        return 'Fácil';
      case 2:
        return 'Médio';
      case 3:
        return 'Difícil';
      default:
        return 'Nível $nivelDificuldade';
    }
  }

  String get tempoFormatado {
    final m = tempoSegundos ~/ 60;
    final s = tempoSegundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────
// DADOS MOCKADOS
// Substitua este bloco por chamadas HTTP quando o backend estiver pronto.
// Exemplo futuro:
//   final response = await http.get(Uri.parse('$baseUrl/partidas?id_usuario=$idUsuario'));
//   final lista = (jsonDecode(response.body) as List).map((e) => Partida.fromJson(e)).toList();
// ─────────────────────────────────────────────
List<Partida> _mockPartidas() {
  final now = DateTime.now();
  return [
    Partida(
      nivelDificuldade: 1,
      tempoSegundos: 92,
      qtdAcertos: 8,
      qtdErros: 2,
      dataPartida: now.subtract(const Duration(days: 0, hours: 2)),
    ),
    Partida(
      nivelDificuldade: 2,
      tempoSegundos: 145,
      qtdAcertos: 6,
      qtdErros: 4,
      dataPartida: now.subtract(const Duration(days: 1)),
    ),
    Partida(
      nivelDificuldade: 1,
      tempoSegundos: 78,
      qtdAcertos: 10,
      qtdErros: 0,
      dataPartida: now.subtract(const Duration(days: 2)),
    ),
    Partida(
      nivelDificuldade: 3,
      tempoSegundos: 210,
      qtdAcertos: 5,
      qtdErros: 5,
      dataPartida: now.subtract(const Duration(days: 3)),
    ),
    Partida(
      nivelDificuldade: 2,
      tempoSegundos: 130,
      qtdAcertos: 7,
      qtdErros: 3,
      dataPartida: now.subtract(const Duration(days: 5)),
    ),
  ];
}

// ─────────────────────────────────────────────
// TELA PRINCIPAL
// ─────────────────────────────────────────────
class RelatoriosAlunoPage extends StatefulWidget {
  /// Recebe o nome do aluno logado para exibição.
  /// Substitua por um objeto de usuário completo quando integrar autenticação.
  final String nomeAluno;

  const RelatoriosAlunoPage({super.key, this.nomeAluno = 'Aluno'});

  @override
  State<RelatoriosAlunoPage> createState() => _RelatoriosAlunoPageState();
}

class _RelatoriosAlunoPageState extends State<RelatoriosAlunoPage> {
  // ── Paleta de cores (baseada na identidade Centro Paula Souza) ──
  static const Color _azulPrincipal = Color(0xFF003F8A);
  static const Color _azulClaro = Color(0xFF1565C0);
  static const Color _laranja = Color(0xFFFF6B00);
  static const Color _cinzaFundo = Color(0xFFF4F6FA);
  static const Color _branco = Colors.white;
  static const Color _verde = Color(0xFF2E7D32);
  static const Color _vermelho = Color(0xFFC62828);

  List<Partida> _partidas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Simula delay de rede. Substitua pelo fetch real da API.
  Future<void> _carregarDados() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _partidas = _mockPartidas();
      _carregando = false;
    });
  }

  // ── Estatísticas calculadas ──
  int get _totalPartidas => _partidas.length;

  double get _taxaMediaAcerto {
    if (_partidas.isEmpty) return 0;
    return _partidas.map((p) => p.taxaAcerto).reduce((a, b) => a + b) /
        _partidas.length;
  }

  int get _melhorTempo {
    if (_partidas.isEmpty) return 0;
    return _partidas.map((p) => p.tempoSegundos).reduce((a, b) => a < b ? a : b);
  }

  int get _totalAcertos =>
      _partidas.fold(0, (sum, p) => sum + p.qtdAcertos);

  int get _totalErros =>
      _partidas.fold(0, (sum, p) => sum + p.qtdErros);

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: _buildAppBar(),
      body: _carregando ? _buildLoading() : _buildConteudo(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _azulPrincipal,
      foregroundColor: _branco,
      elevation: 0,
      title: const Text(
        'Meu Desempenho',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            setState(() => _carregando = true);
            _carregarDados();
          },
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _azulPrincipal),
          SizedBox(height: 16),
          Text('Carregando seus dados...', style: TextStyle(color: _azulPrincipal)),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    return RefreshIndicator(
      color: _azulPrincipal,
      onRefresh: _carregarDados,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCabecalhoAluno(),
          const SizedBox(height: 20),
          _buildTituloSecao('Resumo Geral'),
          const SizedBox(height: 12),
          _buildCardsResumo(),
          const SizedBox(height: 24),
          _buildTituloSecao('Desempenho por Nível'),
          const SizedBox(height: 12),
          _buildBarrasNivel(),
          const SizedBox(height: 24),
          _buildTituloSecao('Histórico de Partidas'),
          const SizedBox(height: 12),
          if (_partidas.isEmpty)
            _buildSemDados()
          else
            ..._partidas.map(_buildCardPartida),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Cabeçalho com nome e avatar ──
  Widget _buildCabecalhoAluno() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_azulPrincipal, _azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _azulPrincipal.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _laranja,
            child: Text(
              widget.nomeAluno.isNotEmpty
                  ? widget.nomeAluno[0].toUpperCase()
                  : 'A',
              style: const TextStyle(
                color: _branco,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${widget.nomeAluno}!',
                  style: const TextStyle(
                    color: _branco,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalPartidas partida${_totalPartidas != 1 ? 's' : ''} jogada${_totalPartidas != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: _branco.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Medalha de taxa de acerto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _laranja,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_taxaMediaAcerto.toStringAsFixed(0)}% ✓',
              style: const TextStyle(
                color: _branco,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cards de resumo ──
  Widget _buildCardsResumo() {
    final melhorTempoStr = _partidas.isEmpty
        ? '--:--'
        : Partida(
            nivelDificuldade: 1,
            tempoSegundos: _melhorTempo,
            qtdAcertos: 0,
            qtdErros: 0,
            dataPartida: DateTime.now(),
          ).tempoFormatado;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildCardResumo(
          icone: Icons.check_circle_outline_rounded,
          valor: '$_totalAcertos',
          label: 'Total de Acertos',
          cor: _verde,
        ),
        _buildCardResumo(
          icone: Icons.cancel_outlined,
          valor: '$_totalErros',
          label: 'Total de Erros',
          cor: _vermelho,
        ),
        _buildCardResumo(
          icone: Icons.timer_outlined,
          valor: melhorTempoStr,
          label: 'Melhor Tempo',
          cor: _azulPrincipal,
        ),
        _buildCardResumo(
          icone: Icons.emoji_events_outlined,
          valor: '${_taxaMediaAcerto.toStringAsFixed(1)}%',
          label: 'Média de Acerto',
          cor: _laranja,
        ),
      ],
    );
  }

  Widget _buildCardResumo({
    required IconData icone,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: cor, size: 26),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barras de desempenho por nível ──
  Widget _buildBarrasNivel() {
    final niveis = [
      {'label': 'Fácil', 'nivel': 1, 'cor': _verde},
      {'label': 'Médio', 'nivel': 2, 'cor': _laranja},
      {'label': 'Difícil', 'nivel': 3, 'cor': _vermelho},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: niveis.map((n) {
          final partidasNivel = _partidas
              .where((p) => p.nivelDificuldade == n['nivel'])
              .toList();
          final media = partidasNivel.isEmpty
              ? 0.0
              : partidasNivel.map((p) => p.taxaAcerto).reduce((a, b) => a + b) /
                  partidasNivel.length;
          final cor = n['cor'] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      n['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      partidasNivel.isEmpty
                          ? 'Sem partidas'
                          : '${media.toStringAsFixed(0)}% (${partidasNivel.length} partida${partidasNivel.length != 1 ? 's' : ''})',
                      style: TextStyle(
                        color: cor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: media / 100,
                    minHeight: 10,
                    backgroundColor: cor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Card de cada partida no histórico ──
  Widget _buildCardPartida(Partida p) {
    final corNivel = p.nivelDificuldade == 1
        ? _verde
        : p.nivelDificuldade == 2
            ? _laranja
            : _vermelho;

    final agora = DateTime.now();
    final diff = agora.difference(p.dataPartida);
    String dataStr;
    if (diff.inMinutes < 60) {
      dataStr = 'Há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      dataStr = 'Há ${diff.inHours}h';
    } else {
      dataStr = 'Há ${diff.inDays} dia${diff.inDays != 1 ? 's' : ''}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: corNivel, width: 4),
        ),
      ),
      child: Row(
        children: [
          // Nível
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corNivel.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.nivelLabel,
                  style: TextStyle(
                    color: corNivel,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dataStr,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Acertos e erros
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniStat(
                  Icons.check_rounded,
                  '${p.qtdAcertos}',
                  'Acertos',
                  _verde,
                ),
                _buildMiniStat(
                  Icons.close_rounded,
                  '${p.qtdErros}',
                  'Erros',
                  _vermelho,
                ),
                _buildMiniStat(
                  Icons.timer_rounded,
                  p.tempoFormatado,
                  'Tempo',
                  _azulPrincipal,
                ),
              ],
            ),
          ),
          // Taxa de acerto
          Column(
            children: [
              Text(
                '${p.taxaAcerto.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: corNivel,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Text(
                'acerto',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icone, String valor, String label, Color cor) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 16),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: cor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }

  // ── Utilitários ──
  Widget _buildTituloSecao(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _azulPrincipal,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSemDados() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _branco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Nenhuma partida registrada ainda.\nJogue para ver seu desempenho aqui!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }
}