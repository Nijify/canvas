import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_proxy_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search calls the configured proxy and parses results', () async {
    Uri? requested;
    final client = UnsplashProxyClient(
      baseUri: Uri.parse('https://proxy.example/api/'),
      get: (uri) async {
        requested = uri;
        return '''
          {
            "results": [
              {
                "id": "photo-1",
                "description": "Photo",
                "width": 1200,
                "height": 800,
                "urls": {
                  "small": "https://images.unsplash.com/small?ixid=small",
                  "regular": "https://images.unsplash.com/regular?ixid=regular"
                },
                "user": {
                  "name": "Jane Doe",
                  "links": {"html": "https://unsplash.com/@jane"}
                },
                "links": {
                  "download_location": "https://api.unsplash.com/photos/photo-1/download?ixid=track"
                }
              }
            ]
          }
        ''';
      },
    );

    final results = await client.search('mountains');

    expect(results, hasLength(1));
    expect(requested?.path, '/api/unsplash/search');
    expect(requested?.queryParameters['query'], 'mountains');
  });

  test('tracking sends only a validated Unsplash path and query', () async {
    Uri? requested;
    final client = UnsplashProxyClient(
      baseUri: Uri.parse('https://proxy.example/api/'),
      get: (uri) async {
        requested = uri;
        return '{}';
      },
    );
    final photo = UnsplashPhoto(
      id: 'photo-1',
      label: 'Photo',
      width: 1200,
      height: 800,
      thumbnailUrl: Uri.parse('https://images.unsplash.com/thumb'),
      imageUrl: Uri.parse('https://images.unsplash.com/image'),
      credit: UnsplashCredit(
        photographerName: 'Jane Doe',
        photographerUrl: Uri.parse('https://unsplash.com/@jane'),
      ),
      downloadLocation: Uri.parse(
        'https://api.unsplash.com/photos/photo-1/download?ixid=track',
      ),
    );

    await client.trackDownload(photo);

    expect(requested?.path, '/api/unsplash/track');
    expect(
      requested?.queryParameters['path'],
      '/photos/photo-1/download',
    );
    expect(requested?.queryParameters['query'], 'ixid=track');
  });

  test('tracking rejects arbitrary upstream URLs', () async {
    final client = UnsplashProxyClient(
      baseUri: Uri.parse('https://proxy.example/api/'),
      get: (_) async => '{}',
    );
    final photo = UnsplashPhoto(
      id: 'photo-1',
      label: 'Photo',
      width: 1200,
      height: 800,
      thumbnailUrl: Uri.parse('https://images.unsplash.com/thumb'),
      imageUrl: Uri.parse('https://images.unsplash.com/image'),
      credit: UnsplashCredit(
        photographerName: 'Jane Doe',
        photographerUrl: Uri.parse('https://unsplash.com/@jane'),
      ),
      downloadLocation: Uri.parse('https://example.com/not-unsplash'),
    );

    expect(() => client.trackDownload(photo), throwsArgumentError);
  });
}
