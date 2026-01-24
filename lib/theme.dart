import 'package:flutter/material.dart';

ColorScheme createColorScheme(Brightness brightness) {
  return ColorScheme(
    brightness: brightness,
    primary: Color.fromARGB(255, 0, 255, 162),
    onPrimary: Color.fromARGB(255, 29, 29, 29),
    secondary: Color.fromRGBO(128, 128, 128, 1),
    onSecondary: Colors.white,
    secondaryContainer: Color.fromARGB(255, 25, 25, 25),
    surface: Color.fromARGB(255, 18, 18, 18),
    onSurface: Colors.white,
    surfaceContainer: Color.fromARGB(255, 24, 24, 24),
    onSurfaceVariant: Colors.white,
    errorContainer: const Color.fromARGB(34, 244, 67, 54),
    onErrorContainer: Colors.red,
    error: Colors.red,
    onError: Colors.white,
  );
}

TextTheme createTextTheme() {
  return TextTheme(
    bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[300]),
    bodySmall: TextStyle(fontSize: 14, color: Colors.grey[500]),
  );
}

InputDecorationTheme createInputDecorationTheme() {
  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[900]?.withAlpha(100),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.grey[500]),
    labelStyle: TextStyle(color: Colors.grey[500]),
  );
}

DividerThemeData createDividerTheme() {
  return DividerThemeData(
    indent: 16.0,
    endIndent: 16.0,
    color: const Color.fromARGB(255, 50, 50, 50),
    thickness: 1.0,
    space: 32.0,
  );
}

AppBarTheme createAppBarTheme(ColorScheme colorScheme) {
  return AppBarTheme(
    backgroundColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.white),
    // foregroundColor: Colors.red,
    surfaceTintColor: colorScheme.secondary,
  );
}

ListTileThemeData createListTileTheme() {
  return ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    visualDensity: VisualDensity.compact,
  );
}

ThemeData createDarkTheme() {
  final colorScheme = createColorScheme(Brightness.dark);

  return ThemeData(
    splashColor: Colors.transparent,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: createTextTheme(),
    dividerTheme: createDividerTheme(),
    inputDecorationTheme: createInputDecorationTheme(),
    appBarTheme: createAppBarTheme(colorScheme),
    listTileTheme: createListTileTheme(),
    dividerColor: const Color.fromARGB(255, 50, 50, 50),
  );
}

ThemeData createLightTheme() {
  final colorScheme = createColorScheme(Brightness.light);

  return ThemeData(
    splashColor: Colors.transparent,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    textTheme: createTextTheme(),
    dividerTheme: createDividerTheme(),
    inputDecorationTheme: createInputDecorationTheme(),
    appBarTheme: createAppBarTheme(colorScheme),
    listTileTheme: createListTileTheme(),
    dividerColor: const Color.fromARGB(255, 50, 50, 50),
  );
}
