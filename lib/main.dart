import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'services/db_helper.dart';
import 'screens/loading_screen.dart'; // UBAH INI - dari splash_screen ke loading_screen
import 'utils/constants.dart';

void main() {
  // Initialize FFI for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Cafe Management System',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.brown,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: const AppBarTheme(elevation: 2, centerTitle: true),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.brown,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.grey[900],
            ),
            themeMode: themeProvider.themeMode,
            home: const LoadingScreen(), // UBAH INI - Ke loading screen
          );
        },
      ),
    );
  }
}

// Theme Provider for Dark Mode
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
