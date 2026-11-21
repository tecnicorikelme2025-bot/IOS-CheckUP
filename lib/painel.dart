part of 'main.dart';


// ==========================================
// TELA 3: PAINEL EXCLUSIVO DO GESTOR & GERADOR QR
// ==========================================

class PainelGestorScreen extends StatelessWidget {
  const PainelGestorScreen({super.key});

  void _abrirModalGeradorQrCode(BuildContext context) {
    final nomeCtrl = TextEditingController();
    double? lat;
    double? lng;
    String? erro;
    bool buscandoGps = false;
    Local? selecionado;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final state = Provider.of<AppState>(ctx);

          Future<void> capturar() async {
            setModalState(() {
              buscandoGps = true;
              erro = null;
            });
            try {
              if (!await Geolocator.isLocationServiceEnabled()) throw 'Ative o GPS do celular.';
              var perm = await Geolocator.checkPermission();
              if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
              if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw 'Permissão de localização negada.';
              final pos = await Geolocator.getCurrentPosition();
              if (pos.isMocked) throw 'Localização simulada detectada.';
              lat = pos.latitude;
              lng = pos.longitude;
            } catch (e) {
              erro = e is String ? e : 'Não foi possível obter a posição.';
            }
            setModalState(() => buscandoGps = false);
          }

          Future<void> imprimir(Local l) async {
            final pdf = pw.Document();
            pdf.addPage(
              pw.Page(
                build: (pw.Context c) => pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('CHECK-IN RONDA - LOCALIZAÇÃO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text(l.nome, style: pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 20),
                      pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: l.codigoQr, width: 200, height: 200),
                    ],
                  ),
                ),
              ),
            );
            await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Locais e QR Codes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Vá até o local, capture a posição e salve. O QR é único e o check-in só vale perto dele.', style: TextStyle(color: ctx.cr.tintaSuave)),
                  const SizedBox(height: 16),
                  TextField(controller: nomeCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome do local (Ex: Corredor 4)')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: buscandoGps ? null : capturar,
                    icon: Icon(lat != null ? Icons.gps_fixed_rounded : Icons.my_location_rounded, color: lat != null ? ctx.cr.ok : null),
                    label: Text(buscandoGps ? 'Buscando posição...' : (lat != null ? 'Posição capturada' : 'Usar minha posição atual')),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 8),
                    Text(erro!, style: TextStyle(color: ctx.cr.atraso, fontWeight: FontWeight.w700)),
                  ],
                  if (lat == null) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Sem posição, o GPS não será conferido nesse local.', style: TextStyle(fontSize: 12, color: ctx.cr.tintaSuave)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (nomeCtrl.text.trim().isEmpty) {
                        setModalState(() => erro = 'Digite o nome do local.');
                        return;
                      }
                      final novo = state.adicionarLocal(nomeCtrl.text.trim(), lat, lng);
                      setModalState(() {
                        selecionado = novo;
                        nomeCtrl.clear();
                        lat = null;
                        lng = null;
                        erro = null;
                      });
                    },
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Salvar local e gerar QR'),
                  ),
                  if (selecionado != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8),
                            child: QrImageView(data: selecionado!.codigoQr, version: QrVersions.auto, size: 180.0),
                          ),
                          const SizedBox(height: 8),
                          Text(selecionado!.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => imprimir(selecionado!),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Imprimir QR em PDF'),
                    ),
                  ],
                  if (state.locais.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Locais cadastrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView(
                        shrinkWrap: true,
                        children: state.locais.map((l) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(l.latitude != null ? 'GPS cadastrado' : 'Sem GPS'),
                          onTap: () => setModalState(() => selecionado = l),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: ctx,
                                builder: (d) => AlertDialog(
                                  title: const Text('Excluir local?'),
                                  content: Text('${l.nome} será removido. Tarefas já criadas continuam com o QR antigo.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
                                    ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Excluir')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                state.excluirLocal(l.id);
                                setModalState(() {
                                  if (selecionado?.id == l.id) selecionado = null;
                                });
                              }
                            },
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Painel Exclusivo do Gestor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ações de Gestão Operacional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: CrTheme.marcaForte, foregroundColor: Colors.white),
                onPressed: () => gerarRelatorioCompleto(context, state),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('EXPORTAR RELATÓRIO (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: context.cr.limpeza, foregroundColor: Colors.white),
                onPressed: () => _abrirModalGeradorQrCode(context),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('LOCAIS E QR CODES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RondasRecorrentesScreen())),
                icon: const Icon(Icons.event_repeat_rounded),
                label: const Text('RONDAS RECORRENTES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListaReposicaoScreen())),
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text('LISTA DE REPOSIÇÃO (${state.tarefasDoUsuario.where((t) => t.produtoEmFalta).length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipeScreen())),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('EQUIPE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                onPressed: () {
                  final avisoCtrl = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Publicar Aviso Geral'),
                      content: TextField(
                        controller: avisoCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Digite o comunicado...'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                        ElevatedButton(
                          onPressed: () async {
                            if (avisoCtrl.text.isNotEmpty) {
                              state.adicionarAviso(Aviso(
                                id: 'av_${DateTime.now().millisecondsSinceEpoch}',
                                titulo: 'Comunicado da Gestão',
                                mensagem: avisoCtrl.text,
                                data: DateTime.now(),
                                autor: state.usuarioLogado?.nome ?? 'Gestor',
                              ));
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aviso publicado no mural!')));
                              }
                            }
                          },
                          child: const Text('Publicar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.campaign),
                label: const Text('PUBLICAR COMUNICADO NO MURAL'),
              ),
            ),
            const SizedBox(height: 24),
            const DesempenhoGestor(),
            const SizedBox(height: 24),
            const Text('Resumo da Operação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Concluídas: ${state.totalConcluidas}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))))),
                Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Atrasadas: ${state.totalAtrasadas}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))))),
              ],
            )
          ],
        ),
      ),
    );
  }
}


// ==========================================
// ASSINATURA DIGITAL DO FISCAL
// ==========================================

class AssinaturaFiscalScreen extends StatefulWidget {
  const AssinaturaFiscalScreen({super.key});

  @override
  State<AssinaturaFiscalScreen> createState() => _AssinaturaFiscalScreenState();
}


class _AssinaturaFiscalScreenState extends State<AssinaturaFiscalScreen> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinatura do Fiscal / Cliente'),
        actions: [IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _points.clear()))],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Assine abaixo para validar o encerramento do turno:', textAlign: TextAlign.center),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2), borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    RenderBox renderBox = context.findRenderObject() as RenderBox;
                    _points.add(renderBox.globalToLocal(details.globalPosition));
                  });
                },
                onPanEnd: (details) => _points.add(null),
                child: CustomPaint(painter: SignaturePainter(_points), size: Size.infinite),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  Provider.of<AppState>(context, listen: false).salvarAssinatura(_points);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assinatura registrada!')));
                },
                child: const Text('CONFIRMAR ASSINATURA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}


class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black..strokeCap = StrokeCap.round..strokeWidth = 3.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}


// ==========================================
// DESEMPENHO (gráficos do gestor)
// ==========================================
class _BarraH extends StatelessWidget {
  final String rotulo;
  final double fracao;
  final String texto;
  final Color cor;
  const _BarraH({required this.rotulo, required this.fracao, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(rotulo, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(texto, style: TextStyle(fontSize: 12, color: context.cr.tintaSuave)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: fracao.clamp(0.0, 1.0), minHeight: 10, backgroundColor: cor.withOpacity(0.15), color: cor),
          ),
        ],
      ),
    );
  }
}


class DesempenhoGestor extends StatelessWidget {
  const DesempenhoGestor({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final c = context.cr;
    final tarefas = state.tarefasDoPeriodo;
    final concluidas = tarefas.where((t) => t.status == StatusTarefa.concluida).toList();
    final taxa = tarefas.isEmpty ? 0 : (concluidas.length * 100 / tarefas.length).round();
    final duracoes = concluidas.map((t) => t.duracao).whereType<Duration>().toList();
    final media = duracoes.isEmpty ? null : Duration(seconds: duracoes.fold<int>(0, (s, d) => s + d.inSeconds) ~/ duracoes.length);

    final porPessoa = <String, List<Tarefa>>{};
    for (final t in tarefas) {
      porPessoa.putIfAbsent(t.idResponsavel, () => []).add(t);
    }

    final hoje = DateTime.now();
    final dias = List.generate(7, (i) => DateTime(hoje.year, hoje.month, hoje.day).subtract(Duration(days: 6 - i)));
    final porDia = dias
        .map((d) => state.tarefasDoUsuario.where((t) => t.status == StatusTarefa.concluida && t.horarioConclusao != null && DateUtils.isSameDay(t.horarioConclusao, d)).length)
        .toList();
    final maxDia = porDia.fold<int>(1, (m, v) => v > m ? v : m);

    final tempos = <String, List<int>>{};
    for (final t in concluidas) {
      final d = t.duracao;
      if (d != null) tempos.putIfAbsent(t.local, () => []).add(d.inSeconds);
    }
    final mediasLocal = tempos.entries.map((e) => MapEntry(e.key, e.value.fold<int>(0, (a, b) => a + b) ~/ e.value.length)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxTempo = mediasLocal.isEmpty ? 1 : mediasLocal.first.value;

    Widget metrica(String valor, String rotulo) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(rotulo, style: TextStyle(fontSize: 12, color: c.tintaSuave)),
          ]),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Desempenho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final o in const [(1, 'Hoje'), (7, '7 dias'), (30, '30 dias'), (0, 'Tudo')])
              ChoiceChip(label: Text(o.$2), selected: state.periodoDias == o.$1, onSelected: (_) => state.definirPeriodo(o.$1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [
          metrica('$taxa%', 'taxa de conclusão (${concluidas.length} de ${tarefas.length})'),
          const SizedBox(width: 8),
          metrica(media == null ? '-' : formatarDuracao(media), 'tempo médio por tarefa'),
        ]),
        const SizedBox(height: 16),
        const Text('Por funcionário', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (porPessoa.isEmpty) Text('Sem tarefas no período.', style: TextStyle(color: c.tintaSuave)),
        for (final e in porPessoa.entries)
          _BarraH(
            rotulo: state.getUsuarioPorId(e.key)?.nome ?? 'Ex-funcionário',
            fracao: e.value.where((t) => t.status == StatusTarefa.concluida).length / e.value.length,
            texto: '${e.value.where((t) => t.status == StatusTarefa.concluida).length}/${e.value.length} concluídas'
                '${e.value.where((t) => t.statusEfetivo == StatusTarefa.atrasada).isNotEmpty ? ' · ${e.value.where((t) => t.statusEfetivo == StatusTarefa.atrasada).length} atrasada(s)' : ''}',
            cor: c.ok,
          ),
        const SizedBox(height: 8),
        const Text('Concluídas nos últimos 7 dias', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${porDia[i]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        height: 4 + 80.0 * porDia[i] / maxDia,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: porDia[i] == 0 ? c.linha : CrTheme.marcaForte, borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormat('dd/MM').format(dias[i]), style: TextStyle(fontSize: 10, color: c.tintaSuave)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tempo médio por local', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (mediasLocal.isEmpty) Text('Os tempos aparecem depois das primeiras tarefas concluídas com check-in.', style: TextStyle(color: c.tintaSuave)),
        for (final e in mediasLocal.take(5))
          _BarraH(rotulo: e.key, fracao: e.value / maxTempo, texto: formatarDuracao(Duration(seconds: e.value)), cor: c.limpeza),
      ],
    );
  }
}


// ==========================================
// RELATÓRIO PDF COMPLETO
// ==========================================
pw.Widget _assinaturaPdf(List<Offset?> pontos) {
  final validos = pontos.whereType<Offset>().toList();
  if (validos.isEmpty) return pw.SizedBox(height: 40);
  double minX = validos.first.dx, maxX = minX, minY = validos.first.dy, maxY = minY;
  for (final o in validos) {
    if (o.dx < minX) minX = o.dx;
    if (o.dx > maxX) maxX = o.dx;
    if (o.dy < minY) minY = o.dy;
    if (o.dy > maxY) maxY = o.dy;
  }
  final largura = (maxX - minX) < 1 ? 1.0 : (maxX - minX);
  final altura = (maxY - minY) < 1 ? 1.0 : (maxY - minY);
  const boxW = 200.0;
  const boxH = 70.0;
  final escala = (boxW / largura) < (boxH / altura) ? (boxW / largura) : (boxH / altura);
  return pw.Container(
    width: boxW,
    height: boxH,
    child: pw.CustomPaint(
      size: PdfPoint(boxW, boxH),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setStrokeColor(PdfColors.black);
        canvas.setLineWidth(1.2);
        double? ax;
        double? ay;
        for (final p in pontos) {
          if (p == null) {
            ax = null;
            ay = null;
            continue;
          }
          final x = (p.dx - minX) * escala;
          final y = boxH - (p.dy - minY) * escala;
          if (ax != null && ay != null) {
            canvas.moveTo(ax, ay);
            canvas.lineTo(x, y);
            canvas.strokePath();
          }
          ax = x;
          ay = y;
        }
      },
    ),
  );
}


pw.Widget _fotoPdf(String rotulo, Uint8List bytes) => pw.Expanded(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(rotulo, style: pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 2),
      pw.Image(pw.MemoryImage(bytes), height: 110, fit: pw.BoxFit.contain),
    ],
  ),
);


Future<void> gerarRelatorioCompleto(BuildContext context, AppState state) async {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando relatório...')));
  final pdf = pw.Document();
  final fmt = DateFormat('dd/MM HH:mm');
  final tarefas = state.tarefasDoPeriodo..sort((a, b) => a.horarioPrevisto.compareTo(b.horarioPrevisto));
  final concluidas = tarefas.where((t) => t.status == StatusTarefa.concluida).toList();
  final atrasadas = tarefas.where((t) => t.statusEfetivo == StatusTarefa.atrasada).length;
  final pendentes = tarefas.where((t) => t.statusEfetivo == StatusTarefa.pendente).length;
  final taxa = tarefas.isEmpty ? 0 : (concluidas.length * 100 / tarefas.length).round();
  final duracoes = concluidas.map((t) => t.duracao).whereType<Duration>().toList();
  final media = duracoes.isEmpty ? null : Duration(seconds: duracoes.fold<int>(0, (s, d) => s + d.inSeconds) ~/ duracoes.length);
  final nomePeriodo = state.periodoDias == 1 ? 'Hoje' : (state.periodoDias == 0 ? 'Todo o histórico' : 'Últimos ${state.periodoDias} dias');
  String nomeDe(String id) => state.getUsuarioPorId(id)?.nome ?? 'Ex-funcionário';

  final porPessoa = <List<String>>[];
  final ids = tarefas.map((t) => t.idResponsavel).toSet();
  for (final id in ids) {
    final ts = tarefas.where((t) => t.idResponsavel == id).toList();
    final feitas = ts.where((t) => t.status == StatusTarefa.concluida).length;
    final atr = ts.where((t) => t.statusEfetivo == StatusTarefa.atrasada).length;
    porPessoa.add([nomeDe(id), '${ts.length}', '$feitas', '$atr', '${(feitas * 100 / ts.length).round()}%']);
  }

  final detalhes = <pw.Widget>[];
  for (final t in concluidas.take(30)) {
    final antes = await state.bytesDaFoto(t.fotoAntesPath);
    final depois = await state.bytesDaFoto(t.fotoDepoisPath);
    detalhes.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(t.titulo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text('${t.local} · ${nomeDe(t.idResponsavel)}', style: pw.TextStyle(fontSize: 10)),
            pw.Text(
              'Concluída em ${t.horarioConclusao != null ? fmt.format(t.horarioConclusao!) : '-'}${t.duracao != null ? ' · executada em ${formatarDuracao(t.duracao!)}' : ''}',
              style: pw.TextStyle(fontSize: 10),
            ),
            if (t.latitudeCheckin != null)
              pw.Text('Check-in por GPS: ${t.latitudeCheckin!.toStringAsFixed(5)}, ${t.longitudeCheckin?.toStringAsFixed(5) ?? '-'}', style: pw.TextStyle(fontSize: 9)),
            if (t.observacao != null && t.observacao!.isNotEmpty) pw.Text('Observação: ${t.observacao}', style: pw.TextStyle(fontSize: 10)),
            if (t.produtoEmFalta) pw.Text('Produto em falta informado.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            if (antes != null || depois != null) ...[
              pw.SizedBox(height: 6),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                if (antes != null) _fotoPdf('Antes', antes),
                if (antes != null && depois != null) pw.SizedBox(width: 8),
                if (depois != null) _fotoPdf('Depois', depois),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  final estiloTitulo = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context ctx) => [
        pw.Header(level: 0, child: pw.Text('CheckUP - Relatório de Operação', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Text('Período: $nomePeriodo'),
        pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
        pw.Text('Gestor responsável: ${state.usuarioLogado?.nome ?? 'Sistema'}'),
        pw.SizedBox(height: 12),
        pw.Text('Resumo', style: estiloTitulo),
        pw.Text('Tarefas no período: ${tarefas.length}  |  Concluídas: ${concluidas.length}  |  Pendentes: $pendentes  |  Atrasadas: $atrasadas'),
        pw.Text('Taxa de conclusão: $taxa%${media != null ? '  |  Tempo médio de execução: ${formatarDuracao(media)}' : ''}'),
        if (porPessoa.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('Por funcionário', style: estiloTitulo),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: ['Funcionário', 'Tarefas', 'Concluídas', 'Atrasadas', 'Conclusão'],
            data: porPessoa,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: pw.TextStyle(fontSize: 9),
          ),
        ],
        pw.SizedBox(height: 14),
        pw.Text('Detalhamento das tarefas', style: estiloTitulo),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headers: ['Título', 'Local', 'Responsável', 'Status', 'Previsto', 'Concluído', 'Duração'],
          data: tarefas
              .map((t) => [
            t.titulo,
            t.local,
            nomeDe(t.idResponsavel),
            t.statusEfetivo.name.toUpperCase(),
            fmt.format(t.horarioPrevisto),
            t.horarioConclusao != null ? fmt.format(t.horarioConclusao!) : '-',
            t.duracao != null ? formatarDuracao(t.duracao!) : '-',
          ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: pw.TextStyle(fontSize: 8),
        ),
        if (detalhes.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text(concluidas.length > 30 ? 'Comprovações (30 mais antigas de ${concluidas.length} concluídas)' : 'Comprovações', style: estiloTitulo),
          pw.SizedBox(height: 8),
          ...detalhes,
        ],
        pw.SizedBox(height: 24),
        pw.Text('Assinatura de validação do fiscal', style: estiloTitulo),
        pw.SizedBox(height: 8),
        _assinaturaPdf(state.pontosAssinatura),
        pw.Container(width: 220, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.black)))),
        pw.Text('Fiscal de Contrato / Cliente'),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}


// ==========================================
// EQUIPE (gestor)
// ==========================================
class EquipeScreen extends StatelessWidget {
  const EquipeScreen({super.key});

  Future<bool> _confirmar(BuildContext context, String titulo, String texto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    return ok == true;
  }

  void _abrirCadastro(BuildContext context, AppState state) {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    var tipo = TipoPerfil.funcionario;
    var definirSenha = false;
    var mostrarSenha = false;
    String? erro;
    bool enviando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Adicionar pessoa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  definirSenha
                      ? 'Você define a senha agora e nenhum e-mail é enviado. Passe a senha para a pessoa; ela pode trocá-la depois em "Esqueci minha senha".'
                      : 'A pessoa recebe um e-mail para criar a própria senha. Você não vê nem define a senha dela.',
                  style: TextStyle(color: ctx.cr.tintaSuave),
                ),
                const SizedBox(height: 16),
                TextField(controller: nomeCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome completo')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 12),
                SegmentedButton<TipoPerfil>(
                  segments: const [
                    ButtonSegment(value: TipoPerfil.funcionario, label: Text('Funcionário')),
                    ButtonSegment(value: TipoPerfil.gestor, label: Text('Gestor')),
                  ],
                  selected: {tipo},
                  onSelectionChanged: (s) => setModal(() => tipo = s.first),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Definir a senha agora', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Não envia o e-mail de convite'),
                  value: definirSenha,
                  onChanged: enviando
                      ? null
                      : (v) => setModal(() {
                    definirSenha = v;
                    erro = null;
                    if (!v) {
                      senhaCtrl.clear();
                      mostrarSenha = false;
                    }
                  }),
                ),
                if (definirSenha) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: senhaCtrl,
                    obscureText: !mostrarSenha,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Senha (mínimo 6 caracteres)',
                      suffixIcon: IconButton(
                        icon: Icon(mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setModal(() => mostrarSenha = !mostrarSenha),
                      ),
                    ),
                  ),
                ],
                if (erro != null) ...[
                  const SizedBox(height: 12),
                  Text(erro!, textAlign: TextAlign.center, style: TextStyle(color: ctx.cr.atraso, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () async {
                    final email = emailCtrl.text.trim();
                    if (nomeCtrl.text.trim().isEmpty || !email.contains('@') || !email.contains('.')) {
                      setModal(() => erro = 'Informe o nome e um e-mail válido.');
                      return;
                    }
                    if (definirSenha && senhaCtrl.text.length < 6) {
                      setModal(() => erro = 'Digite uma senha com pelo menos 6 caracteres ou desligue "Definir a senha agora".');
                      return;
                    }
                    setModal(() {
                      erro = null;
                      enviando = true;
                    });
                    final msg = await state.cadastrarUsuario(
                      nome: nomeCtrl.text,
                      email: email,
                      tipo: tipo,
                      senhaDefinida: definirSenha ? senhaCtrl.text : null,
                    );
                    if (msg == null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(definirSenha
                              ? 'Cadastro criado com a senha que você definiu. Passe a senha para $email entrar.'
                              : 'Cadastro criado. Enviamos um e-mail para $email definir a senha.'),
                        ));
                      }
                    } else {
                      setModal(() {
                        erro = msg;
                        enviando = false;
                      });
                    }
                  },
                  child: Text(enviando ? 'Cadastrando...' : (definirSenha ? 'Cadastrar com esta senha' : 'Cadastrar e enviar convite')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final c = context.cr;
    final eu = state.usuarioLogado;
    final lista = [...state.usuarios]..sort((a, b) {
      if (a.tipo != b.tipo) return a.tipo == TipoPerfil.gestor ? -1 : 1;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    final ativos = lista.where((u) => u.ativo).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Equipe')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCadastro(context, state),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Adicionar pessoa'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('$ativos ativos · ${lista.where((u) => u.tipo == TipoPerfil.gestor).length} gestor(es)', style: TextStyle(color: c.tintaSuave)),
          const SizedBox(height: 12),
          for (final u in lista)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: UserAvatar(fotoPath: u.fotoPath, nome: u.nome),
                title: Text(u.ativo ? u.nome : '${u.nome} (inativo)', style: TextStyle(fontWeight: FontWeight.w700, color: u.ativo ? null : c.tintaSuave)),
                subtitle: Text('${u.tipo == TipoPerfil.gestor ? 'Gestor' : 'Funcionário'} · ${u.username}${u.consentimentoEm == null && u.id != eu?.id ? ' · convite pendente' : ''}'),
                trailing: u.id == eu?.id
                    ? Text('Você', style: TextStyle(color: c.tintaSuave))
                    : PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'ativo') {
                      if (u.ativo && !await _confirmar(context, 'Desativar ${u.nome}?', 'A pessoa perde o acesso ao app. Você pode reativar depois.')) return;
                      state.definirAtivoUsuario(u.id, !u.ativo);
                    } else if (v == 'convite') {
                      final erro = await state.recuperarSenha(u.username);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro ?? 'Convite reenviado para ${u.username}.')));
                      }
                    } else if (v == 'tipo') {
                      final virar = u.tipo == TipoPerfil.gestor ? TipoPerfil.funcionario : TipoPerfil.gestor;
                      if (!await _confirmar(context, 'Mudar perfil?', '${u.nome} passa a ser ${virar == TipoPerfil.gestor ? 'gestor e vê os dados de todos' : 'funcionário'}.')) return;
                      state.definirTipoUsuario(u.id, virar);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'ativo', child: Text(u.ativo ? 'Desativar' : 'Reativar')),
                    if (u.consentimentoEm == null) const PopupMenuItem(value: 'convite', child: Text('Reenviar convite')),
                    PopupMenuItem(value: 'tipo', child: Text(u.tipo == TipoPerfil.gestor ? 'Tornar funcionário' : 'Tornar gestor')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}