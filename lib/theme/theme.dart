// theme/theme.dart
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proj/theme/divider_styles.dart';

extension ColorsExtension on FColors {
  Color get accent => const Color(0xFF38bdf8); // sky-something
}

extension TextExtension on FTypography {
  // idk why height needs to be zero for things to be centered (header title for ex)

  TextStyle get baseSemibold => base.copyWith(
    fontWeight: FontWeight.bold,
    fontFamily: 'IBMPlexMono',
    height: 0,
  );

  TextStyle get lgSemibold => lg.copyWith(
    fontWeight: FontWeight.bold,
    fontFamily: 'IBMPlexMono',
    height: 0,
  );

  TextStyle get xlSemibold => xl3.copyWith(
    fontWeight: FontWeight.bold,
    fontFamily: 'IBMPlexMono',
    height: 0,
  );

  TextStyle get smGrey => sm.copyWith(
    fontFamily: 'IBMPlexMono',
    height: 0,
    color: Color(0xFFa8a29e), // stone-400
  );

  TextStyle get smError => sm.copyWith(
    fontFamily: 'IBMPlexMono',
    height: 0,
    color: Color(0xFF991b1b), // red-800
    fontWeight: FontWeight.bold,
  );
}

/// See https://forui.dev/docs/themes#customize-themes for more information.
FThemeData get zincDark {
  const colors = FColors(
    brightness: Brightness.dark,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    barrier: Color(0xFF000000), // black
    background: Color(0xFF000000), // black
    foreground: Color.fromRGBO(250, 250, 249, 1), // stone-100
    primary: Color(0xFFFAFAF9), // stone-100
    primaryForeground: Color(0xFF1C1917), // stone-800
    secondary: Color(0xFF1C1917), // stone-800
    secondaryForeground: Color(0xFFa8a29e), // stone-400
    muted: Color(0xFF27272A), //
    mutedForeground: Color(0xFFA1A1AA), //
    destructive: Color(0xFF991b1b), // red-800
    destructiveForeground: Color(0xFFFAFAFA), //
    error: Color(0xFF991b1b), // red-800
    errorForeground: Color(0xFFFAFAFA), //
    border: Color(0xFF44403C), // stone-700
  );

  final typography = _typography(colors: colors);
  final style = _style(colors: colors, typography: typography);

  final customDividerStyles = dividerStyles(colors: colors, style: style);

  return FThemeData(
    colors: colors,
    typography: typography,
    style: style,
    dividerStyles: customDividerStyles,
  );
}

FTypography _typography({
  required FColors colors,
  String defaultFontFamily = 'IBMPlexMono',
}) => FTypography(
  xs: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 12,
    height: 1,
  ),
  sm: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 14,
    height: 1.25,
  ),
  base: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 16,
    height: 1.5,
  ),
  lg: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 18,
    height: 1.75,
  ),
  xl: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 20,
    height: 1.75,
  ),
  xl2: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 22,
    height: 2,
  ),
  xl3: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 30,
    height: 2.25,
  ),
  xl4: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 36,
    height: 2.5,
  ),
  xl5: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 48,
    height: 1,
  ),
  xl6: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 60,
    height: 1,
  ),
  xl7: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 72,
    height: 1,
  ),
  xl8: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 96,
    height: 1,
  ),
);

FStyle _style({required FColors colors, required FTypography typography}) =>
    FStyle(
      formFieldStyle: FFormFieldStyle.inherit(
        colors: colors,
        typography: typography,
      ),
      focusedOutlineStyle: FFocusedOutlineStyle(
        color: colors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      iconStyle: IconThemeData(color: colors.primary, size: 20),
      tappableStyle: FTappableStyle(),
      borderRadius: const FLerpBorderRadius.all(Radius.circular(8), min: 24),
      borderWidth: 1,
      pagePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shadow: const [
        BoxShadow(
          color: Color(0x0d000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );
