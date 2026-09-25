/// Form validators mirroring the backend's zod schemas and password policy
/// (Tradingbook-backend/src/modules/auth/policy.ts), so users get the same
/// answer before the round trip.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email';
    if (value.length > 254 || !_email.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? displayName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your name';
    if (value.length > 80) return 'Keep it under 80 characters';
    return null;
  }

  static const _banned = {
    'password',
    'password1',
    'password123',
    'passw0rd',
    '12345678',
    '123456789',
    '1234567890',
    'qwertyui',
    'qwerty123',
    'iloveyou',
    'trustno1',
    'letmein1',
    'admin123',
    'welcome1',
    'tradingbook',
  };

  static final _classes = [
    RegExp(r'\p{Ll}', unicode: true),
    RegExp(r'\p{Lu}', unicode: true),
    RegExp(r'\p{N}', unicode: true),
    RegExp(r'\p{Lo}', unicode: true),
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
  ];

  /// 8–200 chars; not a constantly-stuffed password; 14+ chars needs 5
  /// distinct characters, shorter needs two character classes.
  static String? newPassword(String? v) {
    final value = v ?? '';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (value.length > 200) return 'Password must be at most 200 characters';
    if (_banned.contains(value.toLowerCase())) {
      return 'Password is too common — choose a less guessable one';
    }
    final distinct = value.runes.toSet().length;
    if (value.length >= 14) {
      return distinct >= 5 ? null : 'Password repeats too few distinct characters';
    }
    final classes = _classes.where((re) => re.hasMatch(value)).length;
    if (classes < 2) {
      return 'Mix letters with numbers or symbols (or use 14+ characters)';
    }
    return null;
  }
}
