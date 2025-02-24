import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whispr_chat_app/themes/custom_color.dart';

class AppTheme extends ChangeNotifier {
  bool _isDarkMode = false;
  Color _primaryColor = const Color(0xFF6366F1); // Your default Indigo

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void updatePrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          surface: const Color(0xFFFFFFFF),
          primary: _primaryColor, // Using the changeable primary color
          secondary: const Color(0xFF64748B), // Slate
          tertiary: const Color(0xFFE2E8F0),
          inversePrimary:
              _primaryColor.withOpacity(0.8), // Darker shade of primary
          error: const Color(0xFFDC2626),
        ),
        extensions: <ThemeExtension<dynamic>>[
          const CustomColors(
            quaternary: Color(0xFFFFFFFF),
          ),
        ],
        textTheme: GoogleFonts.museoModernoTextTheme(
          const TextTheme(
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF1E293B),
          primary: _primaryColor,
          secondary: const Color(0xFF94A3B8),
          tertiary: const Color(0xFF334155),
          inversePrimary: _primaryColor.withOpacity(0.8),
          error: const Color(0xFFDC2626),
        ),
        extensions: <ThemeExtension<dynamic>>[
          const CustomColors(
            quaternary: Color(0xFF334155),
          ),
        ],
        textTheme: GoogleFonts.museoModernoTextTheme(
          ThemeData.dark().textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF334155),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF475569)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF475569)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

  ThemeData getCurrentTheme() => _isDarkMode ? darkTheme : lightTheme;
}
