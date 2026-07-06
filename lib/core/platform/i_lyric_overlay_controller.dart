abstract class ILyricOverlayController {
  /// Initialize overlay.
  Future<void> initialize();
  
  /// Show overlay.
  Future<void> show();
  
  /// Hide overlay.
  Future<void> hide();
  
  /// Update lyric text.
  Future<void> updateLyric(String? text);
  
  /// Check overlay permission.
  Future<bool> checkPermission();
  
  /// Request overlay permission.
  Future<bool> requestPermission();
  
  /// Release resources.
  Future<void> dispose();
  
  /// Whether overlay is currently shown.
  Future<bool> isShowing();

  /// Toggle draggable: true accepts touch for vertical drag; false is pass-through (default).
  Future<void> setEditable(bool editable);
}