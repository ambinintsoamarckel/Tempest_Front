import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static Future<String?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }
}
