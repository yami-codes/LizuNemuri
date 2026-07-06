import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lizunemu/data/models/llm/llm_model_option.dart';
import 'package:lizunemu/data/services/llm_model_catalog_service.dart';

/// Model name field with provider-backed autocomplete suggestions.
class LlmModelAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String endpoint;
  final String apiKey;
  final LlmModelCatalogService catalog;

  const LlmModelAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.endpoint,
    required this.apiKey,
    required this.catalog,
  });

  @override
  State<LlmModelAutocompleteField> createState() =>
      _LlmModelAutocompleteFieldState();
}

class _LlmModelAutocompleteFieldState extends State<LlmModelAutocompleteField> {
  final _focusNode = FocusNode();
  List<LlmModelOption> _options = const [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadOptions(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final results = await widget.catalog.searchModels(
          endpoint: widget.endpoint,
          apiKey: widget.apiKey,
          query: query,
          limit: 24,
        );
        if (!mounted) return;
        setState(() {
          _options = results;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _options = const [];
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<LlmModelOption>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.id,
      optionsBuilder: (textEditingValue) async {
        await _loadOptions(textEditingValue.text);
        return _options;
      },
      onSelected: (option) {
        widget.controller.text = option.id;
        widget.controller.selection = TextSelection.collapsed(
          offset: option.id.length,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.arrow_drop_down),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: option.subtitle == null
                        ? null
                        : Text(
                            option.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
