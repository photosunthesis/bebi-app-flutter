import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

final globalContainer = ProviderContainer();

final imagePickerProvider = Provider.autoDispose((ref) => ImagePicker());

final packageInfoProvider = Provider<PackageInfo>(
  (ref) => throw UnimplementedError('Override this in main.dart'),
);
