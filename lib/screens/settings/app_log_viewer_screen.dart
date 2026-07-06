import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/logging/app_log_entry.dart';
import 'package:lizunemu/core/logging/app_log_level.dart';
import 'package:lizunemu/core/logging/app_log_store.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/screens/settings/widgets/settings_group.dart';
import 'package:lizunemu/screens/settings/widgets/settings_tile.dart';
import 'package:lizunemu/screens/settings/widgets/settings_theme.dart';
import 'package:lizunemu/utils/logger.dart';

class AppLogViewerScreen extends StatefulWidget {
  const AppLogViewerScreen({super.key});

  @override
  State<AppLogViewerScreen> createState() => _AppLogViewerScreenState();
}

class _AppLogViewerScreenState extends State<AppLogViewerScreen> {
  final _searchController = TextEditingController();
  final _store = GetIt.I<AppLogStore>();
  final _settings = GetIt.I<AppSettingsService>();

  AppLogLevel _viewMinLevel = AppLogLevel.verbose;
  bool _includeStackOnCopy = true;
  int? _expandedIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLogEntry> get _visibleEntries => _store.filteredNewestFirst(
        minimum: _viewMinLevel,
        query: _searchController.text,
      );

  Future<void> _copyText(String text) async {
    if (text.trim().isEmpty) {
      _showSnack(Strings.logViewerNothingToCopy);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(Strings.logViewerCopied);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyAll() async {
    final text = _store.exportText(
      minimum: _viewMinLevel,
      query: _searchController.text,
      includeStack: _includeStackOnCopy,
    );
    await _copyText(text);
  }

  Future<void> _copyEntry(AppLogEntry entry) async {
    await _copyText(entry.formatLine(includeStack: _includeStackOnCopy));
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.logViewerClearConfirmTitle),
        content: Text(Strings.logViewerClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Strings.logViewerClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _store.clear();
    setState(() => _expandedIndex = null);
    _showSnack(Strings.logViewerCleared);
  }

  Future<void> _pickCaptureLevel() async {
    final picked = await showModalBottomSheet<AppLogLevel>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Text(
                Strings.logCaptureLevel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final level in AppLogLevel.values)
              ListTile(
                title: Text(Strings.logLevelLabel(level)),
                trailing: _settings.logCaptureMinLevel == level
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, level),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _settings.setLogCaptureMinLevel(picked);
    AppLogger.setCaptureMinLevel(picked);
    setState(() {});
  }

  Color _levelColor(AppLogLevel level, ColorScheme scheme) {
    return switch (level) {
      AppLogLevel.verbose => scheme.outline,
      AppLogLevel.debug => scheme.secondary,
      AppLogLevel.info => scheme.primary,
      AppLogLevel.warning => scheme.tertiary,
      AppLogLevel.error => scheme.error,
    };
  }

  String _shortTime(DateTime ts) {
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    final s = ts.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = SettingsTheme.pageBackground(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(Strings.logViewerTitle),
        actions: [
          IconButton(
            tooltip: Strings.logViewerCopyAll,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyAll,
          ),
          IconButton(
            tooltip: Strings.logViewerClear,
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: SettingsTheme.noSplashTheme(
        context: context,
        child: ListenableBuilder(
          listenable: Listenable.merge([_store, _settings]),
          builder: (context, _) {
            final entries = _visibleEntries;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space8,
                    AppSpacing.space16,
                    AppSpacing.space8,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: Strings.logViewerSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.mdAll,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AppLogLevel>(
                              value: _viewMinLevel,
                              decoration: InputDecoration(
                                labelText: Strings.logViewerFilterLevel,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.mdAll,
                                ),
                              ),
                              items: [
                                for (final level in AppLogLevel.values)
                                  DropdownMenuItem(
                                    value: level,
                                    child: Text(Strings.logLevelLabel(level)),
                                  ),
                              ],
                              onChanged: (level) {
                                if (level == null) return;
                                setState(() {
                                  _viewMinLevel = level;
                                  _expandedIndex = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Strings.logViewerEntryCount(
                            entries.length,
                            _store.count,
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                SettingsGroup(
                  header: Strings.logCaptureLevel,
                  footer: Strings.logCaptureLevelDesc,
                  children: [
                    SettingsTile.navigation(
                      title: Strings.logLevelLabel(_settings.logCaptureMinLevel),
                      subtitle: Strings.logCaptureLevelDesc,
                      leading: Icons.tune_outlined,
                      onTap: _pickCaptureLevel,
                    ),
                    SettingsTile.toggle(
                      title: Strings.logViewerIncludeStack,
                      leading: Icons.layers_outlined,
                      value: _includeStackOnCopy,
                      onChanged: (v) => setState(() => _includeStackOnCopy = v),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.space24),
                            child: Text(
                              Strings.logViewerEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space16,
                            0,
                            AppSpacing.space16,
                            AppSpacing.space24,
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.space8),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final expanded = _expandedIndex == index;
                            final levelColor = _levelColor(entry.level, colorScheme);

                            return Material(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: AppRadius.mdAll,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => setState(
                                  () => _expandedIndex = expanded ? null : index,
                                ),
                                onLongPress: () => _copyEntry(entry),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.space12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.space8,
                                              vertical: AppSpacing.space4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: levelColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius: AppRadius.smAll,
                                            ),
                                            child: Text(
                                              Strings.logLevelLabel(entry.level),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(color: levelColor),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.space8),
                                          Text(
                                            _shortTime(entry.timestamp),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          if (entry.tag != null &&
                                              entry.tag!.isNotEmpty) ...[
                                            const SizedBox(
                                              width: AppSpacing.space8,
                                            ),
                                            Expanded(
                                              child: Text(
                                                '[${entry.tag}]',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme.primary,
                                                    ),
                                              ),
                                            ),
                                          ] else
                                            const Spacer(),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: Strings.logViewerCopyEntry,
                                            icon: Icon(
                                              Icons.copy_outlined,
                                              size: 18,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () => _copyEntry(entry),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.space8),
                                      Text(
                                        entry.message,
                                        maxLines: expanded ? null : 3,
                                        overflow: expanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                      ),
                                      if (expanded) ...[
                                        if (entry.errorText != null &&
                                            entry.errorText!.trim().isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.space8),
                                          Text(
                                            entry.errorText!.trim(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.error,
                                                ),
                                          ),
                                        ],
                                        if (entry.stackTraceText != null &&
                                            entry.stackTraceText!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.space8),
                                          SelectableText(
                                            entry.stackTraceText!.trim(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontFamily: 'monospace',
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
