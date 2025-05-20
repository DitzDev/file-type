import 'package:file_type/file_type.dart';

void main() async {
  // Base64 encoded PNG image
  final base64Data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  
  final result = await FileType.fromBlob(base64Data);
  
  if (result != null) {
    print('File detected: ${result.mime} (${result.ext})');
  }
}
