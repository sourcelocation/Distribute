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
    outline: Color.fromARGB(255, 50, 50, 50),
    outlineVariant: Color.fromARGB(255, 50, 50, 50),
  );
}

TextTheme createTextTheme() {
  return TextTheme(
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Colors.grey[300],
      letterSpacing: -0.2,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      color: Colors.grey[500],
      letterSpacing: -0.1,
    ),
    titleMedium: const TextStyle(
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineSmall: const TextStyle(
      fontWeight: FontWeight.bold,
      letterSpacing: -0.8,
    ),
  );
}

InputDecorationTheme createInputDecorationTheme(ColorScheme colorScheme) {
  return InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surfaceContainer.withAlpha(150),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: colorScheme.outline, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: colorScheme.outline, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    ),
    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
    labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
  );
}

CardThemeData createCardTheme(ColorScheme colorScheme) {
  return CardThemeData(
    elevation: 0,
    color: colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      // side: BorderSide(color: colorScheme.outline, width: 1),
    ),
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
  );
}

DialogThemeData createDialogTheme(ColorScheme colorScheme) {
  return DialogThemeData(
    backgroundColor: colorScheme.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: colorScheme.outline, width: 1),
    ),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
}

DividerThemeData createDividerTheme() {
  return DividerThemeData(
    indent: 16.0,
    endIndent: 16.0,
    color: const Color.fromARGB(255, 50, 50, 50),
    thickness: 1.0,
    space: 16.0,
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

ListTileThemeData createListTileTheme(ColorScheme colorScheme) {
  return ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    visualDensity: VisualDensity.standard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    horizontalTitleGap: 12,
    iconColor: colorScheme.secondary,
    titleTextStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
  );
}

SnackBarThemeData createSnackBarTheme() {
  return SnackBarThemeData(
    backgroundColor: const Color.fromARGB(255, 25, 25, 25),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      letterSpacing: -0.1,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color.fromARGB(255, 50, 50, 50)),
    ),
    elevation: 4,
  );
}

IconThemeData createIconTheme(ColorScheme colorScheme) {
  return IconThemeData(color: colorScheme.onSurface, size: 24);
}

FloatingActionButtonThemeData createFabTheme(ColorScheme colorScheme) {
  return FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ThemeData createDarkTheme() {
  final colorScheme = createColorScheme(Brightness.dark);

  return ThemeData(
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: createTextTheme(),
    dividerTheme: createDividerTheme(),
    inputDecorationTheme: createInputDecorationTheme(colorScheme),
    appBarTheme: createAppBarTheme(colorScheme),
    listTileTheme: createListTileTheme(colorScheme),
    cardTheme: createCardTheme(colorScheme),
    dialogTheme: createDialogTheme(colorScheme),
    iconTheme: createIconTheme(colorScheme),
    floatingActionButtonTheme: createFabTheme(colorScheme),
    snackBarTheme: createSnackBarTheme(),
    dividerColor: const Color.fromARGB(255, 50, 50, 50),
    navigationBarTheme: createNavigationBarTheme(colorScheme),
  );
}

NavigationBarThemeData createNavigationBarTheme(ColorScheme colorScheme) {
  return NavigationBarThemeData(
    backgroundColor: colorScheme.surface,
    indicatorColor: Colors.transparent,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Colors.white);
      }
      return IconThemeData(color: Colors.grey);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      }
      return const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
    }),
  );
}

ThemeData createLightTheme() {
  final colorScheme = createColorScheme(Brightness.light);

  return ThemeData(
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    textTheme: createTextTheme(),
    dividerTheme: createDividerTheme(),
    inputDecorationTheme: createInputDecorationTheme(colorScheme),
    appBarTheme: createAppBarTheme(colorScheme),
    listTileTheme: createListTileTheme(colorScheme),
    cardTheme: createCardTheme(colorScheme),
    dialogTheme: createDialogTheme(colorScheme),
    iconTheme: createIconTheme(colorScheme),
    floatingActionButtonTheme: createFabTheme(colorScheme),
    snackBarTheme: createSnackBarTheme(),
    dividerColor: const Color.fromARGB(255, 50, 50, 50),
    navigationBarTheme: createNavigationBarTheme(colorScheme),
  );
}
