part of 'main.dart';


// ==========================================
// TELA 2: CENTRAL DE OCORRÊNCIAS
// ==========================================

class OcorrenciasScreen extends StatefulWidget {
  const OcorrenciasScreen({super.key});

  @override
  State<OcorrenciasScreen> createState() => _OcorrenciasScreenState();
}


class _OcorrenciasScreenState extends State<OcorrenciasScreen> {
  StatusOcorrencia? _filtro;

  Color _corPrioridade(BuildContext ctx, PrioridadeOcorrencia p) {
    final c = ctx.cr;
    return switch (p) {
      PrioridadeOcorrencia.alta => c.atraso,
      PrioridadeOcorrencia.media => c.reposicao,
      PrioridadeOcorrencia.baixa => c.limpeza,
    };
  }

  /// Botão de filtro compacto, para os quatro caberem na mesma linha.
  Widget _chipFiltro(String rotulo, bool selecionado, VoidCallback aoTocar) {
    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      onSelected: (_) => aoTocar(),
    );
  }

  void _abrirModalNovaOcorrencia(BuildContext context) {
    final state0 = Provider.of<AppState>(context, listen: false);
    final tituloCtrl = TextEditingController();
    final localCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var prioridade = PrioridadeOcorrencia.media;
    String? fotoPath;
    String? idTarefa;
    String? erro;
    final tarefasOpcoes = ([...state0.tarefasDoUsuario]..sort((a, b) => b.horarioPrevisto.compareTo(a.horarioPrevisto))).take(20).toList();

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
                const Text('Registrar ocorrência', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: tituloCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Título do problema')),
                const SizedBox(height: 12),
                const Text('Prioridade', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SegmentedButton<PrioridadeOcorrencia>(
                  segments: const [
                    ButtonSegment(value: PrioridadeOcorrencia.baixa, label: Text('Baixa')),
                    ButtonSegment(value: PrioridadeOcorrencia.media, label: Text('Média')),
                    ButtonSegment(value: PrioridadeOcorrencia.alta, label: Text('Alta')),
                  ],
                  selected: {prioridade},
                  onSelectionChanged: (s) => setModal(() => prioridade = s.first),
                ),
                const SizedBox(height: 12),
                if (tarefasOpcoes.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: idTarefa,
                    isExpanded: true,
                    hint: const Text('Tarefa relacionada (opcional)'),
                    decoration: const InputDecoration(labelText: 'Tarefa'),
                    items: tarefasOpcoes.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.titulo} · ${t.local}', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setModal(() {
                      idTarefa = v;
                      final t = tarefasOpcoes.firstWhere((x) => x.id == v);
                      if (localCtrl.text.trim().isEmpty) localCtrl.text = t.local;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(controller: localCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Local (Ex: Corredor 3)')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Descrição detalhada')),
                const SizedBox(height: 12),
                if (fotoPath != null)
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 140, child: Image.file(File(fotoPath!), fit: BoxFit.cover))),
                OutlinedButton.icon(
                  onPressed: () async {
                    final f = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 50);
                    if (f != null) setModal(() => fotoPath = f.path);
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(fotoPath == null ? 'Anexar foto' : 'Trocar foto'),
                ),
                if (erro != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(erro!, style: TextStyle(color: ctx.cr.atraso, fontWeight: FontWeight.w700))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (tituloCtrl.text.trim().isEmpty || localCtrl.text.trim().isEmpty) {
                      setModal(() => erro = 'Preencha o título e o local.');
                      return;
                    }
                    final foto = await state0.enviarFoto(fotoPath, 'ocorrencias');
                    final i = tarefasOpcoes.indexWhere((t) => t.id == idTarefa);
                    state0.adicionarOcorrencia(Ocorrencia(
                      id: 'oc_${DateTime.now().millisecondsSinceEpoch}',
                      titulo: tituloCtrl.text.trim(),
                      descricao: descCtrl.text.trim(),
                      local: localCtrl.text.trim(),
                      autorNome: state0.usuarioLogado?.nome ?? 'Funcionário',
                      idAutor: state0.usuarioLogado?.id ?? '',
                      fotoPath: foto,
                      prioridade: prioridade,
                      idTarefa: i >= 0 ? tarefasOpcoes[i].id : null,
                      tarefaTitulo: i >= 0 ? tarefasOpcoes[i].titulo : null,
                      dataAbertura: DateTime.now(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocorrência aberta com sucesso!')));
                    }
                  },
                  child: const Text('Enviar chamado'),
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
    final isGestor = state.usuarioLogado?.tipo == TipoPerfil.gestor;
    final todas = [...state.ocorrencias]..sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));
    final lista = todas.where((o) => _filtro == null || o.status == _filtro).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências e manutenção')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          // Os quatro filtros ficam sempre na mesma linha. Se a tela for muito
          // estreita (ou o texto estiver ampliado), a linha inteira diminui um pouco.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _chipFiltro('Todas', _filtro == null, () => setState(() => _filtro = null)),
                for (final s in StatusOcorrencia.values) ...[
                  const SizedBox(width: 4),
                  _chipFiltro(rotuloStatusOcorrencia(s), _filtro == s, () => setState(() => _filtro = s)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Nenhuma ocorrência por aqui.', style: TextStyle(color: c.tintaSuave)))),
          for (final oc in lista)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _corPrioridade(context, oc.prioridade).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text('Prioridade ${rotuloPrioridade(oc.prioridade).toLowerCase()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _corPrioridade(context, oc.prioridade))),
                      ),
                      const Spacer(),
                      Text(rotuloStatusOcorrencia(oc.status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: oc.status == StatusOcorrencia.resolvida ? c.ok : c.tintaSuave)),
                      if (isGestor)
                        SizedBox(
                          width: 32,
                          height: 24,
                          child: PopupMenuButton<StatusOcorrencia>(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_vert_rounded, size: 20, color: c.tintaSuave),
                            onSelected: (s) => state.atualizarStatusOcorrencia(oc.id, s),
                            itemBuilder: (_) => [for (final s in StatusOcorrencia.values) PopupMenuItem(value: s, child: Text(rotuloStatusOcorrencia(s)))],
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Text(oc.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${oc.local} · ${oc.autorNome} · ${DateFormat('dd/MM HH:mm').format(oc.dataAbertura)}', style: TextStyle(fontSize: 12, color: c.tintaSuave)),
                    if (oc.descricao.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(oc.descricao)),
                    if (oc.tarefaTitulo != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Tarefa relacionada: ${oc.tarefaTitulo}', style: TextStyle(fontSize: 12, color: c.tintaSuave))),
                    if (oc.fotoPath != null && oc.fotoPath!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(clipBehavior: Clip.antiAlias, child: SizedBox(height: 420, child: FotoComprovacao(caminho: oc.fotoPath, fit: BoxFit.contain))),
                          ),
                          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 140, width: double.infinity, child: FotoComprovacao(caminho: oc.fotoPath))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalNovaOcorrencia(context),
        icon: const Icon(Icons.add_alert),
        label: const Text('Nova ocorrência'),
      ),
    );
  }
}