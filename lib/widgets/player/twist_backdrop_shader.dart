import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';

/// Loads [FragmentProgram] for the Apple Music–style twist backdrop.
class TwistBackdropShader {
  TwistBackdropShader._();

  static Future<ui.FragmentProgram>? _programFuture;

  static Future<ui.FragmentProgram> loadProgram() {
    return _programFuture ??= ui.FragmentProgram.fromAsset(
      'shaders/twist_backdrop.frag',
    );
  }

  static void resetForTests() {
    _programFuture = null;
  }
}

/// Decodes cover art from cache/network into a [ui.Image] for the shader sampler.
Future<ui.Image?> decodeCoverImage(String url) async {
  try {
    final file = await ImageCacheManager.instance.getSingleFile(url);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// Paints the twist backdrop via [CustomPainter].
class TwistBackdropPainter extends CustomPainter {
  TwistBackdropPainter({
    required this.image,
    required this.shader,
    required this.timeSeconds,
  });

  final ui.Image image;
  final ui.FragmentShader shader;
  final double timeSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, timeSeconds);
    shader.setImageSampler(0, image);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant TwistBackdropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.shader != shader;
  }
}

/// Animated twist backdrop — ~15fps when [animating], respects reduced motion.
class TwistBackdropView extends StatefulWidget {
  const TwistBackdropView({
    super.key,
    required this.coverUrl,
    required this.animating,
    required this.fallback,
  });

  final String? coverUrl;
  final bool animating;
  final Widget fallback;

  @override
  State<TwistBackdropView> createState() => _TwistBackdropViewState();
}

class _TwistBackdropViewState extends State<TwistBackdropView>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  ui.Image? _image;
  String? _loadedUrl;
  Object? _loadError;
  late Ticker _ticker;
  double _timeSeconds = 0;
  int _frameSkip = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _bootstrap();
  }

  @override
  void didUpdateWidget(TwistBackdropView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl) {
      _loadImage(widget.coverUrl);
    }
    _syncTicker();
  }

  Future<void> _bootstrap() async {
    try {
      final program = await TwistBackdropShader.loadProgram();
      if (!mounted) return;
      setState(() => _program = program);
      await _loadImage(widget.coverUrl);
      _syncTicker();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  Future<void> _loadImage(String? url) async {
    if (url == null || url.isEmpty) {
      _image?.dispose();
      setState(() {
        _image = null;
        _loadedUrl = null;
      });
      return;
    }
    if (_loadedUrl == url && _image != null) return;

    final decoded = await decodeCoverImage(url);
    if (!mounted || widget.coverUrl != url) {
      decoded?.dispose();
      return;
    }
    final old = _image;
    setState(() {
      _image = decoded;
      _loadedUrl = url;
      _loadError = null;
    });
    old?.dispose();
  }

  void _syncTicker() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldRun =
        widget.animating && !reduceMotion && _program != null && _image != null;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    _timeSeconds = elapsed.inMicroseconds / 1e6;
    // ~15fps cap (Apple Music web uses maxFPS 15).
    _frameSkip = (_frameSkip + 1) % 4;
    if (_frameSkip == 0 && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTicker();

    if (_program == null || _image == null || _loadError != null) {
      return widget.fallback;
    }

    final shader = _program!.fragmentShader();
    return RepaintBoundary(
      child: CustomPaint(
        painter: TwistBackdropPainter(
          image: _image!,
          shader: shader,
          timeSeconds: _timeSeconds,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
