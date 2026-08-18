import 'dart:io';
import 'dart:typed_data';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'cloudinary_config.dart';

// Uploads images and documents to Cloudinary using unsigned upload presets.
// Returns null only if the file could not be read or compressed.
class StorageService {
  const StorageService(this._cloudinary);

  final CloudinaryPublic _cloudinary;

  // Compress images on mobile/desktop; on web we just read the original bytes
  // because flutter_image_compress does not support web file paths.
  Future<Uint8List?> _getImageBytes(XFile file, {required int maxDimension}) async {
    final path = file.path;

    if (!kIsWeb && path.isNotEmpty) {
      try {
        final compressed = await FlutterImageCompress.compressWithFile(
          path,
          minWidth: maxDimension,
          minHeight: maxDimension,
          quality: 85,
          format: CompressFormat.jpeg,
        );
        if (compressed != null) return compressed;
      } catch (_) {
        // Fall through to a plain byte read if compression fails.
      }
    }

    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadImage({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    final file = CloudinaryFile.fromBytesData(
      bytes,
      identifier: fileName,
      folder: folder,
      resourceType: CloudinaryResourceType.Image,
    );
    final response = await _cloudinary.uploadFile(file);
    return response.secureUrl;
  }

  // Uploads and compresses a user avatar. Returns the public Cloudinary URL.
  Future<String?> uploadAvatar({
    required String uid,
    required XFile file,
  }) async {
    final bytes = await _getImageBytes(file, maxDimension: 512);
    if (bytes == null) return null;

    final name = 'avatar_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _uploadImage(
      bytes: bytes,
      folder: CloudinaryConfig.avatarsFolder,
      fileName: name,
    );
  }

  // Uploads and compresses a project logo. Returns the public Cloudinary URL.
  Future<String?> uploadProjectLogo({
    required String projectId,
    required XFile file,
  }) async {
    final bytes = await _getImageBytes(file, maxDimension: 1024);
    if (bytes == null) return null;

    final name = 'logo_${projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _uploadImage(
      bytes: bytes,
      folder: CloudinaryConfig.logosFolder,
      fileName: name,
    );
  }

  // Uploads and compresses a project screenshot. Returns the public Cloudinary URL.
  Future<String?> uploadProjectScreenshot({
    required String projectId,
    required XFile file,
  }) async {
    final bytes = await _getImageBytes(file, maxDimension: 1920);
    if (bytes == null) return null;

    final name = 'screenshot_${projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _uploadImage(
      bytes: bytes,
      folder: CloudinaryConfig.screenshotsFolder,
      fileName: name,
    );
  }

  // Uploads a project document (PDF, DOC, DOCX, TXT) as a raw Cloudinary asset.
  Future<String?> uploadProjectDocument({
    required String projectId,
    required PlatformFile file,
  }) async {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return null;

    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final name = 'doc_${projectId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final cloudinaryFile = CloudinaryFile.fromBytesData(
      bytes,
      identifier: name,
      folder: CloudinaryConfig.documentsFolder,
      resourceType: CloudinaryResourceType.Raw,
    );
    final response = await _cloudinary.uploadFile(cloudinaryFile);
    return response.secureUrl;
  }
}
