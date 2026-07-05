import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme() {
    const primary = Color(0xFF0D5E66);
    const secondary = Color(0xFFE7844A);
    const tertiary = Color(0xFF2E7FE8);
    const surface = Color(0xFFFFFFFF);
    const background = Color(0xFFF3F6FB);
    const outline = Color(0xFFD9E2EE);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      outline: outline,
      onSurface: const Color(0xFF102133),
    );

    final textTheme = GoogleFonts.soraTextTheme().copyWith(
      headlineSmall: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600),
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: outline, width: 1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.94),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: roundedShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: outline),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.95),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
        height: 70,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge!,
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
