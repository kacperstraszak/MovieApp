bool onlyAllowedCharacters(String password) {
  final allowed = RegExp(r'^[A-Za-z0-9!@#\$%^&*(),+.?":{}|<>]+$');
  return allowed.hasMatch(password);
}

String? getPasswordError(String password) {
  if (password.length < 8) return 'Password must be at least 8 characters long.';
  if (password.length > 64) return 'Password must not exceed 64 characters.';
  if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Password must contain at least one uppercase letter.';
  if (!RegExp(r'[a-z]').hasMatch(password)) return 'Password must contain at least one lowercase letter.';
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Password must contain at least one digit.';
  if (!RegExp(r'[!@#\$%^&*(),.?"+:{}|<>]').hasMatch(password)) return 'Password must contain at least one special character.';
  if (!onlyAllowedCharacters(password)) return 'Password contains invalid characters.';
  
  return null; // wszystko OK
}

String? getUsernameError(String username) {
  final regex = RegExp(r'^[a-zA-Z0-9_]+$');
  if (username.length <=3) return 'Username has to be at least 3 characters long.';
  if (username.length >=32) return 'Username must not exceed 32 characters.';
  if (!regex.hasMatch(username)) return 'Only letters, numbers and "_" allowed';
  return null;
}