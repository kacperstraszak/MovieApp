import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              const Color.fromARGB(255, 134, 42, 35),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white),
          color: Color.fromARGB(255, 134, 42, 35),
          centerTitle: true,
          elevation: 4,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[10],
        iconTheme: const IconThemeData(color: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 134, 42, 35),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
            fillColor: Color.fromARGB(255, 230, 145, 139)));
  }
}
