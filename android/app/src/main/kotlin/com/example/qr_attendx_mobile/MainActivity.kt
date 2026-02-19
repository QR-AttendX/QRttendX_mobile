package com.example.qr_attendx_mobile

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveBytesToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType")
            val relativePath = call.argument<String>("relativePath")
            val bytes = call.argument<ByteArray>("bytes")
            if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
                result.error(
                    "invalid_args",
                    "fileName, mimeType, and bytes are required.",
                    null,
                )
                return@setMethodCallHandler
            }

            try {
                val savedPath = saveBytesToDownloads(
                    fileName = fileName,
                    mimeType = mimeType,
                    relativePath = relativePath ?: DEFAULT_RELATIVE_PATH,
                    bytes = bytes,
                )
                result.success(savedPath)
            } catch (error: Exception) {
                result.error("save_failed", error.message, null)
            }
        }
    }

    private fun saveBytesToDownloads(
        fileName: String,
        mimeType: String,
        relativePath: String,
        bytes: ByteArray,
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val fileUri = resolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                contentValues,
            ) ?: throw IOException("Unable to create download entry.")

            resolver.openOutputStream(fileUri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: throw IOException("Unable to write exported file.")

            contentValues.clear()
            contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(fileUri, contentValues, null, null)
            return "$relativePath/$fileName"
        }

        @Suppress("DEPRECATION")
        val downloadDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val subFolder = relativePath.removePrefix("Download/").removePrefix("Downloads/")
        val targetDirectory = if (subFolder.isBlank()) {
            downloadDir
        } else {
            File(downloadDir, subFolder)
        }
        if (!targetDirectory.exists() && !targetDirectory.mkdirs()) {
            throw IOException("Unable to create export directory.")
        }

        val targetFile = File(targetDirectory, fileName)
        targetFile.outputStream().use { stream ->
            stream.write(bytes)
            stream.flush()
        }
        return targetFile.absolutePath
    }

    companion object {
        private const val CHANNEL_NAME = "qr_attendx_mobile/downloads"
        private const val DEFAULT_RELATIVE_PATH = "Download/QR AttendX"
    }
}
