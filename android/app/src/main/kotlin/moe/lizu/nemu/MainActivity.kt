package moe.lizu.nemu

import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import moe.lizu.nemu.lyric.LyricOverlayPlugin

class MainActivity: AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "moe.lizu.nemu/lyric_overlay"
        ).setMethodCallHandler(LyricOverlayPlugin(applicationContext))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "moe.lizu.nemu/platform"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }
    }
}
