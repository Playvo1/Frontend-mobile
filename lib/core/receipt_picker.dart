import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// A receipt the player chose from their phone.
class PickedReceipt {
  const PickedReceipt({
    required this.path,
    required this.fileName,
    required this.sizeInBytes,
  });

  final String path;
  final String fileName;
  final int sizeInBytes;

  /// "2.4 MB", as shown on the upload card.
  String get readableSize {
    final double megabytes = sizeInBytes / (1024 * 1024);
    if (megabytes >= 0.1) {
      return '${megabytes.toStringAsFixed(1)} MB';
    }
    return '${(sizeInBytes / 1024).round()} KB';
  }

  bool get isWithinLimit => sizeInBytes <= ReceiptPicker.maxBytes;
}

/// Picks the bank transfer receipt from the gallery or the camera.
///
/// Wrapped behind this class so the screens do not depend on image_picker
/// directly and can be tested with a fake.
class ReceiptPicker {
  const ReceiptPicker();

  /// The 5 MB cap stated on the upload card.
  static const int maxBytes = 5 * 1024 * 1024;

  Future<PickedReceipt?> pick({bool fromCamera = false}) async {
    final XFile? file = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      // Keeps a modern phone photo under the size cap without the player
      // having to resize anything.
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (file == null) {
      return null;
    }

    return PickedReceipt(
      path: file.path,
      fileName: file.name,
      sizeInBytes: await File(file.path).length(),
    );
  }
}
