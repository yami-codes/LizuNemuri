/// Common raster image extensions openable in the in-app zoom preview.
class ImageFileExtensions {
  ImageFileExtensions._();

  static const previewable = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'avif',
    'heic',
    'heif',
    'tif',
    'tiff',
  };

  static bool hasPreviewableExtension(String? title) {
    if (title == null || title.isEmpty) return false;
    final ext = title.split('.').last.toLowerCase();
    return previewable.contains(ext);
  }
}
