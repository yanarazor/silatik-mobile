package com.example.silatik_mobile

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "silatik_mobile/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enqueueDownload" -> {
                        val url = call.argument<String>("url")
                        val fileName = call.argument<String>("fileName")
                        val headers = call.argument<Map<String, String>>("headers")
                        if (url == null || fileName == null) {
                            result.error("BAD_ARGS", "url and fileName are required", null)
                        } else {
                            try {
                                enqueueDownload(url, fileName, headers)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error(
                                    "ENQUEUE_FAILED",
                                    "${e.javaClass.simpleName}: ${e.message}",
                                    null,
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Hands the download to the system [DownloadManager] so the OS owns the
     * transfer: it shows the progress notification while downloading and the
     * completion notification whose tap opens the file in a viewer. This is why
     * the file is fetched again here instead of reusing the bytes the Dart
     * viewer already loaded: only DownloadManager can drive the system
     * notification, and it cannot be fed an in-memory buffer.
     *
     * On API 29+ the destination is the shared Downloads collection, which
     * needs no storage permission under scoped storage. Below that,
     * [DownloadManager.Request.setDestinationInExternalPublicDir] would require
     * WRITE_EXTERNAL_STORAGE, so the app-specific external Downloads dir is used
     * instead; the notification still works there.
     */
    private fun enqueueDownload(
        url: String,
        fileName: String,
        headers: Map<String, String>?,
    ) {
        val request = DownloadManager.Request(Uri.parse(url))
            .setMimeType("application/pdf")
            .setTitle(fileName)
            .setDescription("Mengunduh dokumen")
            .setNotificationVisibility(
                DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED,
            )
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)

        headers?.forEach { (name, value) -> request.addRequestHeader(name, value) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            request.setDestinationInExternalPublicDir(
                Environment.DIRECTORY_DOWNLOADS,
                fileName,
            )
        } else {
            @Suppress("DEPRECATION")
            request.setDestinationInExternalFilesDir(
                this,
                Environment.DIRECTORY_DOWNLOADS,
                fileName,
            )
        }

        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.enqueue(request)
    }
}
