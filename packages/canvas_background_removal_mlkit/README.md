# canvas_background_removal_mlkit

Unpublished opt-in Android processor based on Google ML Kit Subject Segmentation.
The host must include the Android manifest metadata
`com.google.mlkit.vision.DEPENDENCIES=subject_segment` for model delivery.
Use `createBackgroundRemovalByteProcessor()` in a
`CanvasBackgroundRemovalPort`. The shared package validates raster outputs.
Other platforms return a typed unsupported provider failure. Models may need
time to become available through Google Play services.
