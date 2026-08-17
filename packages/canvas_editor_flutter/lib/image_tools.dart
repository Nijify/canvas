// canvas_editor_flutter – Optional image-tool capabilities.
//
// Use this entrypoint for host-owned destructive image transformations such as
// background removal.
//
// The editor owns target safety, stale-result rejection, field editability,
// history, and committing the returned replacement source reference.
//
// The host owns image access, processing, persistence, and creation of a durable
// replacement source reference.

library;

export 'src/image_tools.dart';
export 'src/image_tools_extension.dart' show backgroundRemovalExtension;
