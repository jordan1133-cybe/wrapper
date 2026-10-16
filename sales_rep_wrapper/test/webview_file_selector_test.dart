import 'package:flutter_test/flutter_test.dart';
import 'package:sales_rep_wrapper/webview/webview_file_selector.dart';

void main() {
  group('acceptsImages', () {
    test('allows an empty accept list', () {
      expect(acceptsImages([]), isTrue);
    });

    test('allows all files', () {
      expect(acceptsImages(['*/*']), isTrue);
    });

    test('allows image wildcards and concrete image MIME types', () {
      expect(acceptsImages(['image/*']), isTrue);
      expect(acceptsImages(['image/png']), isTrue);
      expect(acceptsImages(['IMAGE/JPEG']), isTrue);
    });

    test('allows supported image extensions', () {
      expect(acceptsImages(['.jpg']), isTrue);
      expect(acceptsImages(['.jpeg']), isTrue);
      expect(acceptsImages(['.png']), isTrue);
      expect(acceptsImages(['.webp']), isTrue);
      expect(acceptsImages(['.heic']), isTrue);
    });

    test('rejects only non-image types', () {
      expect(acceptsImages(['application/pdf']), isFalse);
    });

    test('allows images in mixed accept types', () {
      expect(acceptsImages(['application/pdf', 'image/*']), isTrue);
    });

    test('rejects junk and whitespace entries', () {
      expect(acceptsImages(['not-a-type']), isFalse);
      expect(acceptsImages(['   ']), isFalse);
      expect(acceptsImages(['', '  ']), isFalse);
    });
  });
}
