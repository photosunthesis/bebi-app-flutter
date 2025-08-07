import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppDependencies {
  // Add other dependencies here
  ImagePicker get imagePicker => ImagePicker();
}
