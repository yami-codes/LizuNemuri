import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/llm_provider_kind.dart';

/// Endpoint normalization + provider detection for OpenAI-compatible APIs.
class LlmEndpointUtils {
  LlmEndpointUtils._();

  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static LlmProviderKind detect(String endpoint) {
    final url = normalize(endpoint).toLowerCase();
    if (url.isEmpty) return LlmProviderKind.custom;
    if (url.contains('openrouter.ai')) return LlmProviderKind.openRouter;
    if (url.contains('generativelanguage.googleapis.com')) {
      return LlmProviderKind.gemini;
    }
    if (url.contains('api.openai.com')) return LlmProviderKind.openAi;
    return LlmProviderKind.custom;
  }

  /// Preset bundle applied when the user picks a provider tile.
  static ({
    String endpoint,
    String mainModel,
    String liteModel,
  }) presetFor(LlmProviderKind kind) {
    switch (kind) {
      case LlmProviderKind.openRouter:
        return (
          endpoint: AppSettingsService.defaultOpenRouterEndpoint,
          mainModel: AppSettingsService.defaultOpenRouterMainModel,
          liteModel: AppSettingsService.defaultOpenRouterLiteModel,
        );
      case LlmProviderKind.gemini:
        return (
          endpoint: AppSettingsService.defaultGeminiEndpoint,
          mainModel: AppSettingsService.defaultGeminiMainModel,
          liteModel: AppSettingsService.defaultGeminiLiteModel,
        );
      case LlmProviderKind.openAi:
        return (
          endpoint: AppSettingsService.defaultLlmApiEndpoint,
          mainModel: AppSettingsService.defaultOpenAiMainModel,
          liteModel: AppSettingsService.defaultOpenAiLiteModel,
        );
      case LlmProviderKind.custom:
        return (
          endpoint: '',
          mainModel: '',
          liteModel: '',
        );
    }
  }
}
