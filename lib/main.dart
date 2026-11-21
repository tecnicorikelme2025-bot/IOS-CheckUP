import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'cr_design.dart';

// Importações do Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'app_state.dart';
part 'login.dart';
part 'modelos.dart';
part 'navegacao.dart';
part 'notificacoes_locais.dart';
part 'ocorrencias.dart';
part 'painel.dart';
part 'privacidade.dart';
part 'rondas.dart';
part 'tarefas.dart';
part 'utilitarios.dart';
part 'push.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização obrigatória do Firebase
  await Firebase.initializeApp();
  await NotificacoesLocais.iniciar();

  // Habilitar persistência offline nativa no Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..inicializarDados(),
      child: const CheckRondaApp(),
    ),
  );
}


class CheckRondaApp extends StatelessWidget {
  const CheckRondaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'CheckUP',
          debugShowCheckedModeBanner: false,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(state.escalaTexto)),
            child: child!,
          ),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: CrTheme.claro(),
          darkTheme: CrTheme.escuro(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          home: state.carregandoSessao
              ? const _TelaCarregando()
              : (state.usuarioLogado != null ? const MainNavigationScreen() : const LoginScreen()),
        );
      },
    );
  }
}

/// Tela de abertura: logo do app no centro e o crédito da AllCode embaixo.
class _TelaCarregando extends StatelessWidget {
  const _TelaCarregando();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.96 + 0.04 * v, child: child)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoCheckRonda(tamanho: 88),
                    const SizedBox(height: 20),
                    Text('CheckUP', style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.w800, color: context.cr.tinta)),
                    const SizedBox(height: 28),
                    const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  ],
                ),
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 24, child: CreditoAllCode()),
          ],
        ),
      ),
    );
  }
}