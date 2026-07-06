import 'package:flutter/material.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/works/i18n.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';
import 'package:lizunemu/presentation/models/search_command_suggestions.dart';
import 'package:lizunemu/utils/tag_display_name.dart';
import 'package:get_it/get_it.dart';

/// Chip-based search field with `$command:value$` autocomplete (asmr.one style).
class SearchCommandField extends StatefulWidget {
  const SearchCommandField({
    super.key,
    required this.tokens,
    required this.onTokensChanged,
    required this.draftController,
    this.onDraftChanged,
    this.onSubmitted,
    this.hintText,
    this.tagNames = const [],
    this.tagCatalog = const {},
    this.suffixIcon,
  });

  final List<String> tokens;
  final ValueChanged<List<String>> onTokensChanged;
  final TextEditingController draftController;
  final ValueChanged<String>? onDraftChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final List<String> tagNames;
  final Map<String, I18n> tagCatalog;
  final Widget? suffixIcon;

  @override
  State<SearchCommandField> createState() => _SearchCommandFieldState();
}

class _SearchCommandFieldState extends State<SearchCommandField> {
  final _focusNode = FocusNode();
  List<SearchCommandSuggestion> _suggestions = const [];

  AppSettingsService get _settings => GetIt.I<AppSettingsService>();

  @override
  void initState() {
    super.initState();
    widget.draftController.addListener(_refreshSuggestions);
  }

  @override
  void didUpdateWidget(covariant SearchCommandField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftController != widget.draftController) {
      oldWidget.draftController.removeListener(_refreshSuggestions);
      widget.draftController.addListener(_refreshSuggestions);
    }
    _refreshSuggestions();
  }

  @override
  void dispose() {
    widget.draftController.removeListener(_refreshSuggestions);
    _focusNode.dispose();
    super.dispose();
  }

  void _refreshSuggestions() {
    final draft = widget.draftController.text;
    final cursor = widget.draftController.selection.baseOffset;
    final next = SearchCommandSuggestor.suggest(
      draft: draft,
      cursor: cursor < 0 ? draft.length : cursor,
      tagNames: widget.tagNames,
    );
    if (!mounted) return;
    setState(() => _suggestions = next);
    widget.onDraftChanged?.call(draft);
  }

  void _notifyTokens(List<String> tokens) {
    widget.onTokensChanged(List<String>.from(tokens));
  }

  void _removeToken(int index) {
    final next = List<String>.from(widget.tokens)..removeAt(index);
    _notifyTokens(next);
  }

  void _clearAll() {
    _notifyTokens([]);
    widget.draftController.clear();
    _refreshSuggestions();
  }

  void _promoteDraftTokens() {
    final extracted = SearchCommandSuggestor.extractCompleteTokens(
      tokens: widget.tokens,
      draft: widget.draftController.text,
    );
    if (extracted.tokens.length != widget.tokens.length ||
        extracted.draft != widget.draftController.text) {
      _notifyTokens(extracted.tokens);
      widget.draftController.text = extracted.draft;
      widget.draftController.selection = TextSelection.collapsed(
        offset: extracted.draft.length,
      );
    }
  }

  void _applySuggestion(SearchCommandSuggestion suggestion) {
    final draft = widget.draftController.text;
    final cursor = widget.draftController.selection.baseOffset;
    final applied = SearchCommandSuggestor.apply(
      draft: draft,
      cursor: cursor < 0 ? draft.length : cursor,
      suggestion: suggestion,
    );

    if (suggestion.completeToken) {
      final extracted = SearchCommandSuggestor.extractCompleteTokens(
        tokens: widget.tokens,
        draft: applied.draft,
      );
      _notifyTokens(extracted.tokens);
      widget.draftController.text = extracted.draft;
      widget.draftController.selection = TextSelection.collapsed(
        offset: extracted.draft.length,
      );
    } else {
      widget.draftController.text = applied.draft;
      widget.draftController.selection = TextSelection.collapsed(
        offset: applied.cursor,
      );
    }
    _refreshSuggestions();
  }

  String _chipLabel(String raw) {
    final match = SearchCommandParser.parse(raw);
    if (match.tokens.isEmpty) return raw;
    final token = match.tokens.first;
    final tagNames = SearchCommandParser.parseTagNames([token]);
    if (tagNames.include.isNotEmpty) {
      final api = tagNames.include.first;
      return TagDisplayName.forApiName(
        apiName: api,
        catalog: widget.tagCatalog,
        appLanguage: _settings.appLanguage,
      );
    }
    if (tagNames.exclude.isNotEmpty) {
      final api = tagNames.exclude.first;
      return '−${TagDisplayName.forApiName(
        apiName: api,
        catalog: widget.tagCatalog,
        appLanguage: _settings.appLanguage,
      )}';
    }
    return raw;
  }

  bool _isExcludeToken(String raw) => raw.contains(r'$-tag:');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: brightness == Brightness.dark
              ? cs.surfaceContainerHighest
              : Colors.white,
          borderRadius: AppRadius.fullAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.search, color: cs.onSurfaceVariant, size: 22),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.space4,
                    runSpacing: AppSpacing.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...widget.tokens.asMap().entries.map((entry) {
                        final raw = entry.value;
                        final exclude = _isExcludeToken(raw);
                        return InputChip(
                          label: Text(
                            _chipLabel(raw),
                            style: TextStyle(
                              color: exclude ? cs.error : cs.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              exclude ? cs.errorContainer : cs.onSurface,
                          deleteIconColor:
                              exclude ? cs.onErrorContainer : cs.surface,
                          onDeleted: () => _removeToken(entry.key),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120),
                        child: TextField(
                          controller: widget.draftController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: widget.tokens.isEmpty
                                ? widget.hintText
                                : null,
                            hintStyle: TextStyle(color: cs.onSurfaceVariant),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(color: cs.onSurface),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            _promoteDraftTokens();
                            widget.onSubmitted?.call(
                              SearchCommandParser.compose(
                                tokens: widget.tokens,
                                freeText: widget.draftController.text,
                              ),
                            );
                          },
                          onChanged: (_) => _refreshSuggestions(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.suffixIcon != null)
                  widget.suffixIcon!
                else if (widget.tokens.isNotEmpty ||
                    widget.draftController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearAll,
                    tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                  ),
              ],
            ),
          ),
        ),
        if (_suggestions.isNotEmpty && _focusNode.hasFocus)
          Material(
            elevation: 4,
            color: cs.inverseSurface,
            borderRadius: AppRadius.smAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      s.title,
                      style: TextStyle(
                        color: cs.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: s.subtitle == null
                        ? null
                        : Text(
                            s.subtitle!,
                            style: TextStyle(
                              color: cs.onInverseSurface.withValues(alpha: 0.72),
                              fontSize: 11,
                            ),
                          ),
                    onTap: () => _applySuggestion(s),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
