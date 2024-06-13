import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static Future<String?> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }
}
