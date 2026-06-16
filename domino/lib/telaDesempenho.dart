import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'relatorio_models.dart';
import 'relatorio_service.dart';

class TelaDesempenho extends StatefulWidget {
  const TelaDesempenho({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  final int idUsuario;
  final String nomeUsuario;

  @override
  State<TelaDesempenho> createState() => _TelaDesempenhoState();
}

class _TelaDesempenhoState extends State<TelaDesempenho> {
  static const _vermelho = Color(0xFFC0392B);
  static const _cinzaFundo = Color(0xFFF9F9F9);
  final RelatorioService _service = const RelatorioService();
  RelatorioAluno? _relatorio;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final relatorio = await _service.obterRelatorioAluno(widget.idUsuario);
      if (!mounted) {
        return;
      }

      setState(() {
        _relatorio = relatorio;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _carregando = false;
      });
    }
  }

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
                    tooltip: 'Voltar para o menu',
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
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: _vermelho),
                  )
                : _erro != null
                ? _buildErro()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isWide ? 32 : 16),
                    child: Center(
                      child: ConstrainedBox(
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

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _vermelho, size: 44),
            const SizedBox(height: 12),
            Text(
              _erro ?? 'Nao foi possivel carregar seu desempenho.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _carregarRelatorio,
              icon: const Icon(Icons.refresh_rounded, color: _vermelho),
              label: Text(
                'Tentar novamente',
                style: GoogleFonts.nunito(
                  color: _vermelho,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticasGerais(bool isWide) {
    final relatorio = _relatorio!;
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
          '${relatorio.totalPartidas}',
          Colors.blue,
        ),
        _buildStatCard(
          Icons.timer_rounded,
          'Melhor Tempo',
          relatorio.melhorTempoFormatado,
          Colors.amber[600]!,
        ),
        _buildStatCard(
          Icons.check_circle_rounded,
          'Acertos',
          relatorio.totalPartidas == 0
              ? '--'
              : '${relatorio.taxaAcertoMedia.toStringAsFixed(0)}%',
          Colors.green,
        ),
        _buildStatCard(
          Icons.history_toggle_off_rounded,
          'Última Jogada',
          relatorio.ultimaJogadaLabel,
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
            textAlign: TextAlign.center,
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
    final partidas = _relatorio!.historico.take(5).toList();
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
                'Últimas Partidas',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _vermelho,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (partidas.isEmpty)
            Text(
              'Voce ainda nao possui partidas registradas.',
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            )
          else
            for (int i = 0; i < partidas.length; i++) ...[
              _buildLinhaPartida(partidas[i]),
              if (i != partidas.length - 1)
                const Divider(height: 24, thickness: 1),
            ],
        ],
      ),
    );
  }

  Widget _buildLinhaPartida(PartidaRelatorio partida) {
    final corNivel = switch (partida.nivelDificuldade) {
      1 => Colors.green,
      2 => Colors.amber,
      _ => _vermelho,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: corNivel.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  partida.nivelLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: corNivel,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partida.dataFormatada,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${partida.qtdAcertos} acertos • ${partida.qtdErros} erros',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          partida.tempoFormatado,
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
