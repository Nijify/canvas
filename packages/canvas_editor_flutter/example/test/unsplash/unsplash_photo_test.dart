import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps an Unsplash response to a Canvas asset item', () {
    final photo = UnsplashPhoto.fromJson(<String, Object?>{
      'id': 'photo-1',
      'description': 'Mountain lake',
      'width': 4000,
      'height': 3000,
      'urls': <String, Object?>{
        'small': 'https://images.unsplash.com/small?ixid=small-token',
        'regular': 'https://images.unsplash.com/regular?ixid=regular-token',
      },
      'user': <String, Object?>{
        'name': 'Jane Doe',
        'links': <String, Object?>{
          'html': 'https://unsplash.com/@jane',
        },
      },
      'links': <String, Object?>{
        'download_location':
            'https://api.unsplash.com/photos/photo-1/download?ixid=track-token',
      },
    });

    final item = photo.toAssetLibraryItem();

    expect(item.sourceRef, contains('regular-token'));
    expect(item.thumbnailRef, contains('small-token'));
    expect(item.intrinsicSize.w, 4000);
    expect(item.intrinsicSize.h, 3000);
    expect(item.metadata['provider'], 'unsplash');
    expect(
      item.metadata['photographerUrl'],
      contains('utm_source=canvas_editor_example'),
    );
  });

  test('preserves existing query parameters when adding attribution UTM', () {
    final uri = withUnsplashReferral(
      Uri.parse('https://unsplash.com/@jane?existing=value'),
    );

    expect(uri.queryParameters['existing'], 'value');
    expect(uri.queryParameters['utm_source'], 'canvas_editor_example');
    expect(uri.queryParameters['utm_medium'], 'referral');
  });
}
