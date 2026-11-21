part of 'main.dart';


// ==========================================
// LEMBRETES E ALERTAS NO CELULAR (sem servidor)
// ==========================================
class NotificacoesLocais {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _pronto = false;
  static String _ultimaAssinatura = '';

  static const NotificationDetails _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'checkronda_lembretes',
      'Lembretes de tarefas',
      channelDescription: 'Avisos antes do horário das paradas e alertas do app',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> iniciar() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      _pronto = true;
    } catch (_) {
      _pronto = false;
    }
  }

  static Future<void> mostrar(String titulo, String corpo) async {
    if (!_pronto) return;
    try {
      await _plugin.show(DateTime.now().millisecondsSinceEpoch & 0x7fffffff, titulo, corpo, _detalhes);
    } catch (_) {}
  }

  static Future<void> cancelarTudo() async {
    _ultimaAssinatura = '';
    if (!_pronto) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Agenda um lembrete 10 minutos antes de cada tarefa pendente do usuário.
  static Future<void> agendarTarefas(List<Tarefa> tarefas) async {
    if (!_pronto) return;
    final pendentes = tarefas.where((t) => t.status == StatusTarefa.pendente).toList();
    final assinatura = pendentes.map((t) => '${t.id}@${t.horarioPrevisto.millisecondsSinceEpoch}').join('|');
    if (assinatura == _ultimaAssinatura) return;
    _ultimaAssinatura = assinatura;
    try {
      await _plugin.cancelAll();
      final agora = DateTime.now();
      for (final t in pendentes) {
        final aviso = t.horarioPrevisto.subtract(const Duration(minutes: 10));
        if (!aviso.isAfter(agora)) continue;
        await _plugin.zonedSchedule(
          t.id.hashCode & 0x7fffffff,
          'Parada em 10 minutos',
          '${t.titulo} · ${t.local}',
          tz.TZDateTime.from(aviso, tz.local),
          _detalhes,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }
}
