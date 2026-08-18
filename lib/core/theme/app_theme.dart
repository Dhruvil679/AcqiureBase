import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // Inter replaces GoogleSans across the app per the admin-panel restyle.
  static String get customFontFamily => GoogleFonts.inter().fontFamily!;

  // Light-mode color tokens from design_reference/.../DESIGN.md.
  static const Color _primary = Color(0xFF065EFF);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _primaryContainer = Color(0xFF035DFE);
  static const Color _onPrimaryContainer = Color(0xFFECEEFF);
  static const Color _inversePrimary = Color(0xFFB5C4FF);

  static const Color _secondary = Color(0xFF425BA3);
  static const Color _onSecondary = Color(0xFFFFFFFF);
  static const Color _secondaryContainer = Color(0xFF99B0FF);
  static const Color _onSecondaryContainer = Color(0xFF274188);

  static const Color _tertiary = Color(0xFF9B2D00);
  static const Color _onTertiary = Color(0xFFFFFFFF);
  static const Color _tertiaryContainer = Color(0xFFC53B00);
  static const Color _onTertiaryContainer = Color(0xFFFFEAE5);

  static const Color _error = Color(0xFFBA1A1A);
  static const Color _onError = Color(0xFFFFFFFF);
  static const Color _errorContainer = Color(0xFFFFDAD6);
  static const Color _onErrorContainer = Color(0xFF93000A);

  static const Color _surface = Color(0xFFFBF8FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLow = Color(0xFFF3F2FF);
  static const Color _surfaceContainer = Color(0xFFEDEDFB);
  static const Color _surfaceContainerHigh = Color(0xFFE7E7F5);
  static const Color _surfaceContainerHighest = Color(0xFFE1E1EF);
  static const Color _onSurface = Color(0xFF191B25);
  static const Color _onSurfaceVariant = Color(0xFF424656);
  static const Color _inverseSurface = Color(0xFF2E303A);
  static const Color _inverseOnSurface = Color(0xFFF0EFFD);
  static const Color _outline = Color(0xFF737688);
  static const Color _outlineVariant = Color(0xFFC3C5D9);
  static const Color _surfaceTint = Color(0xFF0051E0);

  static const Color _primaryFixed = Color(0xFFDBE1FF);
  static const Color _primaryFixedDim = Color(0xFFB5C4FF);
  static const Color _onPrimaryFixed = Color(0xFF00164D);
  static const Color _onPrimaryFixedVariant = Color(0xFF003CAC);
  static const Color _secondaryFixed = Color(0xFFDBE1FF);
  static const Color _secondaryFixedDim = Color(0xFFB4C5FF);
  static const Color _onSecondaryFixed = Color(0xFF00174C);
  static const Color _onSecondaryFixedVariant = Color(0xFF294289);
  static const Color _tertiaryFixed = Color(0xFFFFDBD0);
  static const Color _tertiaryFixedDim = Color(0xFFFFB59E);
  static const Color _onTertiaryFixed = Color(0xFF3A0B00);
  static const Color _onTertiaryFixedVariant = Color(0xFF842500);

  static ColorScheme get _lightColorScheme => ColorScheme(
        brightness: Brightness.light,
        primary: _primary,
        onPrimary: _onPrimary,
        primaryContainer: _primaryContainer,
        onPrimaryContainer: _onPrimaryContainer,
        secondary: _secondary,
        onSecondary: _onSecondary,
        secondaryContainer: _secondaryContainer,
        onSecondaryContainer: _onSecondaryContainer,
        tertiary: _tertiary,
        onTertiary: _onTertiary,
        tertiaryContainer: _tertiaryContainer,
        onTertiaryContainer: _onTertiaryContainer,
        error: _error,
        onError: _onError,
        errorContainer: _errorContainer,
        onErrorContainer: _onErrorContainer,
        surface: _surface,
        onSurface: _onSurface,
        onSurfaceVariant: _onSurfaceVariant,
        outline: _outline,
        outlineVariant: _outlineVariant,
        inverseSurface: _inverseSurface,
        onInverseSurface: _inverseOnSurface,
        inversePrimary: _inversePrimary,
        surfaceTint: _surfaceTint,
        surfaceContainerLowest: _surfaceContainerLowest,
        surfaceContainerLow: _surfaceContainerLow,
        surfaceContainer: _surfaceContainer,
        surfaceContainerHigh: _surfaceContainerHigh,
        surfaceContainerHighest: _surfaceContainerHighest,
        primaryFixed: _primaryFixed,
        primaryFixedDim: _primaryFixedDim,
        onPrimaryFixed: _onPrimaryFixed,
        onPrimaryFixedVariant: _onPrimaryFixedVariant,
        secondaryFixed: _secondaryFixed,
        secondaryFixedDim: _secondaryFixedDim,
        onSecondaryFixed: _onSecondaryFixed,
        onSecondaryFixedVariant: _onSecondaryFixedVariant,
        tertiaryFixed: _tertiaryFixed,
        tertiaryFixedDim: _tertiaryFixedDim,
        onTertiaryFixed: _onTertiaryFixed,
        onTertiaryFixedVariant: _onTertiaryFixedVariant,
        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),
      );

  static ThemeData get light {
    final colorScheme = _lightColorScheme;
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      fontFamily: customFontFamily,
      textTheme: baseTextTheme,
      filledButtonTheme: _filledButtonTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
      listTileTheme: _listTileTheme(colorScheme),
      dividerTheme: _dividerTheme(colorScheme),
      shadowColor: Colors.transparent,
      scaffoldBackgroundColor: colorScheme.surface,
      applyElevationOverlayColor: false,
    );
  }

  static ThemeData get dark {
    // The reference only provides light tokens; keep a seed-derived dark theme
    // so the app still works if the device forces dark mode.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    );
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      fontFamily: customFontFamily,
      textTheme: baseTextTheme,
      filledButtonTheme: _filledButtonTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
      listTileTheme: _listTileTheme(colorScheme),
      dividerTheme: _dividerTheme(colorScheme),
      shadowColor: Colors.transparent,
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  static FilledButtonThemeData _filledButtonTheme(ColorScheme colors) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colors) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme colors) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colors.surfaceContainerLow,
      surfaceTintColor: colors.surfaceTint,
    );
  }

  static FloatingActionButtonThemeData _fabTheme(ColorScheme colors) {
    return FloatingActionButtonThemeData(
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme colors) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: colors.surfaceContainerHigh,
      foregroundColor: colors.onSurface,
      surfaceTintColor: colors.surfaceTint,
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colors) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme colors) {
    return ChipThemeData(
      backgroundColor: colors.surfaceContainerHighest,
      selectedColor: colors.secondaryContainer,
      labelStyle: GoogleFonts.inter(
        textStyle: TextStyle(color: colors.onSurface),
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        textStyle: TextStyle(color: colors.onSecondaryContainer),
      ),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );
  }

  static ListTileThemeData _listTileTheme(ColorScheme colors) {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: colors.surfaceContainerLowest,
      iconColor: colors.onSurfaceVariant,
    );
  }

  static DividerThemeData _dividerTheme(ColorScheme colors) {
    return DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 1,
    );
  }
}
