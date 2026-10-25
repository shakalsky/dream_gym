import 'package:dream_gym/core/theme/app_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The app's themes: the design system's, with Archivo as the typeface and
/// [AppPalette] as the dark colors.
///
/// The dark palette is poured into the design system's own tokens
/// ([AppThemeColors]) rather than into new ones, so every screen that reads
/// `context.appThemeColors` picks it up without being touched.
abstract final class DreamGymTheme {
  static final ThemeData light = _withArchivo(AppTheme.lightTheme);

  static final ThemeData dark = _withArchivo(
    AppTheme.darkTheme.copyWith(
      extensions: const [_darkColors],
      scaffoldBackgroundColor: AppPalette.background,
      canvasColor: AppPalette.background,
      dividerColor: AppPalette.divider,
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.accent,
        onPrimary: AppPalette.onAccent,
        secondary: AppPalette.accent,
        onSecondary: AppPalette.onAccent,
        error: AppPalette.badge,
        onError: AppPalette.onAccent,
        surface: AppPalette.background,
        onSurface: AppPalette.textPrimary,
        onSurfaceVariant: AppPalette.textSecondary,
        surfaceContainerLowest: AppPalette.canvas,
        surfaceContainerLow: AppPalette.surfaceMuted,
        surfaceContainer: AppPalette.surfaceMuted,
        surfaceContainerHigh: AppPalette.surface,
        surfaceContainerHighest: AppPalette.divider,
        outline: AppPalette.textSecondary,
        outlineVariant: AppPalette.divider,
        inverseSurface: AppPalette.textPrimary,
        onInverseSurface: AppPalette.background,
        inversePrimary: AppPalette.onAccent,
        surfaceTint: Colors.transparent,
      ),
      textTheme: AppTheme.darkTheme.textTheme.apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppPalette.accent,
        selectionColor: AppPalette.accent.withValues(alpha: 0.3),
        selectionHandleColor: AppPalette.accent,
      ),
    ),
  );

  /// Shows the bundled fonts' license on the licenses page, as the OFL asks.
  static void registerFontLicenses() {
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString(
        'assets/google_fonts/OFL.txt',
      );
      yield LicenseEntryWithLineBreaks(['google_fonts'], license);
    });
  }

  static ThemeData _withArchivo(ThemeData theme) => theme.copyWith(
    textTheme: GoogleFonts.archivoTextTheme(theme.textTheme),
  );
}

/// [AppPalette] spread across the design system's tokens.
///
/// The grey ramp runs from the background up to the primary text, keeping the
/// palette's slight green cast, and is pinned at [AppPalette.divider]
/// (gray100, card borders) and [AppPalette.textSecondary] (gray500, captions).
const _darkColors = AppThemeColors(
  backgroundWhite: AppPalette.background,
  backgroundSecondary: AppPalette.canvas,
  surface: AppPalette.surfaceMuted,
  surface1: AppPalette.surface,
  surface2: AppPalette.divider,
  surface3: Color(0xFF2E302C),
  surface4: Color(0xFF3A3C37),
  // In the dark theme "white" text is the dark one and "black" the light one.
  textWhite: AppPalette.background,
  textBlack: AppPalette.textPrimary,
  primary100: Color(0x1AC9F26A),
  primary200: Color(0x33C9F26A),
  primary500: AppPalette.accent,
  gray: AppPalette.surfaceMuted,
  gray20: AppPalette.surfaceMuted,
  gray50: AppPalette.surface,
  gray80: AppPalette.surface,
  gray100: AppPalette.divider,
  gray150: Color(0xFF2E302C),
  gray200: Color(0xFF3C3F3A),
  gray300: Color(0xFF5A5E57),
  gray400: Color(0xFF737870),
  gray500: AppPalette.textSecondary,
  gray600: Color(0xFFA3A79F),
  gray700: Color(0xFFBBBEB7),
  gray800: Color(0xFFD0D3CC),
  gray850: Color(0xFFD0D3CC),
  gray900: Color(0xFFE2E4DF),
  gray920: Color(0xFFE2E4DF),
  gray950: AppPalette.textPrimary,
  gray980: AppPalette.textPrimary,
  gray1000: AppPalette.textPrimary,
  opacityWhite80: Color(0xCC000000),
  opacityWhite60: Color(0x99000000),
  opacityWhite40: Color(0x66000000),
  opacityWhite10: Color(0x1A000000),
  opacityBlack60: Color(0x99000000),
  opacityBlack50: Color(0x80000000),
  opacityBlack15: Color(0x26000000),
  opacityBlack2: Color(0x05000000),
  primaryButtonColor: AppPalette.accent,
);
