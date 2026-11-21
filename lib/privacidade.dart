part of 'main.dart';


// ==========================================
// PRIVACIDADE E LGPD
// ==========================================

// ATENÇÃO: este texto é um RASCUNHO. Antes de publicar o app:
//   1) preencha todos os trechos marcados com [PREENCHER ...];
//   2) peça a revisão de um advogado ou encarregado de dados;
//   3) publique o mesmo texto em um endereço web público (a loja de aplicativos exige).
// Se mudar algo, atualize também a versão e a data no final do texto.
const String kTextoPrivacidade = '''Este texto explica como o CheckUP trata os seus dados pessoais.

Quem é responsável pelos seus dados
• Controladora: a empresa em que você trabalha e que usa o CheckUP. É ela quem decide para que os dados são usados.
• Desenvolvedor: Rikelme Souza, que trata os dados em nome da sua empresa, seguindo as instruções dela.
• Contato sobre privacidade: tecnicorikelme2025@gmail.com.

O que é coletado
• Conta: nome, e-mail, perfil (funcionário ou gestor), foto de perfil (opcional) e a data em que você leu este texto.
• Notificações: um identificador do seu aparelho, usado para enviar avisos do app.
• Localização (GPS): lida quando você faz o check-in de uma tarefa, para confirmar que está no local. As coordenadas ficam gravadas na tarefa e aparecem nos relatórios.
• Fotos, observações e ocorrências que você registra. Nas ocorrências, o seu nome fica gravado como autor.
• Horários de início e de conclusão das tarefas e o tempo de execução.

Para que serve
Comprovar a execução das rondas de limpeza e reposição, gerar relatórios de gestão, avisar sobre atrasos e ocorrências e manter a segurança da operação.


Quem vê os seus dados
• Os gestores da sua empresa veem os registros de todos: tarefas, fotos, localização do check-in e ocorrências.
• Cada funcionário vê apenas as próprias tarefas. Ocorrências, avisos e locais são visíveis a todos da mesma empresa, e colegas da mesma empresa podem ver o seu nome e a sua foto de perfil.
• Os dados de uma empresa não são visíveis para outras empresas.

Onde ficam os dados e com quem são compartilhados
Os dados ficam em serviços do Google (Firebase: login, banco de dados e notificações) e passam por um servidor da Cloudflare. Esses serviços podem usar servidores fora do Brasil. [PREENCHER: países ou regiões e a garantia usada na transferência internacional]. Não vendemos os seus dados.

Por quanto tempo
Os dados da conta ficam até você excluí-la. Os registros de tarefas e ocorrências ficam no histórico da empresa por tempo indeterminado.

Seus direitos (LGPD)
Você pode pedir confirmação de que tratamos seus dados, acesso, correção, anonimização ou eliminação, portabilidade e informação sobre com quem os dados são compartilhados. Você também pode retirar o seu consentimento quando ele for a base do tratamento e reclamar à ANPD. Para exercer esses direitos, use o contato de privacidade acima ou fale com o gestor da sua unidade.

Em "Privacidade e dados" você exclui a sua conta a qualquer momento. Isso apaga o seu perfil, o seu login e o identificador de notificações. Registros já feitos, como tarefas concluídas, fotos, localização do check-in e ocorrências, podem permanecer no histórico da empresa, e em ocorrências o seu nome pode continuar aparecendo como autor. Para pedir a remoção ou a anonimização desses registros, use o contato de privacidade.

Segurança
O acesso exige login e depende do seu perfil. Cada empresa acessa apenas os próprios dados. Se houver um incidente de segurança que possa causar risco a você, avisaremos nos termos da lei.

Versão 1, de 19/11/2026.
Rikelme Souza - desenvolvedor deste app e propietário da AllCode Software''';


class ConsentimentoLgpdScreen extends StatefulWidget {
  const ConsentimentoLgpdScreen({super.key});

  @override
  State<ConsentimentoLgpdScreen> createState() => _ConsentimentoLgpdScreenState();
}


class _ConsentimentoLgpdScreenState extends State<ConsentimentoLgpdScreen> {
  bool _aceito = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Seus dados no CheckUP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(child: Text(kTextoPrivacidade, style: const TextStyle(height: 1.4)))),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _aceito,
                onChanged: (v) => setState(() => _aceito = v ?? false),
                title: const Text('Li e concordo com o uso dos meus dados como descrito acima.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              ElevatedButton(onPressed: _aceito ? state.aceitarLgpd : null, child: const Text('Continuar')),
              TextButton(
                onPressed: () async {
                  await state.fazerLogout();
                  if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class PoliticaPrivacidadeScreen extends StatelessWidget {
  const PoliticaPrivacidadeScreen({super.key});

  Future<void> _excluirConta(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);
    final usaSenha = FirebaseAuth.instance.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;
    final senhaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir minha conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seu perfil e seu login serão apagados. Isso não pode ser desfeito.'),
            if (usaSenha) ...[
              const SizedBox(height: 12),
              TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirme sua senha')),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    final erro = await state.excluirMinhaConta(senha: senhaCtrl.text);
    if (!context.mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e dados')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(kTextoPrivacidade, style: TextStyle(height: 1.4)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _excluirConta(context),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Excluir minha conta e meus dados'),
          ),
          const SizedBox(height: 32),
          const CreditoAllCode(),
        ],
      ),
    );
  }
}