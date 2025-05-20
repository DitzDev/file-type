# file_type

A Dart library for detecting file types from bytes, streams, or URLs by examining the file's binary signature.

## Features

- Detect file types from binary data, streams, files, or URLs
- Supports a wide range of file formats
- Fast detection based on file signatures (magic numbers)
- Cross-platform (works on all Flutter/Dart platforms)
- No external dependencies beyond core Dart libraries and HTTP
- Minimal and efficient implementation

## Supported File Types

### Images
- JPEG (.jpg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)
- BMP (.bmp)
- ICO (.ico)
- TIFF (.tif)
- Canon CR2 (.cr2)
- HEIF/HEIC (.heic)
- AVIF (.avif)
- JPEG XL (.jxl)
- SVG (.svg)

### Documents
- PDF (.pdf)
- DOCX (.docx)
- XLSX (.xlsx)
- PPTX (.pptx)
- DOC (.doc)
- XLS (.xls)
- PPT (.ppt)
- EPUB (.epub)

### Videos
- MP4 (.mp4)
- WebM (.webm)
- MKV (.mkv)
- AVI (.avi)
- QuickTime (.mov)
- FLV (.flv)
- M4V (.m4v)
- 3GP (.3gp)
- 3G2 (.3g2)

### Audio
- MP3 (.mp3)
- WAV (.wav)
- FLAC (.flac)
- OGG (.ogg)
- WebA (.weba)
- AAC (.aac)
- MIDI (.midi)
- M4A (.m4a)
- AMR (.amr)
- AIFF (.aiff)

### Archives & Compressed Files
- ZIP (.zip)
- RAR (.rar)
- 7Z (.7z)
- GZIP (.gz)
- TAR (.tar)
- BZIP2 (.bz2)
- LZIP (.lz)
- LZMA (.lzma)
- XZ (.xz)
- Z (.Z)
- DEB (.deb)
- RPM (.rpm)

### Executables & Binaries
- ELF (.elf)
- EXE (.exe)
- Mach-O (.macho)
- APK (.apk)
- DLL (.dll)
- SWF (.swf)

### Databases & Data Files
- SQLite (.sqlite)

### Fonts
- WOFF (.woff)
- WOFF2 (.woff2)
- EOT (.eot)
- TTF (.ttf)
- OTF (.otf)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  file_type_dart: ^1.0.0
```

Or run:

```
$ flutter pub add file_type_dart
```

## Usage

### Basic Usage

```dart
import 'dart:io';
import 'package:file_type_dart/file_type_dart.dart';

void main() async {
  // Read file as bytes
  final File file = File('example.png');
  final bytes = await file.readAsBytes();
  
  // Detect file type from bytes
  final result = FileType.fromBuffer(bytes);
  
  if (result != null) {
    print('MIME type: ${result.mime}');
    print('Extension: ${result.ext}');
  } else {
    print('Unknown file type');
  }
}
```

### From Stream

```dart
import 'dart:io';
import 'package:file_type_dart/file_type_dart.dart';

void main() async {
  // Get file as stream
  final file = File('example.mp4');
  final stream = file.openRead();
  
  // Detect file type from stream
  final result = await FileType.fromStream(stream);
  
  if (result != null) {
    print('MIME type: ${result.mime}');
    print('Extension: ${result.ext}');
  } else {
    print('Unknown file type');
  }
}
```

### From URL

```dart
import 'package:file_type_dart/file_type_dart.dart';

void main() async {
  // Detect file type from URL
  final result = await FileType.fromUrl('https://example.com/sample.pdf');
  
  if (result != null) {
    print('MIME type: ${result.mime}');
    print('Extension: ${result.ext}');
  } else {
    print('Unknown file type');
  }
}
```

### Type Checking Helpers

```dart
import 'dart:io';
import 'package:file_type_dart/file_type_dart.dart';

void main() async {
  final File file = File('example.jpg');
  final bytes = await file.readAsBytes();
  final result = FileType.fromBuffer(bytes);
  
  if (FileType.isImage(result)) {
    print('This is an image file');
  }
  
  if (FileType.isVideo(result)) {
    print('This is a video file');
  }
  
  if (FileType.isAudio(result)) {
    print('This is an audio file');
  }
  
  if (FileType.isDocument(result)) {
    print('This is a document file');
  }
  
  if (FileType.isArchive(result)) {
    print('This is an archive file');
  }
  
  if (FileType.isFont(result)) {
    print('This is a font file');
  }
  
  if (FileType.isExecutable(result)) {
    print('This is an executable file');
  }
}
```

## Web Support

In web applications, you can detect file types from File objects, Blobs, or ArrayBuffers:

```dart
import 'dart:typed_data';
import 'package:file_type_dart/file_type_dart.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  // Using with file picker
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  
  if (result != null) {
    Uint8List? fileBytes = result.files.first.bytes;
    if (fileBytes != null) {
      final fileType = FileType.fromBuffer(fileBytes);
      print('Selected file type: ${fileType?.mime}');
    }
  }
}
```

## How It Works

This library works by examining the first few bytes of a file to identify its format. These bytes, known as "magic numbers" or file signatures, are specific patterns at the beginning of a file that identify its type.

The detection process:

1. Reads a small buffer from the beginning of the file (default: 4096 bytes)
2. Compares this buffer against known file signatures
3. Returns the matching MIME type and file extension if found

## Limitations

- Some file types share the same signature (like ZIP-based formats)
- Some formats require deeper inspection beyond signatures
- The library checks only the file's signature, not its internal structure

## Contributing

Contributions are welcome! If you'd like to add support for more file types or improve the detection algorithms:

1. Fork the repository
2. Add your signature definitions to the `_signatures` map
3. Submit a pull request

## License

```
MIT License

Copyright (c) 2025 DitzDev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```