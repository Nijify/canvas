## 0.2.0

- **Breaking:** require `canvas_core 0.4.x`.
- Replace pre-expanded text with native `double` letter spacing.
- Forward letter spacing through measurement, caching, and painting.

## 0.1.1

- Expand the supported `canvas_core` range to include `0.3.x`.
- No renderer behavior or API changes.

## 0.1.0

- Initial open-source release of canvas_renderer_flutter.
- Provides Flutter rendering, text measurement, decoded image caching, image intrinsic helpers, and PNG export support for canvas_core scenes.
- Includes optional ImageProvider helpers behind a separate import for apps that want to resolve common image refs across mobile and web.
