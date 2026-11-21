part of 'main.dart';



// ==========================================
// RONDAS RECORRENTES (gestor)
// ==========================================
class RondasRecorrentesScreen extends StatelessWidget {
  const RondasRecorrentesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final c = context.cr;
    const nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Scaffold(
      appBar: AppBar(title: const Text('Rondas recorrentes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovaRondaScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova ronda'),
      ),
      body: state.modelos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Crie uma ronda para a tarefa aparecer sozinha nos dias escolhidos.', textAlign: TextAlign.center, style: TextStyle(color: c.tintaSuave)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: state.modelos.map((m) {
                final dias = m.dias.toList()..sort();
                final quem = state.getUsuarioPorId(m.idResponsavel)?.nome ?? 'Sem responsável';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(m.titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${m.hora.toString().padLeft(2, '0')}:${m.minuto.toString().padLeft(2, '0')} · ${dias.map((d) => nomesDias[d - 1]).join(', ')}\n${m.localNome} · $quem'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(value: m.ativo, onChanged: (v) => state.alternarModelo(m.id, v)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir ronda?'),
                                content: const Text('As próximas tarefas deixam de ser criadas. As já criadas continuam.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                                ],
                              ),
                            );
                            if (ok == true) state.excluirModelo(m.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}


class NovaRondaScreen extends StatefulWidget {
  const NovaRondaScreen({super.key});

  @override
  State<NovaRondaScreen> createState() => _NovaRondaScreenState();
}


class _NovaRondaScreenState extends State<NovaRondaScreen> {
  final _tituloCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  String? _idLocal;
  String? _idResp;
  TipoTarefa _tipo = TipoTarefa.limpeza;
  TimeOfDay _hora = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _dias = {1, 2, 3, 4, 5};
  final List<String> _itens = [];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final funcionarios = state.usuarios.where((u) => u.tipo == TipoPerfil.funcionario && u.ativo).toList();
    const nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Scaffold(
      appBar: AppBar(title: const Text('Nova ronda recorrente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _tituloCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Título (Ex: Limpeza do corredor 4)')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _idLocal,
              hint: Text(state.locais.isEmpty ? 'Cadastre um local no Painel antes' : 'Selecione o local'),
              decoration: const InputDecoration(labelText: 'Local'),
              items: state.locais.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome))).toList(),
              onChanged: (v) => setState(() => _idLocal = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TipoTarefa>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de atividade'),
              items: const [
                DropdownMenuItem(value: TipoTarefa.reposicao, child: Text('Reposição de mercadorias')),
                DropdownMenuItem(value: TipoTarefa.limpeza, child: Text('Serviço de limpeza')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _idResp,
              hint: const Text('Selecione o funcionário'),
              decoration: const InputDecoration(labelText: 'Responsável'),
              items: funcionarios.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nome))).toList(),
              onChanged: (v) => setState(() => _idResp = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Horário: ${_hora.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _hora);
                if (t != null) setState(() => _hora = t);
              },
            ),
            const Text('Repetir em', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(nomesDias[i]),
                    selected: _dias.contains(i + 1),
                    onSelected: (s) => setState(() {
                      if (s) {
                        _dias.add(i + 1);
                      } else {
                        _dias.remove(i + 1);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Checklist', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _itemCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Adicionar item'))),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_itemCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _itens.add(_itemCtrl.text.trim());
                      _itemCtrl.clear();
                    });
                  },
                ),
              ],
            ),
            ..._itens.asMap().entries.map((e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check, size: 18),
                  title: Text(e.value),
                  trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _itens.removeAt(e.key))),
                )),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_tituloCtrl.text.trim().isEmpty || _idLocal == null || _idResp == null || _dias.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha título, local, responsável e ao menos um dia.')));
                    return;
                  }
                  final local = state.locais.firstWhere((l) => l.id == _idLocal);
                  state.salvarModelo(ModeloRonda(
                    id: 'rd_${DateTime.now().millisecondsSinceEpoch}',
                    titulo: _tituloCtrl.text.trim(),
                    localNome: local.nome,
                    codigoQr: local.codigoQr,
                    latitudeLocal: local.latitude,
                    longitudeLocal: local.longitude,
                    idResponsavel: _idResp!,
                    tipo: _tipo,
                    hora: _hora.hour,
                    minuto: _hora.minute,
                    dias: _dias.toList()..sort(),
                    checklist: _itens.isNotEmpty ? _itens : ['Verificação padrão'],
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ronda criada. A tarefa aparece nos dias escolhidos.')));
                },
                child: const Text('Salvar ronda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// LISTA DE REPOSIÇÃO (produtos em falta)
// ==========================================
class ListaReposicaoScreen extends StatelessWidget {
  const ListaReposicaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final c = context.cr;
    final itens = state.tarefasDoUsuario.where((t) => t.produtoEmFalta).toList()
      ..sort((a, b) => (b.horarioConclusao ?? b.horarioPrevisto).compareTo(a.horarioConclusao ?? a.horarioPrevisto));

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de reposição')),
      body: itens.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Nenhum produto em falta no momento.', style: TextStyle(color: c.tintaSuave))))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = itens[i];
                final quem = state.getUsuarioPorId(t.idResponsavel)?.nome ?? 'Funcionário';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.inventory_2_rounded, color: c.reposicao),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t.local, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                        ]),
                        if (t.observacao != null && t.observacao!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.observacao!)),
                        const SizedBox(height: 8),
                        Text('$quem · ${DateFormat('dd/MM HH:mm').format(t.horarioConclusao ?? t.horarioPrevisto)}', style: TextStyle(fontSize: 12, color: c.tintaSuave)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => state.marcarComoReposto(t.id),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Marcar como reposto'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
