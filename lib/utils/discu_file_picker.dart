import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class FilePickerUtil {
  static Future<String?> pickFile() async {
    if (await _requestPermission(Permission.storage)) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        return result.files.single.path;
      }
    }
    return null;
  }

  static Future<String?> pickAudio() async {
    if (await _requestPermission(Permission.storage)) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null) {
        return result.files.single.path;
      }
    }
    return null;
  }

  static Future<String?> saveFile(String filePath) async {
    if (await _requestPermission(Permission.storage)) {
      try {
        final fileName = path.basename(filePath);
        final directory = await getExternalStorageDirectory();
        final newPath = path.join(directory!.path, fileName);
        final savedFile = await File(filePath).copy(newPath);
        return savedFile.path;
      } catch (e) {
        print('Error saving file: $e');
        return null;
      }
    }
    return null;
  }

  static Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status == PermissionStatus.granted;
  }
}
