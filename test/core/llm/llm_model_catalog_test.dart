import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/llm/llm_endpoint_utils.dart';
import 'package:lizunemu/core/settings/llm_provider_kind.dart';
import 'package:lizunemu/data/services/llm_model_catalog_service.dart';

void main() {
  group('LlmEndpointUtils.detect', () {
    test('detects OpenRouter', () {
      expect(
        LlmEndpointUtils.detect('https://openrouter.ai/api/v1'),
        LlmProviderKind.openRouter,
      );
    });

    test('detects Gemini OpenAI-compat endpoint', () {
      expect(
        LlmEndpointUtils.detect(
          'https://generativelanguage.googleapis.com/v1beta/openai',
        ),
        LlmProviderKind.gemini,
      );
    });

    test('detects OpenAI', () {
      expect(
        LlmEndpointUtils.detect('https://api.openai.com/v1'),
        LlmProviderKind.openAi,
      );
    });

    test('unknown host is custom', () {
      expect(
        LlmEndpointUtils.detect('https://llm.example.com/v1'),
        LlmProviderKind.custom,
      );
    });
  });

  group('LlmModelCatalogService parsing', () {
    test('parses OpenRouter model row', () {
      final option = LlmModelCatalogService.parseOpenRouterModelForTest({
        'id': 'google/gemma-4-31b-it:free',
        'name': 'Gemma 4 31B IT (free)',
        'context_length': 128000,
        'pricing': {'prompt': '0', 'completion': '0'},
      });
      expect(option.id, 'google/gemma-4-31b-it:free');
      expect(option.contextLength, 128000);
    });
  });
}
