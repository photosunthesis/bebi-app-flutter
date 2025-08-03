import 'dart:ui';

extension ColorExtensions on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      (a * 255.0).round(),
      ((r * (1 - amount)) * 255.0).round(),
      ((g * (1 - amount)) * 255.0).round(),
      ((b * (1 - amount)) * 255.0).round(),
    );
  }

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      (a * 255.0).round(),
      ((r + (255 - r)) * amount).round(),
      ((g + (255 - g)) * amount).round(),
      ((b + (255 - b)) * amount).round(),
    );
  }
}
