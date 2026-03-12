import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Primary colors
  static const Color primaryBackground = Color(0xFF0B0B0B);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color accentOrange = Color(0xFFFF6A00);
  static const Color secondaryBackground = Color(0xFF1A1A1A);
  static const Color inactiveText = Color(0xFF8A8A8A);
  static const Color successGreen = Color(0xFF00C851);
  static const Color warningRed = Color(0xFFFF4444);
  static const Color subtleBorder = Color(0xFF2D2D2D);
  static const Color timeDisplay = Color(0xFFFFFFFF);
  static const Color challengeAccent = Color(0xFFFFB84D);

  // Light theme colors (minimal usage - app is dark-first)
  static const Color primaryLight = Color(0xFFFF6A00);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color errorLight = Color(0xFFFF4444);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onBackgroundLight = Color(0xFF0B0B0B);
  static const Color onSurfaceLight = Color(0xFF0B0B0B);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color shadowLight = Color(0x33000000);

  // Dark theme colors
  static const Color primaryDark = Color(0xFFFF6A00);
  static const Color backgroundDark = Color(0xFF0B0B0B);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color errorDark = Color(0xFFFF4444);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color dividerDark = Color(0xFF2D2D2D);
  static const Color shadowDark = Color(0x33000000);

  static const Color textHighEmphasisDark = Color(0xFFFFFFFF);
  static const Color textMediumEmphasisDark = Color(0xFF8A8A8A);
  static const Color textDisabledDark = Color(0x61FFFFFF);

  static const Color textHighEmphasisLight = Color(0xFF0B0B0B);
  static const Color textMediumEmphasisLight = Color(0xFF555555);
  static const Color textDisabledLight = Color(0x610B0B0B);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryLight,
      onPrimaryContainer: onPrimaryLight,
      secondary: challengeAccent,
      onSecondary: Color(0xFF0B0B0B),
      secondaryContainer: challengeAccent,
      onSecondaryContainer: Color(0xFF0B0B0B),
      tertiary: successGreen,
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: successGreen,
      onTertiaryContainer: Color(0xFFFFFFFF),
      error: errorLight,
      onError: Color(0xFFFFFFFF),
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: textMediumEmphasisLight,
      outline: dividerLight,
      outlineVariant: dividerLight,
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      foregroundColor: onSurfaceLight,
      elevation: 0,
      shadowColor: shadowLight,
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 2.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: dividerLight, width: 1),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textMediumEmphasisLight,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: onPrimaryLight,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryLight,
        backgroundColor: primaryLight,
        minimumSize: Size(88, 48),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        minimumSize: Size(88, 48),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: primaryLight, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        minimumSize: Size(88, 48),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: true),
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceLight,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: TextStyle(color: textMediumEmphasisLight),
      hintStyle: TextStyle(color: textDisabledLight),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryLight;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withValues(alpha: 0.5);
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryLight;
        return null;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryLight;
        return null;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryLight),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLight,
      thumbColor: primaryLight,
      overlayColor: primaryLight.withValues(alpha: 0.2),
      inactiveTrackColor: primaryLight.withValues(alpha: 0.3),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: textMediumEmphasisLight,
      indicatorColor: primaryLight,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: onSurfaceLight,
      contentTextStyle: TextStyle(color: surfaceLight),
      actionTextColor: primaryLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: cardLight),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: Color(0xFF2A1500),
      onPrimaryContainer: onPrimaryDark,
      secondary: challengeAccent,
      onSecondary: Color(0xFF0B0B0B),
      secondaryContainer: Color(0xFF2A1E00),
      onSecondaryContainer: challengeAccent,
      tertiary: successGreen,
      onTertiary: Color(0xFF0B0B0B),
      tertiaryContainer: Color(0xFF003A14),
      onTertiaryContainer: successGreen,
      error: errorDark,
      onError: Color(0xFF0B0B0B),
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: textMediumEmphasisDark,
      outline: dividerDark,
      outlineVariant: dividerDark,
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,
    appBarTheme: AppBarThemeData(
      backgroundColor: backgroundDark,
      foregroundColor: onSurfaceDark,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: subtleBorder, width: 1),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: secondaryBackground,
      selectedItemColor: accentOrange,
      unselectedItemColor: inactiveText,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: accentOrange,
        minimumSize: Size(88, 48),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentOrange,
        minimumSize: Size(88, 48),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: accentOrange, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentOrange,
        minimumSize: Size(88, 48),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: false),
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: secondaryBackground,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: subtleBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: subtleBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: accentOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: warningRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: warningRed, width: 2),
      ),
      labelStyle: TextStyle(color: inactiveText),
      hintStyle: TextStyle(color: inactiveText),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentOrange;
        return inactiveText;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentOrange.withValues(alpha: 0.4);
        }
        return subtleBorder;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentOrange;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Color(0xFFFFFFFF)),
      side: BorderSide(color: subtleBorder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentOrange;
        return inactiveText;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentOrange,
      linearTrackColor: subtleBorder,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentOrange,
      thumbColor: accentOrange,
      overlayColor: accentOrange.withValues(alpha: 0.2),
      inactiveTrackColor: subtleBorder,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentOrange,
      unselectedLabelColor: inactiveText,
      indicatorColor: accentOrange,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: secondaryBackground,
      contentTextStyle: TextStyle(color: primaryText),
      actionTextColor: accentOrange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: subtleBorder, width: 1),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: subtleBorder, width: 1),
      ),
      textStyle: TextStyle(color: primaryText),
    ),
    dialogTheme: DialogThemeData(backgroundColor: cardDark),
  );

  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color high = isLight ? textHighEmphasisLight : textHighEmphasisDark;
    final Color medium = isLight
        ? textMediumEmphasisLight
        : textMediumEmphasisDark;
    final Color disabled = isLight ? textDisabledLight : textDisabledDark;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        color: high,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        color: high,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: high,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: high,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: high,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: high,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: high,
        letterSpacing: 0.15,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: high,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: high,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: high,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: high,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: medium,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: high,
        letterSpacing: 1.25,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: medium,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: disabled,
        letterSpacing: 1.5,
      ),
    );
  }

  // Reusable shadow styles
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration alarmEntrance = Duration(milliseconds: 150);
}
