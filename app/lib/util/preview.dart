import 'package:distributeapp/theme.dart';
import 'package:flutter/widget_previews.dart';

final class ThemePreview extends Preview {
  const ThemePreview({
    super.name,
    super.group,
    super.size,
    super.textScaleFactor,
    super.wrapper,
    super.brightness,
    super.localizations,
  }) : super(theme: ThemePreview.themeBuilder);

  static PreviewThemeData themeBuilder() {
    return PreviewThemeData(
      materialLight: createLightTheme(),
      materialDark: createDarkTheme(),
    );
  }
}
