import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/llm_batch_split_mode.dart';
import 'package:lizunemu/core/settings/llm_subtitle_display_mode.dart';
import 'package:lizunemu/core/settings/llm_subtitle_target_language.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/screens/settings/llm_usage_history_screen.dart';
import 'package:lizunemu/screens/settings/widgets/settings_group.dart';
import 'package:lizunemu/screens/settings/widgets/settings_tile.dart';
import 'package:lizunemu/screens/settings/widgets/settings_theme.dart';

/// LLM subtitle translation API + prompt configuration.
class LlmTranslationSettingsScreen extends StatefulWidget {
  final AppSettingsService settings;

  const LlmTranslationSettingsScreen({super.key, required this.settings});

  @override
  State<LlmTranslationSettingsScreen> createState() =>
      _LlmTranslationSettingsScreenState();
}

class _LlmTranslationSettingsScreenState
    extends State<LlmTranslationSettingsScreen> {
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _liteModelCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _systemPromptCtrl;
  late final TextEditingController _jailbreakPromptCtrl;
  late final TextEditingController _manualBatchSizeCtrl;
  bool _obscureKey = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: widget.settings.llmApiEndpoint);
    _modelCtrl = TextEditingController(text: widget.settings.llmMainModel);
    _liteModelCtrl =
        TextEditingController(text: widget.settings.llmLiteModel);
    _apiKeyCtrl = TextEditingController();
    _systemPromptCtrl =
        TextEditingController(text: widget.settings.llmSystemPromptOverride);
    _jailbreakPromptCtrl =
        TextEditingController(text: widget.settings.llmJailbreakPrompt);
    _manualBatchSizeCtrl = TextEditingController(
      text: widget.settings.llmManualBatchSize.toString(),
    );
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await GetIt.I<LlmApiKeyRepository>().getApiKey();
    if (!mounted) return;
    _apiKeyCtrl.text = key ?? '';
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _modelCtrl.dispose();
    _liteModelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _systemPromptCtrl.dispose();
    _jailbreakPromptCtrl.dispose();
    _manualBatchSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.settings.setLlmApiEndpoint(_endpointCtrl.text);
      await widget.settings.setLlmMainModel(_modelCtrl.text);
      await widget.settings.setLlmLiteModel(_liteModelCtrl.text);
      await widget.settings.setLlmSystemPromptOverride(_systemPromptCtrl.text);
      await widget.settings.setLlmJailbreakPrompt(_jailbreakPromptCtrl.text);
      final batchSize = int.tryParse(_manualBatchSizeCtrl.text.trim());
      if (batchSize != null) {
        await widget.settings.setLlmManualBatchSize(batchSize);
      }
      final key = _apiKeyCtrl.text.trim();
      final repo = GetIt.I<LlmApiKeyRepository>();
      if (key.isEmpty) {
        await repo.clearApiKey();
      } else {
        await repo.saveApiKey(key);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.llmSettingsSaved)),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = SettingsTheme.pageBackground(context);

    return Scaffold(
      appBar: AppBar(title: Text(Strings.llmTranslationConfigure)),
      backgroundColor: bg,
      body: SettingsTheme.noSplashTheme(
        context: context,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SettingsGroup(
              header: Strings.llmApiEndpoint,
              children: [
                _presetRow(
                  Strings.llmPresetOpenAi,
                  AppSettingsService.defaultLlmApiEndpoint,
                ),
                _presetRow(
                  Strings.llmPresetOpenRouter,
                  AppSettingsService.defaultOpenRouterEndpoint,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _endpointCtrl,
                    decoration: InputDecoration(
                      labelText: Strings.llmApiEndpoint,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              header: Strings.llmMainModel,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _modelCtrl,
                    decoration: InputDecoration(
                      labelText: Strings.llmMainModel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              header: Strings.llmLiteModel,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _liteModelCtrl,
                    decoration: InputDecoration(
                      labelText: Strings.llmLiteModel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              header: Strings.llmApiKey,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _apiKeyCtrl,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: Strings.llmApiKey,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => SettingsGroup(
                header: Strings.llmSubtitleDisplayMode,
                children: [
                  SettingsTile.selection(
                    title: Strings.llmSubtitleDisplayDual,
                    subtitle: Strings.llmSubtitleDisplayDualDesc,
                    leading: Icons.layers_outlined,
                    selected: widget.settings.llmSubtitleDisplayMode ==
                        LlmSubtitleDisplayMode.dual,
                    onTap: () => widget.settings
                        .setLlmSubtitleDisplayMode(LlmSubtitleDisplayMode.dual),
                  ),
                  SettingsTile.selection(
                    title: Strings.llmSubtitleDisplayTranslationOnly,
                    subtitle: Strings.llmSubtitleDisplayTranslationOnlyDesc,
                    leading: Icons.subtitles_outlined,
                    selected: widget.settings.llmSubtitleDisplayMode ==
                        LlmSubtitleDisplayMode.translationOnly,
                    onTap: () => widget.settings.setLlmSubtitleDisplayMode(
                      LlmSubtitleDisplayMode.translationOnly,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => SettingsGroup(
                header: Strings.llmTargetLanguage,
                children: LlmSubtitleTargetLanguage.values
                    .map(
                      (lang) => SettingsTile.selection(
                        title: _targetLangLabel(lang),
                        leading: Icons.language_outlined,
                        selected: widget.settings.llmTargetLanguage == lang,
                        onTap: () => widget.settings.setLlmTargetLanguage(lang),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => SettingsGroup(
                header: Strings.llmBatchSplitMode,
                children: [
                  ...LlmBatchSplitMode.values.map(
                    (mode) => SettingsTile.selection(
                      title: _splitModeLabel(mode),
                      leading: Icons.view_agenda_outlined,
                      selected: widget.settings.llmBatchSplitMode == mode,
                      onTap: () => widget.settings.setLlmBatchSplitMode(mode),
                    ),
                  ),
                  if (widget.settings.llmBatchSplitMode ==
                      LlmBatchSplitMode.manual)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _manualBatchSizeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: Strings.llmManualBatchSize,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => SettingsGroup(
                header: Strings.llmStreamingEnabled,
                footer: Strings.llmStreamingEnabledDesc,
                children: [
                  SettingsTile.toggle(
                    title: Strings.llmStreamingEnabled,
                    leading: Icons.stream_outlined,
                    value: widget.settings.llmStreamingEnabled,
                    onChanged: widget.settings.setLlmStreamingEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              header: Strings.llmUsageHistory,
              children: [
                SettingsTile.navigation(
                  title: Strings.llmUsageHistoryTitle,
                  leading: Icons.receipt_long_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LlmUsageHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => SettingsGroup(
                header: Strings.llmJailbreakPrompt,
                footer: Strings.llmJailbreakAutoDesc,
                children: [
                  SettingsTile.toggle(
                    title: Strings.llmJailbreakAuto,
                    leading: Icons.shield_outlined,
                    value: widget.settings.llmJailbreakAuto,
                    onChanged: widget.settings.setLlmJailbreakAuto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              header: Strings.llmSystemPrompt,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _systemPromptCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: Strings.llmSystemPromptHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              header: Strings.llmJailbreakPrompt,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _jailbreakPromptCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: Strings.llmJailbreakPromptHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(Strings.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetRow(String label, String endpoint) {
    return SettingsTile.selection(
      title: label,
      subtitle: endpoint,
      leading: Icons.link_outlined,
      selected: _endpointCtrl.text.trim() == endpoint,
      onTap: () {
        setState(() => _endpointCtrl.text = endpoint);
      },
    );
  }

  String _splitModeLabel(LlmBatchSplitMode mode) {
    switch (mode) {
      case LlmBatchSplitMode.none:
        return Strings.llmBatchSplitNone;
      case LlmBatchSplitMode.provider:
        return Strings.llmBatchSplitProvider;
      case LlmBatchSplitMode.manual:
        return Strings.llmBatchSplitManual;
    }
  }

  String _targetLangLabel(LlmSubtitleTargetLanguage lang) {
    switch (lang) {
      case LlmSubtitleTargetLanguage.system:
        return Strings.llmTargetLangSystem;
      case LlmSubtitleTargetLanguage.en:
        return Strings.llmTargetLangEn;
      case LlmSubtitleTargetLanguage.zh:
        return Strings.llmTargetLangZh;
      case LlmSubtitleTargetLanguage.ja:
        return Strings.llmTargetLangJa;
      case LlmSubtitleTargetLanguage.th:
        return Strings.llmTargetLangTh;
      case LlmSubtitleTargetLanguage.ko:
        return Strings.llmTargetLangKo;
    }
  }
}
