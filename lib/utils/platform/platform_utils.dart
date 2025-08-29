import 'package:flutter/foundation.dart';

export 'platform_utils_io.dart'
    if (dart.library.html) 'platform_utils_web.dart';

bool get kIsAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
