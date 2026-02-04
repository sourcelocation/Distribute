enum VinylStyle {
  modern,
  transparent;

  String get displayName {
    switch (this) {
      case VinylStyle.modern:
        return 'Modern';
      case VinylStyle.transparent:
        return 'Transparent';
    }
  }
}
