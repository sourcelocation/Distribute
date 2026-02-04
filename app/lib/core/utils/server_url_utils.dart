class ServerUrlUtils {
  static String normalizeUrl(String input) {
    if (input.isEmpty) return input;
    if (input.contains('://')) return input;

    // Default to HTTP for local addresses, HTTPS for everything else
    final uri = Uri.tryParse('http://$input');
    if (uri == null) return 'https://$input';

    final host = uri.host;

    // Check for localhost or .local (mDNS)
    if (host == 'localhost' || host.endsWith('.local')) {
      return 'http://$input';
    }

    // Check for private IPv4 ranges
    final parts = host.split('.');
    if (parts.length == 4) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);

      if (p0 != null) {
        if (p0 == 127) return 'http://$input';
        if (p0 == 10) return 'http://$input';
        if (p0 == 192 && p1 == 168) return 'http://$input';
        if (p0 == 172 && p1 != null && p1 >= 16 && p1 <= 31) {
          return 'http://$input';
        }
      }
    }

    return 'https://$input';
  }
}
