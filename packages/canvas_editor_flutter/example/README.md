# canvas_editor example

A runnable standalone editor reference app. It demonstrates the standard
inspector and layers panel, normal scene editing, JSON export, and the optional
`Add → Assets` integration with host-owned asset selection UI and bundled
`asset:` image references.

## Run

From the repository root:

```sh
cd oss_packages/canvas_editor/example
flutter pub get
flutter run -d chrome
```

The example keeps normal hosted package dependencies in `pubspec.yaml` so the
published package example remains valid for pub.dev consumers. In this monorepo,
Dart workspace resolution uses the local in-repo packages during development.
