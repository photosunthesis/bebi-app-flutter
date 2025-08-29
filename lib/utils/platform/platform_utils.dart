import 'dart:io';

export 'web_platform_utils.dart'
    if (dart.library.io) 'stub_platform_utils.dart';

bool get isTest => Platform.environment.containsKey('FLUTTER_TEST');
