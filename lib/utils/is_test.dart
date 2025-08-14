import 'dart:io';

bool get isTest => Platform.environment.containsKey('FLUTTER_TEST');
