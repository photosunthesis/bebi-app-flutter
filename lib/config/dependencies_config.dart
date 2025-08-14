import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'dependencies_config.config.dart';

@InjectableInit()
Future<void> configureDependencies() async => GetIt.I.init();
