import 'package:envied/envied.dart';
import 'package:injectable/injectable.dart';

part 'env.g.dart';

@lazySingleton
@Envied(path: '.env', useConstantCase: true, obfuscate: true)
class Env {
  @EnviedField()
  final String r2Endpoint = _Env.r2Endpoint;

  @EnviedField()
  final String r2AccessKeyId = _Env.r2AccessKeyId;

  @EnviedField()
  final String r2SecretAccessKey = _Env.r2SecretAccessKey;

  @EnviedField()
  final String r2BucketName = _Env.r2BucketName;
}
