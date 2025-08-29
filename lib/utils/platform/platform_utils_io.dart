import 'dart:io';

bool get kIsTest => Platform.environment.containsKey('FLUTTER_TEST');

bool get kIsPwa => false;

bool get kIsWebiOS => false;
