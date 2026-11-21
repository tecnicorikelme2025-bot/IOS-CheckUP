part of 'main.dart';


// ==========================================
// NAVEGAÇÃO PRINCIPAL (SEPARADA POR PERFIL)
// ==========================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}


class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _abaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isGestor = appState.usuarioLogado?.tipo == TipoPerfil.gestor;
    if (appState.usuarioLogado != null && appState.usuarioLogado!.consentimentoEm == null) {
      return const ConsentimentoLgpdScreen();
    }

    final List<Widget> telas = isGestor
        ? const [
      MinhasTarefasScreen(),
      OcorrenciasScreen(),
      PainelGestorScreen(),
    ]
        : const [
      MinhasTarefasScreen(),
      OcorrenciasScreen(),
    ];

    return Scaffold(
      body: telas[_abaSelecionada >= telas.length ? 0 : _abaSelecionada],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaSelecionada >= telas.length ? 0 : _abaSelecionada,
        onDestinationSelected: (index) => setState(() => _abaSelecionada = index),
        destinations: isGestor
            ? const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tarefas Gerais',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Ocorrências',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Painel Gestor',
          ),
        ]
            : const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Minhas Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Ocorrências',
          ),
        ],
      ),
      floatingActionButton: (isGestor && _abaSelecionada == 0)
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CriarTarefaScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      )
          : null,
    );
  }
}


class UserAvatar extends StatelessWidget {
  final String? fotoPath;
  final String nome;
  final double radius;

  const UserAvatar({super.key, this.fotoPath, required this.nome, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final inicial = Text(nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : 'U');
    final caminho = fotoPath;
    if (caminho != null && caminho.isNotEmpty) {
      if (caminho.startsWith('foto:')) {
        final state = Provider.of<AppState>(context, listen: false);
        return FutureBuilder<Uint8List?>(
          future: state.buscarFoto(caminho),
          initialData: state.fotoEmCache(caminho),
          builder: (_, snap) => CircleAvatar(
            radius: radius,
            backgroundImage: snap.data != null ? MemoryImage(snap.data!) : null,
            child: snap.data == null ? inicial : null,
          ),
        );
      }
      if (caminho.startsWith('http')) {
        return CircleAvatar(radius: radius, backgroundImage: NetworkImage(caminho));
      }
      return CircleAvatar(radius: radius, backgroundImage: FileImage(File(caminho)));
    }
    return CircleAvatar(radius: radius, child: inicial);
  }
}
