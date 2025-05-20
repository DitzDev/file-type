import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_type_dart/file_type_dart.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([http.Client, http.StreamedResponse])
import 'file_type_dart_test.mocks.dart';

// Define a provider for ByteStream
//class MockByteStreamProvider extends Mock implements http.ByteStream {}

void main() {
  // Provide a dummy for ByteStream
  provideDummy(http.ByteStream(Stream.empty()));
  
  group('FileType.fromBuffer', () {
    test('should detect JPEG image', () {
      final buffer = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.mime, equals('image/jpeg'));
      expect(result.ext, equals('jpg'));
    });

    test('should detect PNG image', () {
      final buffer = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52
      ]);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.mime, equals('image/png'));
      expect(result.ext, equals('png'));
    });

    test('should detect MP4 video', () {
      final buffer = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
        0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00
      ]);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.mime, equals('video/mp4'));
      expect(result.ext, equals('mp4'));
    });

    test('should detect MP3 audio', () {
      final buffer = Uint8List.fromList([
        0x49, 0x44, 0x33, 0x04, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x3F, 0x57, 0x00, 0x00, 0x00, 0x00
      ]);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNotNull);
      expect(result!.mime, equals('audio/mpeg'));
      expect(result.ext, equals('mp3'));
    });

    test('should return null for empty buffer', () {
      final buffer = Uint8List(0);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNull);
    });

    test('should return null for too small buffer', () {
      final buffer = Uint8List.fromList([0x01]);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNull);
    });

    test('should return null for unknown file type', () {
      final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]);
      final result = FileType.fromBuffer(buffer);
      expect(result, isNull);
    });
  });

  group('FileType helper methods', () {
    test('isImage should return true for image types', () {
      expect(FileType.isImage(const FileTypeResult(mime: 'image/jpeg', ext: 'jpg')), isTrue);
      expect(FileType.isImage(const FileTypeResult(mime: 'image/png', ext: 'png')), isTrue);
      expect(FileType.isImage(const FileTypeResult(mime: 'video/mp4', ext: 'mp4')), isFalse);
      expect(FileType.isImage(const FileTypeResult(mime: 'audio/mpeg', ext: 'mp3')), isFalse);
      expect(FileType.isImage(null), isFalse);
    });

    test('isVideo should return true for video types', () {
      expect(FileType.isVideo(const FileTypeResult(mime: 'video/mp4', ext: 'mp4')), isTrue);
      expect(FileType.isVideo(const FileTypeResult(mime: 'video/webm', ext: 'webm')), isTrue);
      expect(FileType.isVideo(const FileTypeResult(mime: 'image/jpeg', ext: 'jpg')), isFalse);
      expect(FileType.isVideo(const FileTypeResult(mime: 'audio/mpeg', ext: 'mp3')), isFalse);
      expect(FileType.isVideo(null), isFalse);
    });

    test('isAudio should return true for audio types', () {
      expect(FileType.isAudio(const FileTypeResult(mime: 'audio/mpeg', ext: 'mp3')), isTrue);
      expect(FileType.isAudio(const FileTypeResult(mime: 'audio/wav', ext: 'wav')), isTrue);
      expect(FileType.isAudio(const FileTypeResult(mime: 'image/jpeg', ext: 'jpg')), isFalse);
      expect(FileType.isAudio(const FileTypeResult(mime: 'video/mp4', ext: 'mp4')), isFalse);
      expect(FileType.isAudio(null), isFalse);
    });
  });

  group('FileType.fromStream', () {
    test('should detect file type from stream', () async {
      final stream = Stream.value(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]));
      final result = await FileType.fromStream(stream);
      expect(result, isNotNull);
      expect(result!.mime, equals('image/jpeg'));
      expect(result.ext, equals('jpg'));
    });

    test('should handle empty stream', () async {
      final stream = Stream<List<int>>.empty();
      final result = await FileType.fromStream(stream);
      expect(result, isNull);
    });
  });

  group('FileType.fromBlob', () {
    test('should handle Uint8List as blob', () async {
      final blob = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      final result = await FileType.fromBlob(blob);
      expect(result, isNotNull);
      expect(result!.mime, equals('image/jpeg'));
      expect(result.ext, equals('jpg'));
    });

    test('should handle Stream as blob', () async {
      final stream = Stream.value(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
      final result = await FileType.fromBlob(stream);
      expect(result, isNotNull);
      expect(result!.mime, equals('image/png'));
      expect(result.ext, equals('png'));
    });

    test('should handle base64 string as blob', () async {
      // Base64 for JPEG signature
      final base64Str = base64Encode([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      final result = await FileType.fromBlob(base64Str);
      expect(result, isNotNull);
      expect(result!.mime, equals('image/jpeg'));
      expect(result.ext, equals('jpg'));
    });

    test('should throw for unsupported blob type', () async {
      expect(() async => await FileType.fromBlob(123), throwsUnsupportedError);
    });
  });

  group('FileType.fromUrl', () {
    late MockClient mockClient;
    late MockStreamedResponse mockResponse;

    setUp(() {
      mockClient = MockClient();
      mockResponse = MockStreamedResponse();
    });

    test('should detect file type from URL', () async {
      // PNG header bytes
      final responseBytes = Uint8List.fromList(
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      
      // Set up mock response
      when(mockResponse.statusCode).thenReturn(200);
      when(mockResponse.stream)
           .thenAnswer((_) => http.ByteStream(Stream.value(responseBytes)));
      
      // Set up mock client
      when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

      final result = await FileType.fromUrl(
          'https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg',
          httpClient: mockClient);
          
      expect(result, isNotNull);
      expect(result!.mime, equals('image/png'));
      expect(result.ext, equals('png'));
      
      // Verify that the Range header was set correctly
      verify(mockClient.send(argThat(
          predicate((http.Request request) => 
              request.headers['Range'] == 'bytes=0-4095'))));
    });

    test('should handle HTTP error', () async {
      // Set up mock client to throw exception
      when(mockClient.send(any)).thenThrow(HttpException('Connection failed'));

      expect(
          () => FileType.fromUrl(
              'https://example.com/image.png', httpClient: mockClient),
          throwsA(isA<HttpException>()));
    });
  });
}