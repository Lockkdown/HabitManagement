import 'dart:convert';

/// Helper để decode JWT token
class JwtDecoder {
  /// Decode JWT và lấy payload
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Lấy role từ JWT token
  static String? getRole(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    // JWT role có thể ở "role" hoặc "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
    return payload['role'] ?? 
           payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
  }

  /// Check xem user có phải Admin không
  static bool isAdmin(String token) {
    final role = getRole(token);
    return role == 'Admin';
  }
}
