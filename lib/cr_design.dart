import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores próprias do CheckRonda (acesse com context.cr).
@immutable
class CrCores extends ThemeExtension<CrCores> {
  final Color fundo, superficie, superficieAlta, tinta, tintaSuave, linha, marca, reposicao, limpeza, ok, atraso;
  const CrCores({
    required this.fundo, required this.superficie, required this.superficieAlta, required this.tinta,
    required this.tintaSuave, required this.linha, required this.marca, required this.reposicao,
    required this.limpeza, required this.ok, required this.atraso,
  });

  static const claro = CrCores(
    fundo: Color(0xFFF3F2F8), superficie: Colors.white, superficieAlta: Color(0xFFEBEAF2),
    tinta: Color(0xFF14161C), tintaSuave: Color(0xFF6A7080), linha: Color(0xFFE2E1EA),
    marca: Color(0xFF2450E6), reposicao: Color(0xFFD98E1F), limpeza: Color(0xFF0E9F9A),
    ok: Color(0xFF12945F), atraso: Color(0xFFE5384D),
  );
  static const escuro = CrCores(
    fundo: Color(0xFF0E1015), superficie: Color(0xFF181B22), superficieAlta: Color(0xFF20242D),
    tinta: Color(0xFFF4F5F8), tintaSuave: Color(0xFF9AA1B2), linha: Color(0xFF2A2F3A),
    marca: Color(0xFF7C9BFF), reposicao: Color(0xFFF0A83A), limpeza: Color(0xFF2CC7C0),
    ok: Color(0xFF35D08A), atraso: Color(0xFFFF6B7A),
  );

  @override
  CrCores copyWith() => this;
  @override
  CrCores lerp(ThemeExtension<CrCores>? other, double t) => other is CrCores ? (t < 0.5 ? this : other) : this;
}

extension CrContext on BuildContext {
  CrCores get cr => Theme.of(this).extension<CrCores>()!;
}

class CrTheme {
  /// Azul da marca CheckRonda (o mesmo da logo do QR Code): botões e blocos de destaque, com texto branco em cima.
  static const marcaForte = Color(0xFF2450E6);
  static const cobalto = marcaForte; // nome antigo, mantido por compatibilidade

  static ThemeData claro() => _build(CrCores.claro, Brightness.light);
  static ThemeData escuro() => _build(CrCores.escuro, Brightness.dark);

  static ThemeData _build(CrCores c, Brightness b) {
    final claro = b == Brightness.light;
    final scheme = ColorScheme.fromSeed(seedColor: marcaForte, brightness: b).copyWith(
      primary: claro ? marcaForte : c.marca,
      onPrimary: claro ? Colors.white : c.fundo,
      surface: c.superficie,
      onSurface: c.tinta,
      outline: c.linha,
    );
    final base = ThemeData(useMaterial3: true, brightness: b, colorScheme: scheme);
    final corpo = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: c.tinta, displayColor: c.tinta);
    TextStyle? titulo(TextStyle? s) => GoogleFonts.sora(textStyle: s, fontWeight: FontWeight.w800, color: c.tinta);
    final texto = corpo.copyWith(
      displayLarge: titulo(corpo.displayLarge), displayMedium: titulo(corpo.displayMedium), displaySmall: titulo(corpo.displaySmall),
      headlineLarge: titulo(corpo.headlineLarge), headlineMedium: titulo(corpo.headlineMedium), headlineSmall: titulo(corpo.headlineSmall),
      titleLarge: titulo(corpo.titleLarge),
    );
    OutlineInputBorder borda(Color cor, [double w = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: w == 0 ? BorderSide.none : BorderSide(color: cor, width: w),
        );
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));

    return base.copyWith(
      scaffoldBackgroundColor: c.fundo,
      textTheme: texto,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.fundo, foregroundColor: c.tinta, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: c.tinta),
      ),
      cardTheme: CardThemeData(
        color: c.superficie, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: c.linha)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: c.superficieAlta,
        border: borda(c.linha), enabledBorder: borda(c.linha), focusedBorder: borda(scheme.primary, 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, backgroundColor: marcaForte, foregroundColor: Colors.white,
          minimumSize: const Size(0, 54), shape: forma,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54), shape: forma, side: BorderSide(color: c.linha, width: 1.5),
          foregroundColor: c.tinta,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(), side: BorderSide(color: c.linha),
        backgroundColor: c.superficie, selectedColor: marcaForte.withOpacity(0.25), checkmarkColor: c.marca,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: c.tinta),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.superficieAlta, height: 70, elevation: 0,
        indicatorColor: marcaForte.withOpacity(0.28),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.marca : c.tintaSuave)),
        labelTextStyle: WidgetStatePropertyAll(GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: marcaForte, foregroundColor: Colors.white, elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: forma),
      dialogTheme: DialogThemeData(backgroundColor: c.superficieAlta, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficieAlta,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      ),
    );
  }
}

/// Logo da AllCode: escolhe sozinha a versão para fundo escuro ou claro.
/// Se o arquivo não estiver em assets/logo/, simplesmente não aparece (o app não quebra).
class LogoAllCode extends StatelessWidget {
  final double altura;
  final bool soMarca;
  const LogoAllCode({super.key, this.altura = 32, this.soMarca = false});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final arquivo = soMarca ? 'allcode_marca' : (escuro ? 'allcode_logo_escuro' : 'allcode_logo_claro');
    return Image.asset(
      'assets/logo/$arquivo.png',
      height: altura,
      filterQuality: FilterQuality.high,
      semanticLabel: 'AllCode',
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Logo do aplicativo CheckRonda: o ícone de leitor de QR Code, branco sobre o quadrado azul (igual à versão original).
class LogoCheckRonda extends StatelessWidget {
  final double tamanho;
  const LogoCheckRonda({super.key, this.tamanho = 64});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CheckUP',
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(color: CrTheme.marcaForte, borderRadius: BorderRadius.circular(tamanho * 0.32)),
        child: Icon(Icons.qr_code_scanner_rounded, size: tamanho * 0.53, color: Colors.white),
      ),
    );
  }
}

/// Crédito discreto de quem desenvolveu o app, no estilo "from Meta" do Instagram.
class CreditoAllCode extends StatelessWidget {
  const CreditoAllCode({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Desenvolvido por', style: TextStyle(fontSize: 11, letterSpacing: 0.4, color: context.cr.tintaSuave)),
        const SizedBox(height: 6),
        const LogoAllCode(altura: 20),
      ],
    );
  }
}
