// ============================================================
// PriVault – Shared Utility Functions
// ============================================================

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format bytes into a human-readable string (e.g., "1.5 GB").
String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  final i = (log(bytes) / log(1024)).floor();
  final value = bytes / pow(1024, i);
  return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
}

/// Format a DateTime to a relative string (e.g., "2 hours ago").
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  return DateFormat.yMMMd().format(dateTime);
}

/// Format a DateTime for display.
String formatDate(DateTime dateTime) {
  return DateFormat.yMMMd().format(dateTime);
}

/// Format time for chat messages.
String formatChatTime(DateTime dateTime) {
  return DateFormat.jm().format(dateTime);
}

/// Generate cryptographically secure random bytes.
Uint8List generateSecureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}

/// Get the file extension from a filename.
String getFileExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) return '';
  return filename.substring(dot + 1).toLowerCase();
}

/// Get an icon for a file based on its extension.
IconData getFileIcon(String extension) {
  switch (extension.toLowerCase()) {
    // Images
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
    case 'heic':
    case 'heif':
      return Icons.image_rounded;
    // Videos
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
    case 'webm':
      return Icons.videocam_rounded;
    // Audio
    case 'mp3':
    case 'wav':
    case 'aac':
    case 'flac':
    case 'ogg':
      return Icons.audiotrack_rounded;
    // Documents
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'doc':
    case 'docx':
      return Icons.description_rounded;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_rounded;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow_rounded;
    case 'txt':
    case 'md':
    case 'csv':
      return Icons.article_rounded;
    // Code
    case 'dart':
    case 'py':
    case 'js':
    case 'ts':
    case 'java':
    case 'kt':
    case 'swift':
    case 'json':
    case 'yaml':
    case 'xml':
    case 'html':
    case 'css':
      return Icons.code_rounded;
    // Archives
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Icons.archive_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

/// Get a color for a file based on its extension.
Color getFileColor(String extension) {
  switch (extension.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
    case 'heic':
      return const Color(0xFF14B8A6);
    case 'mp4':
    case 'mov':
    case 'avi':
      return const Color(0xFF8B5CF6);
    case 'pdf':
      return const Color(0xFFEF4444);
    case 'doc':
    case 'docx':
      return const Color(0xFF3B82F6);
    case 'xls':
    case 'xlsx':
      return const Color(0xFF22C55E);
    default:
      return const Color(0xFF94A3B8);
  }
}

/// Truncate a string to a maximum length with ellipsis.
String truncateString(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}…';
}

/// Validate email format.
bool isValidEmail(String email) {
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

/// Calculate password strength (0.0 to 1.0).
double calculatePasswordStrength(String password) {
  if (password.isEmpty) return 0.0;

  double strength = 0.0;

  // Length score
  if (password.length >= 8) strength += 0.2;
  if (password.length >= 12) strength += 0.1;
  if (password.length >= 16) strength += 0.1;

  // Character variety
  if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
  if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
  if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

  return strength.clamp(0.0, 1.0);
}

/// Get password strength label.
String getPasswordStrengthLabel(double strength) {
  if (strength < 0.3) return 'Weak';
  if (strength < 0.5) return 'Fair';
  if (strength < 0.7) return 'Good';
  if (strength < 0.9) return 'Strong';
  return 'Very Strong';
}

/// Get password strength color.
Color getPasswordStrengthColor(double strength) {
  if (strength < 0.3) return const Color(0xFFEF4444);
  if (strength < 0.5) return const Color(0xFFF59E0B);
  if (strength < 0.7) return const Color(0xFF3B82F6);
  if (strength < 0.9) return const Color(0xFF22C55E);
  return const Color(0xFF14B8A6);
}
