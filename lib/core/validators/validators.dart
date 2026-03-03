// ============================================================
// PriVault – Validators (BR-01)
// ============================================================

/// Validates password strength per BR-01.
/// Requirements: min 10 chars, uppercase, lowercase, number, special char.
String? validatePassword(String? password) {
  if (password == null || password.isEmpty) {
    return 'Password is required';
  }
  if (password.length < 10) {
    return 'Password must be at least 10 characters';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password must contain an uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Password must contain a lowercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password must contain a number';
  }
  if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:\x27"\\|,.<>/?]').hasMatch(password)) {
    return 'Password must contain a special character';
  }
  return null;
}

/// Validates email format.
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(email)) {
    return 'Please enter a valid email';
  }
  return null;
}

/// Returns password strength 0.0 to 1.0 for the progress indicator.
double passwordStrength(String password) {
  if (password.isEmpty) return 0.0;
  double score = 0.0;
  if (password.length >= 10) score += 0.2;
  if (password.length >= 14) score += 0.1;
  if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
  if (RegExp(r'[a-z]').hasMatch(password)) score += 0.15;
  if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
  if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:\x27"\\|,.<>/?]').hasMatch(password)) score += 0.2;
  return score.clamp(0.0, 1.0);
}
