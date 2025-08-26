import 'package:intl/intl.dart';

extension StringExtensions on String {
  DateTime? toDateTime(String format) =>
      DateFormat(format).tryParseStrict(this);

  DateTime? toEEEMMMdyyyyHHmmaaDate() => toDateTime('EEE MMM d, yyyy h:mm a');

  DateTime? toHHmmaTime() => toDateTime('h:mm a');

  String toSnakeCase() {
    final input = trim();
    if (input.isEmpty) return input;

    return input
        // Split camelCase or digitsBeforeUppercase
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        // Split ALLCAPS before PascalCase
        .replaceAllMapped(RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) {
          final head = m[1]!;
          final tail = m[2]!;
          return '${head.substring(0, head.length - 1)}_${head.substring(head.length - 1)}${tail.substring(1)}';
        })
        // Replace spaces/hyphens with underscores
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        // Collapse multiple underscores
        .replaceAll(RegExp(r'_+'), '_')
        // Remove leading/trailing underscores
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .toLowerCase();
  }

  String toTitleCase() {
    final trimmed = trim();
    if (trimmed.isEmpty) return trimmed;

    return trimmed
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }
}
