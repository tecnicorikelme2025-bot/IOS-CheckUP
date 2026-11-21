part of 'main.dart';


// ==========================================
// TELA DE LOGIN & CADASTRO
// ==========================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _lembrarUsuario = false;
  String? _erroMensagem;

  @override
  void initState() {
    super.initState();
    _carregarLoginSalvo();
  }

  void _carregarLoginSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final bool remember = prefs.getBool('remember_me') ?? false;
    final String? savedUsername = prefs.getString('logged_username');
    if (remember && savedUsername != null) {
      setState(() {
        _userController.text = savedUsername;
        _lembrarUsuario = true;
      });
    }
  }

  void _irParaHome() {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
  }

  void _entrar() async {
    final state = Provider.of<AppState>(context, listen: false);
    final email = _userController.text.trim();
    if (!email.contains('@') || _senhaController.text.isEmpty) {
      setState(() => _erroMensagem = 'Digite o e-mail e a senha da sua conta.');
      return;
    }
    final erro = await state.entrarComEmail(email, _senhaController.text, _lembrarUsuario);
    if (erro == null) {
      _irParaHome();
    } else if (mounted) {
      setState(() => _erroMensagem = erro);
    }
  }

  void _entrarComGoogle() async {
    final erro = await Provider.of<AppState>(context, listen: false).entrarComGoogle();
    if (erro == null) {
      _irParaHome();
    } else if (erro != 'cancelado' && mounted) {
      setState(() => _erroMensagem = erro);
    }
  }

  void _recuperarSenha() {
    final emailCtrl = TextEditingController(text: _userController.text.contains('@') ? _userController.text.trim() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail da conta'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final erro = await Provider.of<AppState>(context, listen: false).recuperarSenha(emailCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(erro ?? 'Se o e-mail tiver conta, enviamos um link para redefinir a senha.'),
                ));
              }
            },
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: LogoCheckRonda(tamanho: 68)),
              const SizedBox(height: 24),
              Text('CheckUP', style: GoogleFonts.sora(fontSize: 40, fontWeight: FontWeight.w800, height: 1.05, color: context.cr.tinta)),
              const SizedBox(height: 8),
              Text('Escaneie o local, registre a foto e conclua cada parada da sua ronda.', style: TextStyle(fontSize: 16, height: 1.35, color: context.cr.tintaSuave)),
              const SizedBox(height: 36),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline_rounded)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline_rounded)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lembrar meu usuário neste dispositivo', style: TextStyle(fontSize: 14)),
                value: _lembrarUsuario,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) => setState(() => _lembrarUsuario = val ?? false),
              ),
              if (_erroMensagem != null) ...[
                const SizedBox(height: 12),
                Text(_erroMensagem!, style: TextStyle(color: context.cr.atraso, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _entrar,
                  child: const Text('Entrar'),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _recuperarSenha, child: const Text('Esqueci minha senha')),
              ),
              Row(children: [
                Expanded(child: Divider(color: context.cr.linha)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: TextStyle(color: context.cr.tintaSuave))),
                Expanded(child: Divider(color: context.cr.linha)),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _entrarComGoogle,
                icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                label: const Text('Continuar com o Google'),
              ),
              const SizedBox(height: 12),
              Text('Primeiro acesso? Peça seu cadastro ao gestor. Você receberá um e-mail para criar a sua senha.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.cr.tintaSuave)),
              const SizedBox(height: 40),
              const CreditoAllCode(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
