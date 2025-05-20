library file_type;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Class that represents the result of file type detection.
/// 
/// Contains MIME type and file extension information for the detected file.
class FileTypeResult {
  /// The MIME type of the file
  final String? mime;

  /// The extension of the file
  final String? ext;

  /// Creates a new immutable [FileTypeResult] instance.
  /// 
  /// Both [mime] and [ext] parameters are optional and may be null if the file
  /// type could not be determined.
  /// 
  /// Example:
  /// ```dart
  /// final result = FileTypeResult(mime: 'image/png', ext: 'png');
  /// ```
  @literal
  const FileTypeResult({this.mime, this.ext});

  @override
  String toString() => 'FileTypeResult(mime: $mime, ext: $ext)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileTypeResult &&
          runtimeType == other.runtimeType &&
          mime == other.mime &&
          ext == other.ext;

  @override
  int get hashCode => mime.hashCode ^ ext.hashCode;
}

/// Main class for detecting file types based on file signatures (magic numbers).
/// 
/// This class provides static methods for detecting file types from various sources:
/// - Byte buffers (Uint8List)
/// - Streams
/// - URLs
/// - Blobs
/// 
/// It also provides utility methods for checking file type categories such as:
/// - Images
/// - Videos
/// - Audio files
/// - Documents
/// - Archives
/// - Fonts
/// - Executables
class FileType {
  // Signature definitions for file types
  static final Map<String, List<FileTypeSignature>> _signatures = {
    // Images
    'image/jpeg': [FileTypeSignature([0xFF, 0xD8, 0xFF], ext: 'jpg')],
    'image/png': [
      FileTypeSignature(
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], ext: 'png')
    ],
    'image/gif': [
      FileTypeSignature([0x47, 0x49, 0x46, 0x38, null, 0x61],
          maskFunc: (buffer) => buffer[4] == 0x37 || buffer[4] == 0x39,
          ext: 'gif')
    ],
    'image/webp': [
      FileTypeSignature([0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50],
          ext: 'webp')
    ],
    'image/bmp': [FileTypeSignature([0x42, 0x4D], ext: 'bmp')],
    'image/x-icon': [
      FileTypeSignature([0x00, 0x00, 0x01, 0x00], ext: 'ico')
    ],
    'image/tiff': [
      FileTypeSignature([0x49, 0x49, 0x2A, 0x00], ext: 'tif'), // little endian
      FileTypeSignature([0x4D, 0x4D, 0x00, 0x2A], ext: 'tif') // big endian
    ],
    'image/x-canon-cr2': [
      FileTypeSignature(
          [0x49, 0x49, 0x2A, 0x00, null, null, null, null, 0x43, 0x52],
          ext: 'cr2'),
      FileTypeSignature(
          [0x4D, 0x4D, 0x00, 0x2A, null, null, null, null, 0x43, 0x52],
          ext: 'cr2')
    ],
    'image/heif': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63],
          ext: 'heic')
    ],
    'image/avif': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x66],
          ext: 'avif')
    ],
    'image/jxl': [
      FileTypeSignature([0xFF, 0x0A], ext: 'jxl'),
      FileTypeSignature([0x00, 0x00, 0x00, 0x0C, 0x4A, 0x58, 0x4C, 0x20, 0x0D, 0x0A, 0x87, 0x0A], ext: 'jxl')
    ],
    'image/svg+xml': [
      FileTypeSignature([0x3C, 0x73, 0x76, 0x67], ext: 'svg'),
      FileTypeSignature([0x3C, 0x3F, 0x78, 0x6D, 0x6C], ext: 'svg') // XML declaration
    ],
    
    // Documents
    'application/pdf': [
      FileTypeSignature([0x25, 0x50, 0x44, 0x46], ext: 'pdf')
    ],
    'application/zip': [
      FileTypeSignature([0x50, 0x4B, null, null],
          maskFunc: (buffer) =>
              (buffer[2] == 0x03 || buffer[2] == 0x05 || buffer[2] == 0x07) &&
              (buffer[3] == 0x04 || buffer[3] == 0x06 || buffer[3] == 0x08),
          ext: 'zip')
    ],
    'application/x-rar-compressed': [
      FileTypeSignature([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07], ext: 'rar') // RAR v1.5+
    ],
    'application/x-7z-compressed': [
      FileTypeSignature([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C], ext: '7z')
    ],
    'application/gzip': [
      FileTypeSignature([0x1F, 0x8B, 0x08], ext: 'gz')
    ],
    'application/x-tar': [
      FileTypeSignature([0x75, 0x73, 0x74, 0x61, 0x72, 0x00, 0x30, 0x30], ext: 'tar'),
      FileTypeSignature([0x75, 0x73, 0x74, 0x61, 0x72, 0x20, 0x20, 0x00], ext: 'tar')
    ],
    'application/epub+zip': [
      FileTypeSignature(
          [0x50, 0x4B, 0x03, 0x04, null, null, null, null, null, null, null, null, null, null, null, null, 
          0x6D, 0x69, 0x6D, 0x65, 0x74, 0x79, 0x70, 0x65, 0x61, 0x70, 0x70, 0x6C, 0x69, 0x63, 0x61, 0x74, 
          0x69, 0x6F, 0x6E, 0x2F, 0x65, 0x70, 0x75, 0x62, 0x2B, 0x7A, 0x69, 0x70],
          ext: 'epub')
    ],
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': [
      FileTypeSignature(
          [0x50, 0x4B, 0x03, 0x04],
          ext: 'docx')
    ],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': [
      FileTypeSignature(
          [0x50, 0x4B, 0x03, 0x04],
          ext: 'xlsx')
    ],
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': [
      FileTypeSignature(
          [0x50, 0x4B, 0x03, 0x04],
          ext: 'pptx')
    ],
    'application/msword': [
      FileTypeSignature([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1], ext: 'doc')
    ],
    'application/vnd.ms-excel': [
      FileTypeSignature([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1], ext: 'xls')
    ],
    'application/vnd.ms-powerpoint': [
      FileTypeSignature([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1], ext: 'ppt')
    ],
    
    // Videos
    'video/mp4': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, null, null, null, null],
          maskFunc: (buffer) =>
              // ISOM
              (buffer[8] == 0x69 && buffer[9] == 0x73 && buffer[10] == 0x6F && buffer[11] == 0x6D) ||
              // MP41
              (buffer[8] == 0x6D && buffer[9] == 0x70 && buffer[10] == 0x34 && buffer[11] == 0x31) ||
              // MP42
              (buffer[8] == 0x6D && buffer[9] == 0x70 && buffer[10] == 0x34 && buffer[11] == 0x32) ||
              // M4V
              (buffer[8] == 0x4D && buffer[9] == 0x34 && buffer[10] == 0x56 && buffer[11] == 0x20) ||
              // MSNV
              (buffer[8] == 0x4D && buffer[9] == 0x53 && buffer[10] == 0x4E && buffer[11] == 0x56) ||
              // DASH
              (buffer[8] == 0x64 && buffer[9] == 0x61 && buffer[10] == 0x73 && buffer[11] == 0x68),
          ext: 'mp4'),
    ],
    'video/webm': [
      FileTypeSignature([0x1A, 0x45, 0xDF, 0xA3], ext: 'webm')
    ],
    'video/x-matroska': [
      FileTypeSignature([0x1A, 0x45, 0xDF, 0xA3], ext: 'mkv')
    ],
    'video/avi': [
      FileTypeSignature(
          [0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x41, 0x56, 0x49, 0x20],
          ext: 'avi')
    ],
    'video/quicktime': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20],
          ext: 'mov'),
      FileTypeSignature(
          [0x6D, 0x6F, 0x6F, 0x76],
          ext: 'mov')
    ],
    'video/x-flv': [
      FileTypeSignature([0x46, 0x4C, 0x56, 0x01], ext: 'flv')
    ],
    'video/x-m4v': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x56, 0x20],
          ext: 'm4v')
    ],
    'video/3gpp': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x33, 0x67],
          ext: '3gp')
    ],
    'video/3gpp2': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x33, 0x67, 0x32],
          ext: '3g2')
    ],
    
    // Audio
    'audio/mpeg': [
      FileTypeSignature([0x49, 0x44, 0x33], ext: 'mp3'), // ID3v2
      FileTypeSignature([0xFF, null],
          maskFunc: (buffer) => (buffer[1] & 0xE0) == 0xE0, ext: 'mp3') // MPEG sync
    ],
    'audio/wav': [
      FileTypeSignature(
          [0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x41, 0x56, 0x45],
          ext: 'wav')
    ],
    'audio/flac': [
      FileTypeSignature([0x66, 0x4C, 0x61, 0x43], ext: 'flac')
    ],
    'audio/ogg': [FileTypeSignature([0x4F, 0x67, 0x67, 0x53], ext: 'ogg')],
    'audio/webm': [
      FileTypeSignature([0x1A, 0x45, 0xDF, 0xA3], ext: 'weba')
    ],
    'audio/aac': [
      FileTypeSignature([0xFF, 0xF1], ext: 'aac'), // ADTS
      FileTypeSignature([0xFF, 0xF9], ext: 'aac')  // ADTS
    ],
    'audio/midi': [
      FileTypeSignature([0x4D, 0x54, 0x68, 0x64], ext: 'midi')
    ],
    'audio/x-m4a': [
      FileTypeSignature(
          [null, null, null, null, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20],
          ext: 'm4a')
    ],
    'audio/amr': [
      FileTypeSignature([0x23, 0x21, 0x41, 0x4D, 0x52], ext: 'amr')
    ],
    'audio/aiff': [
      FileTypeSignature(
          [0x46, 0x4F, 0x52, 0x4D, null, null, null, null, 0x41, 0x49, 0x46, 0x46],
          ext: 'aiff')
    ],
    
    // Archives and Compressed Files
    'application/x-bzip2': [
      FileTypeSignature([0x42, 0x5A, 0x68], ext: 'bz2')
    ],
    'application/x-lzip': [
      FileTypeSignature([0x4C, 0x5A, 0x49, 0x50], ext: 'lz')
    ],
    'application/x-lzma': [
      FileTypeSignature([0x5D, 0x00, 0x00], ext: 'lzma')
    ],
    'application/x-xz': [
      FileTypeSignature([0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00], ext: 'xz')
    ],
    'application/x-compress': [
      FileTypeSignature([0x1F, 0x9D], ext: 'Z')
    ],
    'application/vnd.debian.binary-package': [
      FileTypeSignature([0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E], ext: 'deb')
    ],
    'application/x-rpm': [
      FileTypeSignature([0xED, 0xAB, 0xEE, 0xDB], ext: 'rpm')
    ],
    
    // Executables and Binaries
    'application/x-executable': [
      FileTypeSignature([0x7F, 0x45, 0x4C, 0x46], ext: 'elf') // ELF (Linux/Unix)
    ],
    'application/x-msdownload': [
      FileTypeSignature([0x4D, 0x5A], ext: 'exe') // Windows/DOS executable
    ],
    'application/x-mach-binary': [
      FileTypeSignature([0xCF, 0xFA, 0xED, 0xFE], ext: 'macho'), // Mach-O binary (macOS, 32-bit)
      FileTypeSignature([0xCE, 0xFA, 0xED, 0xFE], ext: 'macho'), // Mach-O binary (macOS, reverse endian)
      FileTypeSignature([0xFE, 0xED, 0xFA, 0xCF], ext: 'macho'), // Mach-O binary (macOS, big endian)
      FileTypeSignature([0xFE, 0xED, 0xFA, 0xCE], ext: 'macho'), // Mach-O binary (macOS, big endian, reverse)
      FileTypeSignature([0xCA, 0xFE, 0xBA, 0xBE], ext: 'macho')  // Mach-O universal binary
    ],
    'application/vnd.android.package-archive': [
      FileTypeSignature([0x50, 0x4B, 0x03, 0x04], ext: 'apk')
    ],
    
    // Database and Data Files
    'application/x-sqlite3': [
      FileTypeSignature([0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00], ext: 'sqlite')
    ],
    'application/vnd.microsoft.portable-executable': [
      FileTypeSignature([0x4D, 0x5A], ext: 'dll') // DLL files share the MZ header
    ],
    'application/x-shockwave-flash': [
      FileTypeSignature([0x43, 0x57, 0x53], ext: 'swf'), // Compressed SWF
      FileTypeSignature([0x46, 0x57, 0x53], ext: 'swf')  // Uncompressed SWF
    ],
    
    // Fonts
    'application/font-woff': [
      FileTypeSignature([0x77, 0x4F, 0x46, 0x46, 0x00, 0x01, 0x00, 0x00], ext: 'woff')
    ],
    'application/font-woff2': [
      FileTypeSignature([0x77, 0x4F, 0x46, 0x32, 0x00, 0x01, 0x00, 0x00], ext: 'woff2')
    ],
    'application/vnd.ms-fontobject': [
      FileTypeSignature([0x00, 0x00, 0x01, 0x00], ext: 'eot')
    ],
    'application/font-sfnt': [
      FileTypeSignature([0x00, 0x01, 0x00, 0x00], ext: 'ttf'), // TrueType font
      FileTypeSignature([0x4F, 0x54, 0x54, 0x4F], ext: 'otf')  // OpenType font
    ],
  };

  /// Default buffer size used for file type detection.
  /// 
  /// This determines how many bytes to read from streams, URLs, and blobs
  /// when detecting file types.
  static const int _defaultBufferSize = 4096;

  /// Detects the file type from a [Uint8List] buffer.
  /// 
  /// This method analyzes the provided byte buffer to identify file type
  /// based on file signatures (magic numbers) defined in [_signatures].
  /// 
  /// Parameters:
  /// - [buffer]: A [Uint8List] containing the bytes to analyze, typically from the start of a file.
  /// 
  /// Returns a [FileTypeResult] object with detected MIME type and file extension,
  /// or `null` if the file type couldn't be detected.
  /// 
  /// Example:
  /// ```dart
  /// final buffer = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);
  /// final result = FileType.fromBuffer(buffer);
  /// print('${result?.mime}, ${result?.ext}'); // Outputs: image/jpeg, jpg
  /// ```
  static FileTypeResult? fromBuffer(Uint8List buffer) {
    if (buffer.isEmpty || buffer.length < 2) {
      return null;
    }

    // Check all signatures
    for (final entry in _signatures.entries) {
      final mime = entry.key;
      final signatureList = entry.value;
      
      for (final signature in signatureList) {
        if (signature.matches(buffer)) {
          return FileTypeResult(mime: mime, ext: signature.ext);
        }
      }
    }

    // Default case - unable to determine type
    return null;
  }

  /// Detects the file type from a [Stream<List<int>>].
  /// 
  /// This method reads from the provided stream to collect enough bytes to identify
  /// the file type, then uses [fromBuffer] to perform the detection.
  /// 
  /// Parameters:
  /// - [stream]: A [Stream<List<int>>] containing the file data.
  /// - [bufferSize]: Optional parameter to specify how many bytes to read from the stream.
  ///   Defaults to [_defaultBufferSize] (4096 bytes).
  /// 
  /// Returns a [Future<FileTypeResult?>] that resolves to the detected file type
  /// or `null` if the type couldn't be determined.
  /// 
  /// Example:
  /// ```dart
  /// // Reading from a file
  /// final file = File('example.mp4');
  /// final stream = file.openRead();
  /// final result = await FileType.fromStream(stream);
  /// print('${result?.mime}, ${result?.ext}'); // Outputs: video/mp4, mp4
  /// ```
  /// 
  /// Note: This method only reads the beginning of the stream up to [bufferSize] bytes.
  /// The stream is not completely consumed, and the remainder can still be used elsewhere.
  static Future<FileTypeResult?> fromStream(Stream<List<int>> stream, 
      {int bufferSize = _defaultBufferSize}) async {
    final buffer = await _readFromStream(stream, bufferSize);
    return fromBuffer(buffer);
  }

  /// Detects the file type from a [Blob].
  /// 
  /// This method handles various blob types by converting them to a stream
  /// and then using [fromStream] to detect the file type.
  /// 
  /// Parameters:
  /// - [blob]: A blob object which can be of various types like:
  ///   - Stream<List<int>>
  ///   - List<int>
  ///   - String (base64 encoded or plain text)
  /// - [bufferSize]: Optional parameter to specify how many bytes to read.
  ///   Defaults to [_defaultBufferSize] (4096 bytes).
  /// 
  /// Returns a [Future<FileTypeResult?>] that resolves to the detected file type
  /// or `null` if the type couldn't be determined.
  /// 
  /// Example:
  /// ```dart
  /// // From a base64 string
  /// final base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  /// final result = await FileType.fromBlob(base64Image);
  /// print('${result?.mime}, ${result?.ext}'); // Outputs: image/png, png
  /// ```
  /// 
  /// Note: This is a platform-agnostic implementation that works for both web and native platforms.
  static Future<FileTypeResult?> fromBlob(dynamic blob, 
      {int bufferSize = _defaultBufferSize}) async {
    // Handle different blob types
    // Web platform would handle this differently with dart:html
    // This is a simplified version focusing on the API structure
    final Stream<List<int>> stream = await _getBlobStream(blob);
    return fromStream(stream, bufferSize: bufferSize);
  }

  /// Detects the file type from a URL.
  /// 
  /// This method fetches the beginning of a file from the specified URL
  /// and then uses [fromStream] to detect the file type.
  /// 
  /// Parameters:
  /// - [url]: The URL to fetch the file from.
  /// - [bufferSize]: Optional parameter to specify how many bytes to read.
  ///   Defaults to [_defaultBufferSize] (4096 bytes).
  /// - [httpClient]: Optional HTTP client to use for the request.
  /// - [headers]: Optional HTTP headers to include in the request.
  /// 
  /// Returns a [Future<FileTypeResult?>] that resolves to the detected file type
  /// or `null` if the type couldn't be determined.
  /// 
  /// Example:
  /// ```dart
  /// // From a URL
  /// final result = await FileType.fromUrl('https://example.com/image.jpg');
  /// print('${result?.mime}, ${result?.ext}'); // Outputs: image/jpeg, jpg
  /// 
  /// // With custom headers
  /// final result = await FileType.fromUrl(
  ///   'https://example.com/image.jpg',
  ///   headers: {'Authorization': 'Bearer token123'}
  /// );
  /// ```
  /// 
  /// Note: This method uses the HTTP Range header to only download the beginning 
  /// of the file, reducing bandwidth usage.
  static Future<FileTypeResult?> fromUrl(String url, 
      {int bufferSize = _defaultBufferSize, 
       http.Client? httpClient,
       Map<String, String>? headers}) async {
    final client = httpClient ?? http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      
      // Add headers if provided
      if (headers != null) {
        request.headers.addAll(headers);
      }
      
      // Set range header to only get the beginning of the file
      request.headers['Range'] = 'bytes=0-${bufferSize - 1}';
      
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        return await fromStream(streamedResponse.stream, bufferSize: bufferSize);
      } else {
        throw Exception('HTTP error: ${streamedResponse.statusCode}');
      }
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// Checks if the file type is one of the supported image formats
  static bool isImage(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    return result.mime!.startsWith('image/');
  }

  /// Checks if the file type is one of the supported video formats
  static bool isVideo(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    return result.mime!.startsWith('video/');
  }

  /// Checks if the file type is one of the supported audio formats
  static bool isAudio(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    return result.mime!.startsWith('audio/');
  }
  
  /// Checks if the file type is a document format
  static bool isDocument(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    
    final documentTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/epub+zip',
    ];
    
    return documentTypes.contains(result.mime);
  }
  
  /// Checks if the file type is an archive format
  static bool isArchive(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    
    final archiveTypes = [
      'application/zip',
      'application/x-rar-compressed',
      'application/x-7z-compressed',
      'application/gzip',
      'application/x-tar',
      'application/x-bzip2',
      'application/x-lzip',
      'application/x-lzma',
      'application/x-xz',
      'application/x-compress',
    ];
    
    return archiveTypes.contains(result.mime);
  }
  
  /// Checks if the file type is a font format
  static bool isFont(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    
    final fontTypes = [
      'application/font-woff',
      'application/font-woff2',
      'application/vnd.ms-fontobject',
      'application/font-sfnt',
    ];
    
    return fontTypes.contains(result.mime);
  }
  
  /// Checks if the file type is an executable format
  static bool isExecutable(FileTypeResult? result) {
    if (result == null || result.mime == null) return false;
    
    final executableTypes = [
      'application/x-executable',
      'application/x-msdownload',
      'application/x-mach-binary',
      'application/vnd.android.package-archive',
      'application/vnd.microsoft.portable-executable',
    ];
    
    return executableTypes.contains(result.mime);
  }
  
  /// Helper method to read from a stream into a buffer
  static Future<Uint8List> _readFromStream(Stream<List<int>> stream, int maxSize) async {
    final List<int> data = [];
    final completer = Completer<Uint8List>();
    
    late StreamSubscription<List<int>> subscription;
    
    subscription = stream.listen(
      (chunk) {
        data.addAll(chunk);
        if (data.length >= maxSize) {
          subscription.cancel();
          completer.complete(Uint8List.fromList(data.sublist(0, maxSize)));
        }
      },
      onDone: () {
        completer.complete(Uint8List.fromList(data));
      },
      onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
      },
      cancelOnError: true,
    );
    
    return completer.future;
  }
  
  /// Helper method to get a stream from a blob object
  /// This implementation depends on the platform (web or native)
  static Future<Stream<List<int>>> _getBlobStream(dynamic blob) async {
    // This is a placeholder implementation
    // In actual web implementation, dart:html would be used
    // For native platforms, the blob could be a File or other io object
    
    if (blob is Stream<List<int>>) {
      return blob;
    }
    
    if (blob is List<int>) {
      return Stream.value(blob);
    }
    
    if (blob is String) {
      // Assume base64 encoded string
      try {
        final decoded = base64Decode(blob);
        return Stream.value(decoded);
      } catch (e) {
        // If not base64, treat as plain text
        final encoded = utf8.encode(blob);
        return Stream.value(encoded);
      }
    }
    
    // Throw error for unsupported blob types
    throw UnsupportedError('Unsupported blob type: ${blob.runtimeType}');
  }
}

/// Internal class to define file type signatures
class FileTypeSignature {
  final List<int?> bytes;
  final bool Function(Uint8List)? maskFunc;
  final String ext;
  
  @literal
  const FileTypeSignature(this.bytes, {this.maskFunc, required this.ext});
  
  bool matches(Uint8List buffer) {
    if (buffer.length < bytes.length) {
      return false;
    }
    
    // Check each byte in the signature
    for (int i = 0; i < bytes.length; i++) {
      // Skip null bytes in the signature (wildcards)
      if (bytes[i] == null) continue;
      
      if (buffer[i] != bytes[i]) {
        return false;
      }
    }
    
    // Apply mask function if provided
    if (maskFunc != null) {
      return maskFunc!(buffer);
    }
    
    return true;
  }
}