import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF131313);
  static const Color card = Color(0xFF171717);
  static const Color cardAlt = Color(0xFF1D1D1D);
  static const Color border = Color(0x1AFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  static const Color accent = Color(0xFFFF9800);
  static const Color accentSoft = Color(0x26FF9800);
  static const Color accentGlow = Color(0x66FF9800);

  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF8F8F8F);
  static const Color textMuted = Color(0xFF5C5C5C);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0x26EF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0x2622C55E);
  static const Color midStock = Color(0xFFFFA726);
  static const Color midStockSoft = Color(0x26FFA726);
  static const Color lowStock = Color(0xFFEF4444);
}

class AppGlows {
  static List<BoxShadow> accent({double blur = 20, double spread = 0}) => [
        BoxShadow(color: AppColors.accent.withOpacity(0.35), blurRadius: blur, spreadRadius: spread),
      ];

  static List<BoxShadow> softCard() => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
      ];
}

class AppTheme {
  static ThemeData get darkIndustrial {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.accent),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      cardColor: AppColors.card,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, letterSpacing: 0.4),
        errorStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardAlt,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: AppGlows.accent(blur: 24),
            ),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.4),
            ),
          ),
          Text(
            'GWC',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: size * 0.22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          Positioned(
            bottom: size * 0.02,
            right: size * 0.02,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 1.5),
              ),
              child: Icon(Icons.sync_rounded, color: AppColors.accent, size: size * 0.16),
            ),
          ),
        ],
      ),
    );
  }
}