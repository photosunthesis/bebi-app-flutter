class SimpleException implements Exception {
  const SimpleException(this.message);

  final String message;

  @override
  String toString() => message;
}
