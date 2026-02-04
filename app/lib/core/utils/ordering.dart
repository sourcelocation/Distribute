String generateNextKey(String prev) {
  if (prev.isEmpty) return 'a';

  int lastCode = prev.codeUnitAt(prev.length - 1);

  if (lastCode == 122) {
    return '${prev}a';
  }

  return prev.substring(0, prev.length - 1) + String.fromCharCode(lastCode + 1);
}

String generateKeyBetween(String? prev, String? next) {
  if (prev == null || prev.isEmpty) {
    if (next == null || next.isEmpty) return 'a';
    return _midpoint("", next);
  }
  if (next == null || next.isEmpty) {
    return _nextKey(prev);
  }

  return _midpoint(prev, next);
}

String _midpoint(String prev, String next) {
  int pLen = prev.length;
  int nLen = next.length;
  int i = 0;

  while (i < pLen && i < nLen && prev.codeUnitAt(i) == next.codeUnitAt(i)) {
    i++;
  }

  int charP = (i < pLen) ? prev.codeUnitAt(i) : 48;

  int charN = (i < nLen) ? next.codeUnitAt(i) : 123;

  if (charN - charP > 1) {
    int midCode = (charP + charN) ~/ 2;
    return prev.substring(0, i) + String.fromCharCode(midCode);
  }

  return '${prev}n';
}

String _nextKey(String prev) {
  int lastCode = prev.codeUnitAt(prev.length - 1);
  if (lastCode < 122) {
    return prev.substring(0, prev.length - 1) +
        String.fromCharCode(lastCode + 1);
  }
  return '${prev}a';
}
