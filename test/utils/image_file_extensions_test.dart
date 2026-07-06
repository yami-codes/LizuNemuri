import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/presentation/viewmodels/detail_viewmodel.dart';
import 'package:lizunemu/utils/image_file_extensions.dart';

void main() {
  group('ImageFileExtensions', () {
    test('recognizes common raster extensions', () {
      expect(ImageFileExtensions.hasPreviewableExtension('cover.jpg'), isTrue);
      expect(ImageFileExtensions.hasPreviewableExtension('art.PNG'), isTrue);
      expect(ImageFileExtensions.hasPreviewableExtension('photo.webp'), isTrue);
      expect(ImageFileExtensions.hasPreviewableExtension('anim.gif'), isTrue);
      expect(ImageFileExtensions.hasPreviewableExtension('scan.tiff'), isTrue);
    });

    test('rejects non-image extensions', () {
      expect(ImageFileExtensions.hasPreviewableExtension('track.mp3'), isFalse);
      expect(ImageFileExtensions.hasPreviewableExtension('readme.txt'), isFalse);
      expect(ImageFileExtensions.hasPreviewableExtension(null), isFalse);
    });
  });

  group('DetailViewModel.isPreviewableImageFile', () {
    test('matches extension and API type image', () {
      expect(
        DetailViewModel.isPreviewableImageFile(
          Child(type: 'text', title: '3.高画質メインイラスト.jpg'),
        ),
        isTrue,
      );
      expect(
        DetailViewModel.isPreviewableImageFile(
          Child(type: 'image', title: 'cover'),
        ),
        isTrue,
      );
      expect(
        DetailViewModel.isPreviewableImageFile(
          Child(type: 'audio', title: '01.mp3'),
        ),
        isFalse,
      );
    });
  });
}
