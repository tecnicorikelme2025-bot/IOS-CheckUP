part of 'main.dart';


// ==========================================
// TELA 1: LISTA DE TAREFAS
// ==========================================

class MinhasTarefasScreen extends StatelessWidget {
  const MinhasTarefasScreen({super.key});

  void _exibirNotificacoes(BuildContext context, AppState state) {
    state.marcarNotificacoesComoLidas();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minhas Notificações'),
        content: SizedBox(
          width: double.maxFinite,
          child: state.notificacoesDoUsuario.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Nenhuma notificação recebida.'),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: state.notificacoesDoUsuario.length,
            itemBuilder: (context, i) {
              final notif = state.notificacoesDoUsuario[i];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.notifications_active, color: Colors.blue),
                title: Text(notif.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${notif.mensagem}\n${DateFormat('dd/MM HH:mm').format(notif.data)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('FECHAR')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final usuario = appState.usuarioLogado;
    final tarefas = appState.tarefasDoUsuario;
    final avisos = appState.avisos;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: UserAvatar(fotoPath: usuario?.fotoPath, nome: usuario?.nome ?? 'U', radius: 18),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario?.tipo == TipoPerfil.gestor ? 'Painel de Controle' : 'Minhas Tarefas', style: const TextStyle(fontSize: 18)),
            Text('Olá, ${usuario?.nome ?? ''}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notificações',
                onPressed: () => _exibirNotificacoes(context, appState),
              ),
              if (appState.qtdNotificacoesNaoLidas > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: context.cr.atraso, borderRadius: BorderRadius.circular(10)),
                    child: Text('${appState.qtdNotificacoesNaoLidas}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Mais opções',
            onSelected: (v) async {
              if (v == 'sync') {
                await appState.forcarSincronizacao();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados sincronizados com a nuvem')));
                }
              } else if (v == 'tema') {
                appState.alternarTemaDark(!appState.isDarkMode);
              } else if (v == 'assinatura') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AssinaturaFiscalScreen()));
              } else if (v == 'privacidade') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliticaPrivacidadeScreen()));
              } else if (v == 'texto') {
                appState.alternarEscalaTexto();
              } else if (v == 'sair') {
                await appState.fazerLogout();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'sync', child: ListTile(leading: Icon(Icons.sync_rounded), title: Text('Sincronizar'), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'tema', child: ListTile(leading: Icon(appState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined), title: Text(appState.isDarkMode ? 'Tema claro' : 'Tema escuro'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'assinatura', child: ListTile(leading: Icon(Icons.draw_outlined), title: Text('Assinatura do fiscal'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'texto', child: ListTile(leading: Icon(Icons.text_fields_rounded), title: Text('Tamanho do texto'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'privacidade', child: ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacidade e dados'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'sair', child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Sair'), contentPadding: EdgeInsets.zero)),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ResumoDoDia(
            concluidas: appState.totalConcluidas,
            total: tarefas.length,
            atrasadas: appState.totalAtrasadas,
          ),
          if (appState.pendentesSync > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.cr.reposicao.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.cloud_upload_outlined, color: context.cr.reposicao),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${appState.pendentesSync} alteração(ões) aguardando sincronização. Seu trabalho está salvo e será enviado quando a internet voltar.', style: const TextStyle(fontSize: 13))),
                ]),
              ),
            ),
          const SizedBox(height: 20),
          if (avisos.isNotEmpty) ...[
            const Text('Mural de avisos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...avisos.map((aviso) => Card(
              color: context.cr.reposicao.withOpacity(0.12),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.campaign_rounded, color: context.cr.reposicao),
                title: Text(aviso.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(aviso.mensagem),
              ),
            )),
            const SizedBox(height: 16),
          ],
          const Text('Paradas do dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('busca'),
            onChanged: appState.definirBusca,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Buscar por tarefa ou local'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Todas'), selected: appState.filtroTipo == null, onSelected: (_) => appState.definirFiltroTipo(null)),
              ChoiceChip(label: const Text('Reposição'), selected: appState.filtroTipo == TipoTarefa.reposicao, onSelected: (_) => appState.definirFiltroTipo(TipoTarefa.reposicao)),
              ChoiceChip(label: const Text('Limpeza'), selected: appState.filtroTipo == TipoTarefa.limpeza, onSelected: (_) => appState.definirFiltroTipo(TipoTarefa.limpeza)),
            ],
          ),
          const SizedBox(height: 12),
          if (tarefas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: Text('Nenhuma parada por aqui. Quando uma tarefa for atribuída, ela aparece nesta trilha.', textAlign: TextAlign.center, style: TextStyle(color: context.cr.tintaSuave))),
            )
          else
            ...(() {
              final ordenadas = [...tarefas.where((t) => (appState.filtroTipo == null || t.tipo == appState.filtroTipo) && (appState.busca.isEmpty || t.titulo.toLowerCase().contains(appState.busca) || t.local.toLowerCase().contains(appState.busca)))]..sort((x, y) => x.horarioPrevisto.compareTo(y.horarioPrevisto));
              return [for (var i = 0; i < ordenadas.length; i++) CardTarefa(tarefa: ordenadas[i], ultima: i == ordenadas.length - 1)];
            })(),
        ],
      ),
    );
  }
}


class ResumoDoDia extends StatelessWidget {
  final int concluidas, total, atrasadas;
  const ResumoDoDia({super.key, required this.concluidas, required this.total, required this.atrasadas});

  @override
  Widget build(BuildContext context) {
    final c = context.cr;
    final progresso = total == 0 ? 0.0 : concluidas / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.tinta, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          SizedBox(
            width: 92, height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92, height: 92,
                  child: CircularProgressIndicator(
                    value: progresso, strokeWidth: 10, strokeCap: StrokeCap.round,
                    backgroundColor: c.fundo.withOpacity(0.18), color: c.limpeza,
                  ),
                ),
                Text('${(progresso * 100).round()}%', style: TextStyle(color: c.fundo, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$concluidas de $total', style: TextStyle(color: c.fundo, fontSize: 30, fontWeight: FontWeight.w800, height: 1.0)),
                const SizedBox(height: 6),
                Text(total == 0 ? 'Sem paradas hoje' : 'paradas concluídas', style: TextStyle(color: c.fundo.withOpacity(0.75), fontSize: 14)),
                if (atrasadas > 0) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.schedule_rounded, size: 16, color: c.atraso),
                    const SizedBox(width: 6),
                    Text('$atrasadas em atraso', style: TextStyle(color: c.atraso, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class CardTarefa extends StatelessWidget {
  final Tarefa tarefa;
  final bool ultima;
  const CardTarefa({super.key, required this.tarefa, this.ultima = false});

  @override
  Widget build(BuildContext context) {
    final c = context.cr;
    final appState = Provider.of<AppState>(context, listen: false);
    final bool isGestor = appState.usuarioLogado?.tipo == TipoPerfil.gestor;
    final respUser = appState.getUsuarioPorId(tarefa.idResponsavel);
    final bool repo = tarefa.tipo == TipoTarefa.reposicao;
    final Color corTipo = repo ? c.reposicao : c.limpeza;
    final bool feita = tarefa.status == StatusTarefa.concluida;
    final bool atrasada = tarefa.statusEfetivo == StatusTarefa.atrasada;
    final Color corNo = feita ? c.ok : (atrasada ? c.atraso : c.tintaSuave);
    final String rotuloStatus = feita ? 'Concluída' : (atrasada ? 'Em atraso' : 'Pendente');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(DateFormat('HH:mm').format(tarefa.horarioPrevisto), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.tinta)),
            ),
          ),
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: feita ? c.ok : c.fundo,
                    border: Border.all(color: corNo, width: 2.5),
                  ),
                  child: feita
                      ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                      : (atrasada ? Icon(Icons.priority_high_rounded, size: 15, color: c.atraso) : null),
                ),
                if (!ultima) Expanded(child: Container(width: 2.5, color: c.linha)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultima ? 0 : 14),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExecucaoTarefaScreen(tarefa: tarefa))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: corTipo.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(repo ? Icons.inventory_2_rounded : Icons.cleaning_services_rounded, size: 14, color: corTipo),
                                const SizedBox(width: 6),
                                Text(repo ? 'Reposição' : 'Limpeza', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: corTipo)),
                              ]),
                            ),
                            const Spacer(),
                            Text(rotuloStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: corNo)),
                            if (isGestor)
                              SizedBox(
                                width: 32,
                                height: 24,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.more_vert_rounded, size: 20, color: c.tintaSuave),
                                  onSelected: (v) async {
                                    if (v == 'editar') {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => CriarTarefaScreen(tarefa: tarefa)));
                                      return;
                                    }
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Excluir tarefa?'),
                                        content: Text('${tarefa.titulo} será removida para todos. Essa ação não pode ser desfeita.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                                        ],
                                      ),
                                    );
                                    if (ok == true) appState.excluirTarefa(tarefa.id);
                                  },
                                  itemBuilder: (_) => [
                                    if (!feita) const PopupMenuItem(value: 'editar', child: Text('Editar tarefa')),
                                    const PopupMenuItem(value: 'excluir', child: Text('Excluir tarefa')),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(tarefa.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.place_outlined, size: 16, color: c.tintaSuave),
                          const SizedBox(width: 4),
                          Expanded(child: Text(tarefa.local, style: TextStyle(color: c.tintaSuave))),
                        ]),
                        if (isGestor) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            UserAvatar(fotoPath: respUser?.fotoPath, nome: respUser?.nome ?? 'U', radius: 10),
                            const SizedBox(width: 6),
                            Expanded(child: Text(respUser?.nome ?? 'Não atribuído', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                        ],
                        if (tarefa.latitudeCheckin != null) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.gps_fixed_rounded, size: 14, color: c.ok),
                            const SizedBox(width: 6),
                            Text('Local confirmado por GPS', style: TextStyle(fontSize: 12, color: c.ok, fontWeight: FontWeight.w700)),
                          ]),
                        ],
                        if (feita && tarefa.duracao != null) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.timer_outlined, size: 14, color: c.tintaSuave),
                            const SizedBox(width: 6),
                            Text('Executada em ${formatarDuracao(tarefa.duracao!)}', style: TextStyle(fontSize: 12, color: c.tintaSuave)),
                          ]),
                        ],
                        if (!feita) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExecucaoTarefaScreen(tarefa: tarefa))),
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text('Iniciar check-in'),
                            ),
                          ),
                        ],
                      ],
                    ),
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


// ==========================================
// FORMULÁRIO DE CRIAR TAREFA
// ==========================================

class CriarTarefaScreen extends StatefulWidget {
  final Tarefa? tarefa;
  const CriarTarefaScreen({super.key, this.tarefa});

  @override
  State<CriarTarefaScreen> createState() => _CriarTarefaScreenState();
}


class _CriarTarefaScreenState extends State<CriarTarefaScreen> {
  final _tituloController = TextEditingController();
  final _localController = TextEditingController();
  final _itemChecklistController = TextEditingController();

  TipoTarefa _tipoSelecionado = TipoTarefa.reposicao;
  String? _idResponsavelSelecionado;
  String? _idLocalSelecionado;
  final List<ItemChecklist> _itensChecklist = [];
  TimeOfDay _horarioSelecionado = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    if (t != null) {
      final state = Provider.of<AppState>(context, listen: false);
      _tituloController.text = t.titulo;
      _tipoSelecionado = t.tipo;
      _horarioSelecionado = TimeOfDay.fromDateTime(t.horarioPrevisto);
      _itensChecklist.addAll(t.checklist.map((i) => ItemChecklist(titulo: i.titulo)));
      if (state.usuarios.any((u) => u.id == t.idResponsavel && u.tipo == TipoPerfil.funcionario)) {
        _idResponsavelSelecionado = t.idResponsavel;
      }
      final i = state.locais.indexWhere((l) => l.nome == t.local);
      if (i >= 0) _idLocalSelecionado = state.locais[i].id;
    }
  }

  void _exibirNotificacaoLocalCelular(String titulo, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(mensagem, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: CrTheme.marcaForte,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final funcionarios = appState.usuarios.where((u) => u.tipo == TipoPerfil.funcionario && u.ativo).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.tarefa == null ? 'Cadastrar Nova Tarefa' : 'Editar Tarefa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tituloController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título da Tarefa', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _idLocalSelecionado,
              hint: Text(appState.locais.isEmpty ? 'Cadastre um local no Painel antes' : 'Selecione o local'),
              decoration: const InputDecoration(labelText: 'Local', border: OutlineInputBorder()),
              items: appState.locais.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome))).toList(),
              onChanged: (val) => setState(() => _idLocalSelecionado = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TipoTarefa>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(labelText: 'Tipo de Atividade', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: TipoTarefa.reposicao, child: Text('Reposição de Mercadorias')),
                DropdownMenuItem(value: TipoTarefa.limpeza, child: Text('Serviço de Limpeza')),
              ],
              onChanged: (val) => setState(() => _tipoSelecionado = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _idResponsavelSelecionado,
              hint: const Text('Selecione o Funcionário Responsável'),
              decoration: const InputDecoration(labelText: 'Atribuir a:', border: OutlineInputBorder()),
              items: funcionarios.map((f) {
                return DropdownMenuItem(
                  value: f.id,
                  child: Row(
                    children: [
                      UserAvatar(fotoPath: f.fotoPath, nome: f.nome, radius: 12),
                      const SizedBox(width: 8),
                      Text(f.nome),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _idResponsavelSelecionado = val),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: Text('Horário Previsto: ${_horarioSelecionado.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _horarioSelecionado);
                if (time != null) setState(() => _horarioSelecionado = time);
              },
            ),
            const SizedBox(height: 20),
            const Text('Checklist da Tarefa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemChecklistController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Adicionar sub-tarefa', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_itemChecklistController.text.isNotEmpty) {
                      setState(() {
                        _itensChecklist.add(ItemChecklist(titulo: _itemChecklistController.text));
                        _itemChecklistController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            ..._itensChecklist.map((item) => ListTile(dense: true, leading: const Icon(Icons.check, size: 18), title: Text(item.titulo))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  if (_tituloController.text.isEmpty || _idLocalSelecionado == null || _idResponsavelSelecionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios!')));
                    return;
                  }
                  final agora = DateTime.now();
                  final localEscolhido = appState.locais.firstWhere((l) => l.id == _idLocalSelecionado);
                  final respUser = appState.getUsuarioPorId(_idResponsavelSelecionado!);

                  if (widget.tarefa != null) {
                    final t0 = widget.tarefa!.horarioPrevisto;
                    appState.atualizarTarefa(
                      widget.tarefa!,
                      titulo: _tituloController.text,
                      local: localEscolhido,
                      tipo: _tipoSelecionado,
                      horario: DateTime(t0.year, t0.month, t0.day, _horarioSelecionado.hour, _horarioSelecionado.minute),
                      idResponsavel: _idResponsavelSelecionado!,
                      checklist: _itensChecklist.isNotEmpty ? _itensChecklist : [ItemChecklist(titulo: 'Verificação padrão')],
                    );
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }
                  await appState.adicionarTarefa(Tarefa(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titulo: _tituloController.text,
                    local: localEscolhido.nome,
                    qrCodeEsperado: localEscolhido.codigoQr,
                    latitudeLocal: localEscolhido.latitude,
                    longitudeLocal: localEscolhido.longitude,
                    tipo: _tipoSelecionado,
                    horarioPrevisto: DateTime(agora.year, agora.month, agora.day, _horarioSelecionado.hour, _horarioSelecionado.minute),
                    idResponsavel: _idResponsavelSelecionado!,
                    checklist: _itensChecklist.isNotEmpty ? _itensChecklist : [ItemChecklist(titulo: 'Verificação padrão')],
                  ));

                  if (context.mounted) {
                    Navigator.pop(context);
                    _exibirNotificacaoLocalCelular('Notificação Enviada!', 'Atividade enviada para ${respUser?.nome ?? "o funcionário"}.');
                  }
                },
                child: Text(widget.tarefa == null ? 'SALVAR E ATRIBUIR TAREFA' : 'SALVAR ALTERAÇÕES', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// LEITOR DE QR CODE VIA CÂMERA
// ==========================================

class LeitorQrCodeScreen extends StatefulWidget {
  final String qrCodeEsperado;
  final String localNome;

  const LeitorQrCodeScreen({super.key, required this.qrCodeEsperado, required this.localNome});

  @override
  State<LeitorQrCodeScreen> createState() => _LeitorQrCodeScreenState();
}


class _LeitorQrCodeScreenState extends State<LeitorQrCodeScreen> {
  bool _processando = false;
  late MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Validar: ${widget.localNome}')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_processando) return;
              for (final barcode in capture.barcodes) {
                final String? valorLido = barcode.rawValue;
                if (valorLido != null && valorLido.isNotEmpty) {
                  setState(() => _processando = true);
                  if (valorLido.trim().toUpperCase() == widget.qrCodeEsperado.trim().toUpperCase()) {
                    Navigator.pop(context, true);
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('QR Code Incorreto'),
                        content: Text('Esse QR Code não é do local "${widget.localNome}". Confira se está no lugar certo.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() => _processando = false);
                            },
                            child: const Text('Tentar Novamente'),
                          )
                        ],
                      ),
                    );
                  }
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 3), borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}


// ==========================================
// TELA DE EXECUÇÃO DA TAREFA COMPLETA
// ==========================================

class ExecucaoTarefaScreen extends StatefulWidget {
  final Tarefa tarefa;
  const ExecucaoTarefaScreen({super.key, required this.tarefa});

  @override
  State<ExecucaoTarefaScreen> createState() => _ExecucaoTarefaScreenState();
}


class _ExecucaoTarefaScreenState extends State<ExecucaoTarefaScreen> {
  bool _qrValido = false;
  DateTime? _inicio;
  String? _fotoAntesPath;
  String? _fotoDepoisPath;
  bool _produtoEmFalta = false;
  double? _latitude;
  double? _longitude;
  final TextEditingController _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tarefa.status == StatusTarefa.concluida) {
      _qrValido = true;
      _fotoAntesPath = widget.tarefa.fotoAntesPath;
      _fotoDepoisPath = widget.tarefa.fotoDepoisPath;
      _produtoEmFalta = widget.tarefa.produtoEmFalta;
      _obsController.text = widget.tarefa.observacao ?? '';
    }
  }

  Future<void> _capturarGpsEValidar() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ative o GPS do celular!')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (position.isMocked) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localização simulada detectada. Desative o app de GPS falso e tente de novo.')));
        }
        return;
      }
      final latLocal = widget.tarefa.latitudeLocal;
      final lngLocal = widget.tarefa.longitudeLocal;
      if (latLocal != null && lngLocal != null) {
        final dist = Geolocator.distanceBetween(position.latitude, position.longitude, latLocal, lngLocal);
        final limite = 100 + position.accuracy.clamp(0.0, 50.0);
        if (dist > limite) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Você está a ${dist.round()} m do local. Chegue a até 100 m para fazer o check-in.')));
          }
          return;
        }
      }
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      if (widget.tarefa.latitudeLocal != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível obter sua localização. Tente de novo.')));
        }
        return;
      }
    }

    if (!mounted) return;
    final bool? valido = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LeitorQrCodeScreen(qrCodeEsperado: widget.tarefa.qrCodeEsperado, localNome: widget.tarefa.local)),
    );

    if (valido == true) {
      setState(() {
        _qrValido = true;
        _inicio = DateTime.now();
      });
    }
  }

  Future<void> _tirarFoto(bool antes) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          if (antes) {
            _fotoAntesPath = image.path;
          } else {
            _fotoDepoisPath = image.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir a câmera: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool modoApenasLeitura = widget.tarefa.status == StatusTarefa.concluida;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tarefa.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _qrValido ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _qrValido ? Colors.green : Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(_qrValido ? Icons.check_circle : Icons.warning_amber, color: _qrValido ? Colors.green : Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _qrValido ? 'Local validado com sucesso!' : 'Escaneie o QR Code do local para liberar as atividades.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_qrValido && !modoApenasLeitura) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: CrTheme.marcaForte, foregroundColor: Colors.white),
                  onPressed: _capturarGpsEValidar,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('ESCANEAR QR CODE COM CÂMERA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Checklist de Atividades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.tarefa.checklist.map((item) => CheckboxListTile(
              title: Text(item.titulo),
              value: item.concluido,
              enabled: _qrValido && !modoApenasLeitura,
              onChanged: (val) => setState(() => item.concluido = val ?? false),
            )),
            const Divider(height: 32),
            const Text('Comprovação por Foto (Câmera)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFotoButton(
                    rotulo: 'Foto Antes',
                    fotoPath: _fotoAntesPath,
                    desabilitado: !_qrValido || modoApenasLeitura,
                    onTap: () => _tirarFoto(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFotoButton(
                    rotulo: 'Foto Depois',
                    fotoPath: _fotoDepoisPath,
                    desabilitado: !_qrValido || modoApenasLeitura,
                    onTap: () => _tirarFoto(false),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (widget.tarefa.tipo == TipoTarefa.reposicao) ...[
              SwitchListTile(
                title: const Text('Produto em falta / Estoque Baixo'),
                subtitle: const Text('Gera alerta automático para compras'),
                value: _produtoEmFalta,
                activeColor: Colors.red,
                onChanged: modoApenasLeitura || !_qrValido ? null : (val) => setState(() => _produtoEmFalta = val),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _obsController,
              enabled: _qrValido && !modoApenasLeitura,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Observações / Ocorrências', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            if (!modoApenasLeitura)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _qrValido
                      ? () async {
                    final completo = widget.tarefa.checklist.every((i) => i.concluido) &&
                        (_fotoAntesPath?.isNotEmpty ?? false) &&
                        (_fotoDepoisPath?.isNotEmpty ?? false);
                    if (!completo) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marque todos os itens do checklist e tire as fotos de antes e depois.')));
                      return;
                    }
                    await Provider.of<AppState>(context, listen: false).concluirTarefa(
                      id: widget.tarefa.id,
                      checklist: widget.tarefa.checklist,
                      inicio: _inicio,
                      fotoAntesPath: _fotoAntesPath,
                      fotoDepoisPath: _fotoDepoisPath,
                      produtoEmFalta: _produtoEmFalta,
                      obs: _obsController.text,
                      lat: _latitude,
                      lng: _longitude,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarefa finalizada com sucesso!')));
                    }
                  }
                      : null,
                  child: const Text('FINALIZAR E REGISTRAR CHECK-IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoButton({required String rotulo, required String? fotoPath, required bool desabilitado, required VoidCallback onTap}) {
    final bool feita = fotoPath != null && fotoPath.isNotEmpty;
    final c = context.cr;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: feita && desabilitado
          ? () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(height: 420, child: FotoComprovacao(caminho: fotoPath, fit: BoxFit.contain)),
                ),
              )
          : (desabilitado ? null : onTap),
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.superficie,
          border: Border.all(color: feita ? c.ok : c.linha, width: feita ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: feita
            ? Stack(
                fit: StackFit.expand,
                children: [
                  FotoComprovacao(caminho: fotoPath),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Text(rotulo, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(radius: 12, backgroundColor: c.ok, child: const Icon(Icons.check_rounded, size: 16, color: Colors.white)),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_outlined, size: 28, color: c.tintaSuave),
                  const SizedBox(height: 4),
                  Text(rotulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Toque para fotografar', style: TextStyle(fontSize: 11, color: c.tintaSuave)),
                ],
              ),
      ),
    );
  }
}


/// Mostra a foto de comprovação, venha ela do Firestore ('foto:ID'), da internet ou do celular.
class FotoComprovacao extends StatelessWidget {
  final String? caminho;
  final BoxFit fit;
  const FotoComprovacao({super.key, required this.caminho, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final c = caminho;
    if (c == null || c.isEmpty) return const SizedBox.shrink();
    if (c.startsWith('foto:')) {
      final state = Provider.of<AppState>(context, listen: false);
      return FutureBuilder<Uint8List?>(
        future: state.buscarFoto(c),
        initialData: state.fotoEmCache(c),
        builder: (_, snap) => snap.data != null
            ? Image.memory(snap.data!, fit: fit, width: double.infinity, height: double.infinity, gaplessPlayback: true)
            : Center(
                child: snap.connectionState == ConnectionState.done
                    ? const Icon(Icons.broken_image_outlined)
                    : const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
      );
    }
    if (c.startsWith('http')) return Image.network(c, fit: fit, width: double.infinity, height: double.infinity);
    return Image.file(File(c), fit: fit, width: double.infinity, height: double.infinity);
  }
}
