part of 'main.dart';

// ==========================================
// NOTIFICAÇÕES PUSH (Firebase Cloud Messaging)
// ==========================================

/// Registra o aparelho para receber notificações enviadas pelo servidor.
/// O token do aparelho fica em usuarios/{uid}, no campo "fcmToken".
class ServicoPush {
  static StreamSubscription<String>? _renovacao;

  /// Pede permissão, grava o token e acompanha as renovações dele.
  static Future<void> registrar(FirebaseFirestore db, String uid) async {
    try {
      final fcm = FirebaseMessaging.instance;
      final permissao = await fcm.requestPermission();
      if (permissao.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await fcm.getToken();
      if (token != null) _salvar(db, uid, token);

      await _renovacao?.cancel();
      _renovacao = fcm.onTokenRefresh.listen((novo) => _salvar(db, uid, novo));
    } catch (_) {}
  }

  static void _salvar(FirebaseFirestore db, String uid, String token) {
    db.collection('usuarios').doc(uid).update({'fcmToken': token}).catchError((_) {});
  }

  /// Chamar antes do logout: tira o token deste aparelho do usuário,
  /// para ele não receber avisos de quem entrar depois no mesmo aparelho.
  static Future<void> remover(FirebaseFirestore db, String uid) async {
    await _renovacao?.cancel();
    _renovacao = null;
    try {
      await db
          .collection('usuarios')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()}).timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}