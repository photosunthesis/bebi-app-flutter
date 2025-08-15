import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dependencies_config.config.dart';

@InjectableInit()
Future<void> configureDependencies() async => GetIt.I.init();

@module
abstract class OtherDependencies {
  ImagePicker get imagePicker => ImagePicker();

  @preResolve
  Future<PackageInfo> get packageInfo async => PackageInfo.fromPlatform();

  Dio get dio =>
      Dio(
          BaseOptions(
            connectTimeout: 5.seconds,
            receiveTimeout: 5.seconds,
            sendTimeout: 5.seconds,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            responseType: ResponseType.json,
          ),
        )
        ..interceptors.addAll([
          if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
        ]);
}
