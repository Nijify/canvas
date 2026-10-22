package com.nijify.isnetbenchmark

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.nijify.isnetbenchmark/files"
        private const val REQUEST_MODEL = 7101
        private const val REQUEST_IMAGE = 7102
        private const val COPY_BUFFER_BYTES = 1024 * 1024
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingKind: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickModel" -> launchPicker(
                        kind = "model",
                        mimeType = "*/*",
                        requestCode = REQUEST_MODEL,
                        result = result,
                    )
                    "pickImage" -> launchPicker(
                        kind = "image",
                        mimeType = "image/*",
                        requestCode = REQUEST_IMAGE,
                        result = result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchPicker(
        kind: String,
        mimeType: String,
        requestCode: Int,
        result: MethodChannel.Result,
    ) {
        if (pendingResult != null) {
            result.error("picker_busy", "Another file picker request is active.", null)
            return
        }

        pendingResult = result
        pendingKind = kind

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
        }

        try {
            startActivityForResult(intent, requestCode)
        } catch (error: Exception) {
            pendingResult = null
            pendingKind = null
            result.error("picker_launch_failed", error.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != REQUEST_MODEL && requestCode != REQUEST_IMAGE) {
            return
        }

        val result = pendingResult
        val kind = pendingKind
        pendingResult = null
        pendingKind = null

        if (result == null || kind == null) {
            return
        }

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        thread(name = "isnet-benchmark-file-copy") {
            try {
                val displayName = queryDisplayName(uri) ?: defaultDisplayName(kind)
                val copiedFile = copyUriToCache(uri, kind)
                runOnUiThread {
                    result.success(
                        mapOf(
                            "path" to copiedFile.absolutePath,
                            "name" to displayName,
                        ),
                    )
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("file_copy_failed", error.message, null)
                }
            }
        }
    }

    private fun copyUriToCache(uri: Uri, kind: String): File {
        val directory = File(cacheDir, "isnet-benchmark").apply {
            if (!exists() && !mkdirs()) {
                throw IllegalStateException("Failed to create benchmark cache directory.")
            }
        }

        val suffix = if (kind == "model") ".tflite" else ".image"
        val target = File.createTempFile("$kind-", suffix, directory)

        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw IllegalStateException("Failed to open selected file.")

            input.use { source ->
                target.outputStream().buffered(COPY_BUFFER_BYTES).use { destination ->
                    source.copyTo(destination, COPY_BUFFER_BYTES)
                }
            }
        } catch (error: Exception) {
            target.delete()
            throw error
        }

        return target
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return null
    }

    private fun defaultDisplayName(kind: String): String {
        return if (kind == "model") "selected-model.tflite" else "selected-image"
    }
}
