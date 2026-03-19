import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/notification_service.dart';
import 'utils/theme_manager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeManager(),
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'Task Manager Pro',
            debugShowCheckedModeBanner: false,
            themeMode: themeManager.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Color(0xFF6C63FF),
              colorScheme: ColorScheme.light(
                primary: Color(0xFF6C63FF),
                secondary: Color(0xFF03DAC6),
                background: Colors.white,
                surface: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
              // 🔥 FIXED: CardTheme ko CardThemeData mein convert kiya
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Add this for better compatibility
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Color(0xFF6C63FF),
              colorScheme: ColorScheme.dark(
                primary: Color(0xFF6C63FF),
                secondary: Color(0xFF03DAC6),
                background: Color(0xFF121212),
                surface: Color(0xFF1E1E1E),
              ),
              scaffoldBackgroundColor: Color(0xFF121212),
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.dark().textTheme,
              ),
              // 🔥 FIXED: Dark theme card theme
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color(0xFF2C2C2C),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              useMaterial3: true,
            ),
            home: HomeScreen(),
            routes: {
              '/settings': (context) => SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}