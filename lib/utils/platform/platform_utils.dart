import 'package:flutter/foundation.dart';

export 'web_platform_utils.dart' if (dart.library.io) 'io_platform_utils.dart';

bool get kIsAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
