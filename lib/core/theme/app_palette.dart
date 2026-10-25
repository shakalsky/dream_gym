import 'package:flutter/painting.dart';

/// The raw colors of the dark theme.
///
/// Widgets should not reach for these directly: they read
/// `context.appThemeColors`, which `DreamGymTheme.dark` fills from this
/// palette. That way a widget looks right in the light theme too.
abstract final class AppPalette {
  /// Screen and tab bar background.
  static const background = Color(0xFF141513);

  /// Raised cards, such as a live workout bar.
  static const surface = Color(0xFF20221F);

  /// Content and secondary cards.
  static const surfaceMuted = Color(0xFF1B1C1A);

  /// Hairlines: the tab bar's top border, card borders.
  static const divider = Color(0xFF262824);

  static const textPrimary = Color(0xFFEEF0EC);

  /// Subtitles and inactive tabs.
  static const textSecondary = Color(0xFF8A8F86);

  /// The active tab, live indicators, primary actions.
  static const accent = Color(0xFFC9F26A);

  /// Icons and text drawn on [accent].
  static const onAccent = Color(0xFF111111);

  /// Notification dots.
  static const badge = Color(0xFFFF7A59);

  /// The outermost background, behind everything.
  static const canvas = Color(0xFF0B0C0B);
}
