import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_example_ui.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('credit bar is hidden when no Unsplash photos are visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UnsplashCreditBar(
          creditsBySourceRef: <String, UnsplashCredit>{},
        ),
      ),
    );

    expect(find.text('Unsplash'), findsNothing);
  });

  testWidgets('credit bar renders photographer and Unsplash attribution', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UnsplashCreditBar(
          creditsBySourceRef: <String, UnsplashCredit>{
            'https://images.unsplash.com/photo-1': UnsplashCredit(
              photographerName: 'Example Photographer',
              photographerUrl: Uri.parse('https://unsplash.com/@example'),
            ),
          },
        ),
      ),
    );

    expect(find.text('Photo by'), findsOneWidget);
    expect(find.text('Example Photographer'), findsOneWidget);
    expect(find.text('Unsplash'), findsOneWidget);
  });

  testWidgets('asset picker degrades cleanly without a proxy', (tester) async {
    late BuildContext hostContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final selection = presentExampleAssetSelection(
      context: hostContext,
      library: const LocalCanvasAssetLibrary(<CanvasAssetLibraryItem>[]),
      unsplashClient: null,
      onUnsplashSelected: (_) {},
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Unsplash'));
    await tester.pumpAndSettle();

    expect(find.textContaining('UNSPLASH_PROXY_BASE_URL'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await selection, isNull);
  });
}
