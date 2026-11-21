part of 'main.dart';


// ==========================================
// GERENCIAMENTO DE ESTADO E FIRESTORE EM TEMPO REAL
// ==========================================

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'checkronda-34b28',
  );

  bool _carregandoSessao = true;
  bool get carregandoSessao => _carregandoSessao;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _sincronizando = false;
  bool get sincronizando => _sincronizando;

  List<Usuario> usuarios = [];
  Usuario? _usuarioLogado;
  Usuario? get usuarioLogado => _usuarioLogado;

  /// Organização (empresa) a que o usuário logado pertence. Todos os dados de trabalho ficam em
  /// organizacoes/{orgId}/..., então uma empresa nunca enxerga os dados de outra.
  String? _orgId;
  String? get orgId => _orgId;

  /// Coleção dentro do espaço da organização do usuário logado.
  CollectionReference<Map<String, dynamic>> _col(String nome) =>
      _firestore.collection('organizacoes').doc(_orgId ?? '_semorg').collection(nome);
  List<Offset?> _pontosAssinatura = [];

  List<Offset?> get pontosAssinatura => _pontosAssinatura;

  List<NotificacaoUsuario> _notificacoes = [];

  List<NotificacaoUsuario> get notificacoesDoUsuario {
    if (_usuarioLogado == null) return [];
    if (_usuarioLogado!.tipo == TipoPerfil.gestor) {
      return _notificacoes.where((n) => n.idUsuario == _usuarioLogado!.id || n.idUsuario == 'GESTOR_GERAL').toList();
    }
    return _notificacoes.where((n) => n.idUsuario == _usuarioLogado!.id).toList();
  }

  int get qtdNotificacoesNaoLidas => notificacoesDoUsuario.where((n) => !n.lida).length;

  Future<void> forcarSincronizacao() async {
    _sincronizando = true;
    notifyListeners();

    try {
      await _firestore.waitForPendingWrites().timeout(const Duration(seconds: 10));
      if (_usuarioLogado != null) _ouvirTudo();
    } catch (_) {}

    _sincronizando = false;
    notifyListeners();
  }

  Future<void> marcarNotificacoesComoLidas() async {
    for (var n in notificacoesDoUsuario) {
      if (!n.lida) {
        n.lida = true;
        await _col('notificacoes').doc(n.id).update({'lida': true});
      }
    }
    notifyListeners();
  }

  Future<void> alternarTemaDark(bool valor) async {
    _isDarkMode = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', valor);
    notifyListeners();
  }

  final List<StreamSubscription> _subs = [];
  StreamSubscription<User?>? _authSub;
  bool _criandoConta = false;

  void _cancelarEscutas() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _limparSessaoLocal() {
    _cancelarEscutas();
    _usuarioLogado = null;
    _orgId = null;
    usuarios = [];
    _tarefas = [];
    _ocorrencias = [];
    _avisos = [];
    _notificacoes = [];
    _locais = [];
    _modelos = [];
    _pendTarefas = 0;
    _pendOcorrencias = 0;
    NotificacoesLocais.cancelarTudo();
  }

  void _ouvirTudo() {
    _cancelarEscutas();
    _notifInicializadas = false;
    _ouvirUsuarios();
    _ouvirTarefas();
    _ouvirOcorrencias();
    _ouvirAvisos();
    _ouvirNotificacoes();
    _ouvirLocais();
    _ouvirModelos();
  }

  void inicializarDados() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    try {
      await FirebaseAuth.instance.setLanguageCode('pt-BR');
    } catch (_) {}
    _escalaTexto = prefs.getDouble('escala_texto') ?? 1.0;

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (_criandoConta) return;
      if (user == null) {
        _limparSessaoLocal();
        _carregandoSessao = false;
        notifyListeners();
      } else {
        await _iniciarSessao(user);
      }
    });
    notifyListeners();
  }

  /// Carrega (ou cria) o perfil em 'usuarios' e começa a ouvir os dados.
  /// Contas novas sempre entram como funcionário; gestor só é definido no console.
  /// Só entra quem o gestor cadastrou: o perfil precisa existir em 'usuarios'.
  Future<void> _iniciarSessao(User u) async {
    _erroSessao = null;
    try {
      final doc = await _firestore.collection('usuarios').doc(u.uid).get();
      if (doc.exists) {
        _usuarioLogado = Usuario.fromMap(doc.data()!, doc.id);
        _orgId = (doc.data()!['orgId'] as String?)?.trim();
      } else if (!doc.metadata.isFromCache) {
        // Conta sem cadastro da empresa (ex.: alguém tentou o Google): remove a sobra.
        _erroSessao = 'Seu e-mail ainda não foi cadastrado pelo gestor. Fale com ele para receber o convite.';
        try {
          await u.delete();
        } catch (_) {}
      }
    } catch (_) {
      _usuarioLogado = null;
    }
    if (_usuarioLogado == null && _erroSessao != null) {
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    if (_usuarioLogado != null && !_usuarioLogado!.ativo) {
      _erroSessao = 'Sua conta está desativada. Fale com o gestor.';
      _usuarioLogado = null;
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    if (_usuarioLogado != null && (_orgId == null || _orgId!.isEmpty)) {
      _erroSessao = 'Sua conta não está vinculada a uma organização. Fale com o administrador.';
      _usuarioLogado = null;
      _orgId = null;
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    _carregandoSessao = false;
    if (_usuarioLogado != null) {
      _ouvirTudo();
      unawaited(ServicoPush.registrar(_firestore, _usuarioLogado!.id));
    }
    notifyListeners();
  }

  void _ouvirUsuarios() {
    _subs.add(_firestore.collection('usuarios').where('orgId', isEqualTo: _orgId).snapshots().listen((snapshot) {
      usuarios = snapshot.docs.map((doc) => Usuario.fromMap(doc.data(), doc.id)).toList();
      final id = _usuarioLogado?.id;
      if (id != null) {
        final i = usuarios.indexWhere((u) => u.id == id);
        if (i >= 0) {
          _usuarioLogado = usuarios[i];
          if (!_usuarioLogado!.ativo) fazerLogout();
        }
      }
      notifyListeners();
    }, onError: (_) {}));
  }

  List<Tarefa> _tarefas = [];
  void _ouvirTarefas() {
    final u = _usuarioLogado;
    if (u == null) return;
    Query<Map<String, dynamic>> q = _col('tarefas');
    if (u.tipo != TipoPerfil.gestor) q = q.where('idResponsavel', isEqualTo: u.id);
    _subs.add(q.snapshots(includeMetadataChanges: true).listen((snapshot) {
      _tarefas = snapshot.docs.map((doc) => Tarefa.fromMap(doc.data(), doc.id)).toList();
      _pendTarefas = snapshot.docs.where((d) => d.metadata.hasPendingWrites).length;
      NotificacoesLocais.agendarTarefas(_tarefas.where((t) => t.idResponsavel == u.id).toList());
      notifyListeners();
    }, onError: (_) {}));
  }

  List<Ocorrencia> _ocorrencias = [];
  void _ouvirOcorrencias() {
    _subs.add(_col('ocorrencias').snapshots(includeMetadataChanges: true).listen((snapshot) {
      _ocorrencias = snapshot.docs.map((doc) => Ocorrencia.fromMap(doc.data(), doc.id)).toList();
      _pendOcorrencias = snapshot.docs.where((d) => d.metadata.hasPendingWrites).length;
      notifyListeners();
    }, onError: (_) {}));
  }

  List<Aviso> _avisos = [];
  void _ouvirAvisos() {
    _subs.add(_col('avisos').snapshots().listen((snapshot) {
      _avisos = snapshot.docs.map((doc) => Aviso.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (_) {}));
  }

  void _ouvirNotificacoes() {
    final u = _usuarioLogado;
    if (u == null) return;
    Query<Map<String, dynamic>> q = _col('notificacoes');
    if (u.tipo != TipoPerfil.gestor) q = q.where('idUsuario', isEqualTo: u.id);
    _subs.add(q.snapshots().listen((snapshot) {
      _notificacoes = snapshot.docs.map((doc) => NotificacaoUsuario.fromMap(doc.data(), doc.id)).toList();
      // Aviso na barra do celular para notificações novas (com o app aberto ou em segundo plano).
      if (_notifInicializadas) {
        for (final ch in snapshot.docChanges) {
          if (ch.type == DocumentChangeType.added && !ch.doc.metadata.hasPendingWrites && ch.doc.data() != null) {
            final n = NotificacaoUsuario.fromMap(ch.doc.data()!, ch.doc.id);
            if (n.idUsuario == u.id || (u.tipo == TipoPerfil.gestor && n.idUsuario == 'GESTOR_GERAL')) {
              NotificacoesLocais.mostrar(n.titulo, n.mensagem);
            }
          }
        }
      }
      _notifInicializadas = true;
      notifyListeners();
    }, onError: (_) {}));
  }

  List<Local> _locais = [];
  List<Local> get locais => [..._locais]..sort((a, b) => a.nome.compareTo(b.nome));

  void _ouvirLocais() {
    _subs.add(_col('locais').snapshots().listen((snapshot) {
      _locais = snapshot.docs.map((d) => Local.fromMap(d.data(), d.id)).toList();
      notifyListeners();
    }, onError: (_) {}));
  }

  /// Código aleatório e imprevisível (sem letras parecidas como O/0 e I/1).
  String _novoCodigoQr() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return 'CR-${List.generate(10, (_) => letras[r.nextInt(letras.length)]).join()}';
  }

  Local adicionarLocal(String nome, double? lat, double? lng) {
    final ref = _col('locais').doc();
    final local = Local(id: ref.id, nome: nome, codigoQr: _novoCodigoQr(), latitude: lat, longitude: lng);
    ref.set(local.toMap()).catchError((_) {});
    return local;
  }

  void excluirLocal(String id) => _col('locais').doc(id).delete().catchError((_) {});

  void excluirTarefa(String id) => _col('tarefas').doc(id).delete().catchError((_) {});

  void atualizarTarefa(Tarefa t, {
    required String titulo,
    required Local local,
    required TipoTarefa tipo,
    required DateTime horario,
    required String idResponsavel,
    required List<ItemChecklist> checklist,
  }) {
    _col('tarefas').doc(t.id).update({
      'titulo': titulo,
      'local': local.nome,
      'qrCodeEsperado': local.codigoQr,
      'latitudeLocal': local.latitude,
      'longitudeLocal': local.longitude,
      'tipo': tipo.name,
      'horarioPrevisto': horario.toIso8601String(),
      'idResponsavel': idResponsavel,
      'checklist': checklist.map((i) => i.toMap()).toList(),
    }).catchError((_) {});

    if (idResponsavel != t.idResponsavel) {
      final ref = _col('notificacoes').doc();
      ref.set(NotificacaoUsuario(
        id: ref.id,
        idUsuario: idResponsavel,
        titulo: 'Nova Atividade Atribuída!',
        mensagem: 'Você recebeu a tarefa "$titulo" no local ${local.nome}.',
        data: DateTime.now(),
      ).toMap()).catchError((_) {});
    }
  }

  void marcarComoReposto(String idTarefa) =>
      _col('tarefas').doc(idTarefa).update({'produtoEmFalta': false}).catchError((_) {});

  // ---- Rondas recorrentes ----
  List<ModeloRonda> _modelos = [];
  List<ModeloRonda> get modelos => _modelos;

  void _ouvirModelos() {
    final u = _usuarioLogado;
    if (u == null) return;
    Query<Map<String, dynamic>> q = _col('modelos');
    if (u.tipo != TipoPerfil.gestor) q = q.where('idResponsavel', isEqualTo: u.id);
    _subs.add(q.snapshots().listen((snapshot) {
      _modelos = snapshot.docs.map((d) => ModeloRonda.fromMap(d.data(), d.id)).toList();
      _gerarTarefasDoDia();
      notifyListeners();
    }, onError: (_) {}));
  }

  /// Sem servidor: a tarefa do dia é criada quando alguém abre o app (gestor ou o responsável).
  /// O id é fixo (modelo + data), então nunca duplica.
  void _gerarTarefasDoDia() {
    final agora = DateTime.now();
    final hoje = DateFormat('yyyy-MM-dd').format(agora);
    for (final m in _modelos) {
      if (!m.ativo || !m.dias.contains(agora.weekday) || m.ultimaGeracao == hoje) continue;
      final idTarefa = '${m.id}_${hoje.replaceAll('-', '')}';
      final tarefa = Tarefa(
        id: idTarefa,
        titulo: m.titulo,
        local: m.localNome,
        qrCodeEsperado: m.codigoQr,
        tipo: m.tipo,
        horarioPrevisto: DateTime(agora.year, agora.month, agora.day, m.hora, m.minuto),
        idResponsavel: m.idResponsavel,
        checklist: m.checklist.map((t) => ItemChecklist(titulo: t)).toList(),
        latitudeLocal: m.latitudeLocal,
        longitudeLocal: m.longitudeLocal,
        idModelo: m.id,
      );
      _col('tarefas').doc(idTarefa).set(tarefa.toMap()).catchError((_) {});
      _col('modelos').doc(m.id).update({'ultimaGeracao': hoje}).catchError((_) {});
      m.ultimaGeracao = hoje;
    }
  }

  void salvarModelo(ModeloRonda m) => _col('modelos').doc(m.id).set(m.toMap()).catchError((_) {});
  void alternarModelo(String id, bool ativo) => _col('modelos').doc(id).update({'ativo': ativo}).catchError((_) {});
  void excluirModelo(String id) => _col('modelos').doc(id).delete().catchError((_) {});

  // ---- Estado novo: período, filtros, offline, texto ----
  String? _erroSessao;
  bool _notifInicializadas = false;
  int _pendTarefas = 0;
  int _pendOcorrencias = 0;
  int get pendentesSync => _pendTarefas + _pendOcorrencias;

  int _periodoDias = 1; // 1 = hoje, 7, 30, 0 = tudo
  int get periodoDias => _periodoDias;
  void definirPeriodo(int dias) {
    _periodoDias = dias;
    notifyListeners();
  }

  List<Tarefa> get tarefasDoPeriodo {
    final todas = tarefasDoUsuario;
    if (_periodoDias == 0) return todas.toList();
    final agora = DateTime.now();
    final inicio = DateTime(agora.year, agora.month, agora.day).subtract(Duration(days: _periodoDias - 1));
    return todas.where((t) => !t.horarioPrevisto.isBefore(inicio)).toList();
  }

  TipoTarefa? _filtroTipo;
  TipoTarefa? get filtroTipo => _filtroTipo;
  void definirFiltroTipo(TipoTarefa? tipo) {
    _filtroTipo = tipo;
    notifyListeners();
  }

  String _busca = '';
  String get busca => _busca;
  void definirBusca(String v) {
    _busca = v.trim().toLowerCase();
    notifyListeners();
  }

  double _escalaTexto = 1.0;
  double get escalaTexto => _escalaTexto;
  Future<void> alternarEscalaTexto() async {
    _escalaTexto = _escalaTexto >= 1.3 ? 1.0 : double.parse((_escalaTexto + 0.15).toStringAsFixed(2));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('escala_texto', _escalaTexto);
  }

  Future<String?> enviarFoto(String? caminho, String pasta) => _enviarImagem(caminho, pasta);

  Future<Uint8List?> bytesDaFoto(String? caminho) async {
    if (caminho == null || caminho.isEmpty) return null;
    if (caminho.startsWith('foto:')) return buscarFoto(caminho);
    if (caminho.startsWith('http')) return null;
    try {
      return await File(caminho).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  void _notificarGestores(String titulo, String mensagem) {
    final ref = _col('notificacoes').doc();
    ref.set(NotificacaoUsuario(id: ref.id, idUsuario: 'GESTOR_GERAL', titulo: titulo, mensagem: mensagem, data: DateTime.now()).toMap()).catchError((_) {});
  }

  // ---- Equipe ----
  void definirAtivoUsuario(String id, bool ativo) =>
      _firestore.collection('usuarios').doc(id).update({'ativo': ativo}).catchError((_) {});

  void definirTipoUsuario(String id, TipoPerfil tipo) =>
      _firestore.collection('usuarios').doc(id).update({'tipo': tipo.name}).catchError((_) {});

  // ---- LGPD ----
  void aceitarLgpd() {
    final u = _usuarioLogado;
    if (u == null) return;
    _firestore.collection('usuarios').doc(u.id).update({'consentimentoEm': DateTime.now().toIso8601String()}).catchError((_) {});
  }

  /// Apaga o perfil e o login da pessoa. Contas com senha precisam confirmar a senha.
  Future<String?> excluirMinhaConta({String? senha}) async {
    final auth = FirebaseAuth.instance.currentUser;
    final me = _usuarioLogado;
    if (auth == null || me == null) return 'Sessão inválida. Entre de novo.';
    try {
      final provedores = auth.providerData.map((p) => p.providerId).toList();
      if (provedores.contains('password')) {
        if (senha == null || senha.isEmpty) return 'Digite sua senha para confirmar.';
        await auth.reauthenticateWithCredential(EmailAuthProvider.credential(email: auth.email!, password: senha));
      } else if (provedores.contains('google.com')) {
        final conta = await GoogleSignIn().signIn();
        if (conta == null) return 'Confirmação cancelada.';
        final g = await conta.authentication;
        await auth.reauthenticateWithCredential(GoogleAuthProvider.credential(accessToken: g.accessToken, idToken: g.idToken));
      }
      await _firestore.collection('usuarios').doc(me.id).delete();
      await auth.delete();
    } on FirebaseAuthException catch (e) {
      return _mensagemErroAuth(e);
    } catch (_) {
      return 'Não foi possível excluir a conta. Verifique a internet.';
    }
    _limparSessaoLocal();
    notifyListeners();
    return null;
  }

  Future<void> salvarSessao(String username, bool lembrarUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    if (lembrarUsuario) {
      await prefs.setString('logged_username', username);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('logged_username');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> removerSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_username');
  }

  void salvarAssinatura(List<Offset?> pontos) {
    _pontosAssinatura = List.from(pontos);
    notifyListeners();
  }

  void limparAssinatura() {
    _pontosAssinatura.clear();
    notifyListeners();
  }

  String _mensagemErroAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já tem conta. Entre ou recupere a senha.';
      case 'weak-password':
        return 'Use uma senha com pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem internet. Conecte-se para continuar.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      default:
        return 'Não foi possível autenticar (${e.code}).';
    }
  }

  Future<String?> entrarComEmail(String email, String senha, bool lembrar) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: senha);
      await salvarSessao(email.trim().toLowerCase(), lembrar);
      await _iniciarSessao(cred.user!);
      return _usuarioLogado == null ? (_erroSessao ?? 'Não foi possível carregar seu perfil. Verifique a internet.') : null;
    } on FirebaseAuthException catch (e) {
      return _mensagemErroAuth(e);
    } catch (_) {
      return 'Não foi possível entrar. Verifique a internet.';
    }
  }

  /// Devolve 'cancelado' se a pessoa fechou a janela do Google.
  Future<String?> entrarComGoogle() async {
    try {
      final conta = await GoogleSignIn().signIn();
      if (conta == null) return 'cancelado';
      final auth = await conta.authentication;
      final cred = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken),
      );
      await _iniciarSessao(cred.user!);
      return _usuarioLogado == null ? (_erroSessao ?? 'Não foi possível carregar seu perfil. Verifique a internet.') : null;
    } on FirebaseAuthException catch (e) {
      return _mensagemErroAuth(e);
    } catch (_) {
      return 'Não foi possível entrar com o Google.';
    }
  }

  String _senhaAleatoria() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    final r = Random.secure();
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// O gestor cadastra a pessoa. Por padrão, cria o login com uma senha aleatória que ninguém vê
  /// e envia o e-mail para ela definir a própria senha. Se [senhaDefinida] vier preenchida, o
  /// login é criado com essa senha e NENHUM e-mail é enviado. Usa um segundo app do Firebase
  /// para não derrubar o login do gestor.
  Future<String?> cadastrarUsuario({
    required String nome,
    required String email,
    required TipoPerfil tipo,
    String? senhaDefinida,
  }) async {
    if (_usuarioLogado?.tipo != TipoPerfil.gestor) return 'Só o gestor pode cadastrar pessoas.';
    if (_orgId == null || _orgId!.isEmpty) return 'Sua conta não está vinculada a uma organização.';
    final emailLimpo = email.trim().toLowerCase();
    final senhaGestor = (senhaDefinida != null && senhaDefinida.isNotEmpty) ? senhaDefinida : null;
    if (senhaGestor != null && senhaGestor.length < 6) return 'Use uma senha com pelo menos 6 caracteres.';
    FirebaseAuth? authSec;
    try {
      final app = Firebase.apps.any((a) => a.name == 'cadastro')
          ? Firebase.app('cadastro')
          : await Firebase.initializeApp(name: 'cadastro', options: Firebase.app().options);
      authSec = FirebaseAuth.instanceFor(app: app);
      await authSec.setLanguageCode('pt-BR');
      final cred = await authSec.createUserWithEmailAndPassword(email: emailLimpo, password: senhaGestor ?? _senhaAleatoria());
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(nome.trim());
      final novo = Usuario(id: uid, nome: nome.trim(), username: emailLimpo, senha: '', tipo: tipo);
      await _firestore.collection('usuarios').doc(uid).set({...novo.toMap(), 'orgId': _orgId});
      if (senhaGestor == null) await authSec.sendPasswordResetEmail(email: emailLimpo);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Este e-mail já tem cadastro. Na lista da equipe, use "Reenviar convite".';
      }
      return _mensagemErroAuth(e);
    } catch (_) {
      return 'Não foi possível cadastrar. Verifique a internet.';
    } finally {
      try {
        await authSec?.signOut();
      } catch (_) {}
    }
  }

  Future<String?> recuperarSenha(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensagemErroAuth(e);
    } catch (_) {
      return 'Não foi possível enviar o e-mail. Verifique a internet.';
    }
  }

  Future<void> fazerLogout() async {
    final uidAtual = _usuarioLogado?.id;
    if (uidAtual != null) await ServicoPush.remover(_firestore, uidAtual);
    _limparSessaoLocal();
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
    await removerSessao();
    notifyListeners();
  }

  List<Aviso> get avisos => _avisos;

  void adicionarAviso(Aviso aviso) {
    _col('avisos').doc(aviso.id).set(aviso.toMap()).catchError((_) {});
    notifyListeners();
  }

  List<Ocorrencia> get ocorrencias => _ocorrencias;

  void adicionarOcorrencia(Ocorrencia oc) {
    _col('ocorrencias').doc(oc.id).set(oc.toMap()).catchError((_) {});
    _notificarGestores('Nova Ocorrência (${rotuloPrioridade(oc.prioridade)}): ${oc.titulo}', '${oc.autorNome} registrou uma ocorrência em ${oc.local}.');
    notifyListeners();
  }

  void atualizarStatusOcorrencia(String id, StatusOcorrencia novoStatus) {
    _col('ocorrencias').doc(id).update({'status': novoStatus.name}).catchError((_) {});
    final i = _ocorrencias.indexWhere((o) => o.id == id);
    if (i >= 0 && _ocorrencias[i].idAutor.isNotEmpty && _ocorrencias[i].idAutor != _usuarioLogado?.id) {
      final oc = _ocorrencias[i];
      final ref = _col('notificacoes').doc();
      ref.set(NotificacaoUsuario(
        id: ref.id,
        idUsuario: oc.idAutor,
        titulo: 'Sua ocorrência foi atualizada',
        mensagem: '"${oc.titulo}" agora está: ${rotuloStatusOcorrencia(novoStatus)}.',
        data: DateTime.now(),
      ).toMap()).catchError((_) {});
    }
  }

  List<Tarefa> get tarefasDoUsuario {
    if (_usuarioLogado == null) return [];
    if (_usuarioLogado!.tipo == TipoPerfil.gestor) {
      return _tarefas;
    }
    return _tarefas.where((t) => t.idResponsavel == _usuarioLogado!.id).toList();
  }

  int get totalConcluidas => tarefasDoUsuario.where((t) => t.status == StatusTarefa.concluida).length;
  int get totalPendentes => tarefasDoUsuario.where((t) => t.statusEfetivo == StatusTarefa.pendente).length;
  int get totalAtrasadas => tarefasDoUsuario.where((t) => t.statusEfetivo == StatusTarefa.atrasada).length;

  Future<void> adicionarTarefa(Tarefa novaTarefa) async {
    // Sem await: offline, o Firestore guarda na fila e envia depois.
    _col('tarefas').doc(novaTarefa.id).set(novaTarefa.toMap()).catchError((_) {});

    final notifRef = _col('notificacoes').doc();
    final notif = NotificacaoUsuario(
      id: notifRef.id,
      idUsuario: novaTarefa.idResponsavel,
      titulo: 'Nova Atividade Atribuída!',
      mensagem: 'Você recebeu a tarefa "${novaTarefa.titulo}" no local ${novaTarefa.local}.',
      data: DateTime.now(),
    );
    notifRef.set(notif.toMap()).catchError((_) {});

    notifyListeners();
  }

  final Map<String, Uint8List> _cacheFotos = {};

  /// Guarda a foto (já reduzida) na coleção 'fotos' do Firestore e devolve a referência 'foto:ID'.
  /// Funciona offline: o Firestore envia quando a internet voltar.
  Future<String?> _enviarImagem(String? caminho, String pasta) async {
    if (caminho == null || caminho.isEmpty || caminho.startsWith('http') || caminho.startsWith('foto:')) return caminho;
    try {
      final bytes = await File(caminho).readAsBytes();
      // Limite do Firestore: ~1 MB por documento (a base64 aumenta o tamanho em ~33%).
      if (bytes.length > 600 * 1024) return caminho;
      final ref = _col('fotos').doc();
      ref.set({
        'dados': base64Encode(bytes),
        'pasta': pasta,
        'criadaEm': DateTime.now().toIso8601String(),
      }).catchError((_) {});
      _cacheFotos[ref.id] = bytes;
      return 'foto:${ref.id}';
    } catch (_) {
      return caminho;
    }
  }

  Uint8List? fotoEmCache(String referencia) => _cacheFotos[referencia.replaceFirst('foto:', '')];

  Future<Uint8List?> buscarFoto(String referencia) async {
    final id = referencia.replaceFirst('foto:', '');
    final emCache = _cacheFotos[id];
    if (emCache != null) return emCache;
    try {
      final doc = await _col('fotos').doc(id).get();
      final dados = doc.data()?['dados'] as String?;
      if (dados == null) return null;
      final bytes = base64Decode(dados);
      _cacheFotos[id] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> concluirTarefa({
    required String id,
    required String? fotoAntesPath,
    required String? fotoDepoisPath,
    List<ItemChecklist>? checklist,
    DateTime? inicio,
    bool produtoEmFalta = false,
    String? obs,
    double? lat,
    double? lng,
  }) async {
    final fotos = await Future.wait([
      _enviarImagem(fotoAntesPath, 'tarefas/$id'),
      _enviarImagem(fotoDepoisPath, 'tarefas/$id'),
    ]);

    // Sem await: offline, o Firestore guarda na fila e sincroniza quando a internet voltar.
    _col('tarefas').doc(id).update({
      'status': StatusTarefa.concluida.name,
      'fotoAntesPath': fotos[0],
      'fotoDepoisPath': fotos[1],
      'produtoEmFalta': produtoEmFalta,
      'observacao': obs,
      'horarioConclusao': DateTime.now().toIso8601String(),
      'latitudeCheckin': lat,
      'longitudeCheckin': lng,
      'horarioInicio': inicio?.toIso8601String(),
      if (checklist != null) 'checklist': checklist.map((i) => i.toMap()).toList(),
    }).catchError((_) {});

    if ((obs != null && obs.isNotEmpty) || produtoEmFalta) {
      final tarefaAtual = _tarefas.firstWhere((t) => t.id == id, orElse: () => _tarefas.first);
      final funcionarioNome = _usuarioLogado?.nome ?? 'Funcionário';

      final notifRef = _col('notificacoes').doc();
      final notif = NotificacaoUsuario(
        id: notifRef.id,
        idUsuario: 'GESTOR_GERAL',
        titulo: 'Alerta / Observação em Tarefa',
        mensagem: '$funcionarioNome reportou "${produtoEmFalta ? 'Produto em falta' : 'Nova observação'}" na tarefa ${tarefaAtual.titulo}.',
        data: DateTime.now(),
      );
      notifRef.set(notif.toMap()).catchError((_) {});
    }

    // Alerta ao gestor quando a tarefa é concluída rápido demais (menos de 1 minuto após o check-in).
    if (inicio != null && DateTime.now().difference(inicio).inSeconds < 60) {
      final i = _tarefas.indexWhere((t) => t.id == id);
      final titulo = i >= 0 ? _tarefas[i].titulo : 'uma tarefa';
      _notificarGestores('Tarefa concluída muito rápido', '${_usuarioLogado?.nome ?? 'Funcionário'} concluiu "$titulo" em menos de 1 minuto. Vale conferir as fotos.');
    }

    notifyListeners();
  }

  Usuario? getUsuarioPorId(String id) {
    try {
      return usuarios.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}