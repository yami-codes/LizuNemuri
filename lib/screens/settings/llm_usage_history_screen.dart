import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/llm/llm_usage_record.dart';
import 'package:lizunemu/data/repositories/llm_usage_repository.dart';
import 'package:lizunemu/data/services/llm_client.dart';
import 'package:lizunemu/screens/settings/widgets/settings_group.dart';
import 'package:lizunemu/screens/settings/widgets/settings_theme.dart';

/// Token / cost history for LLM subtitle and title translation.
class LlmUsageHistoryScreen extends StatefulWidget {
  const LlmUsageHistoryScreen({super.key});

  @override
  State<LlmUsageHistoryScreen> createState() => _LlmUsageHistoryScreenState();
}

class _LlmUsageHistoryScreenState extends State<LlmUsageHistoryScreen> {
  final _usageRepo = GetIt.I<LlmUsageRepository>();
  final _client = GetIt.I<LlmClient>();

  List<LlmUsageRecord> _history = [];
  LlmAccountBalance? _balance;
  ({int totalTokens, double totalCostUsd, int requestCount})? _totals;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final history = await _usageRepo.listHistory(limit: 200);
    final totals = await _usageRepo.totals();
    final balance = await _client.fetchOpenRouterBalance();
    if (!mounted) return;
    setState(() {
      _history = history;
      _totals = totals;
      _balance = balance;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    await _usageRepo.clearHistory();
    await _reload();
  }

  String _formatCost(double? usd) {
    if (usd == null) return '—';
    return usd.toStringAsFixed(usd < 0.01 ? 6 : 4);
  }

  String _operationLabel(String operation) {
    switch (operation) {
      case 'subtitle_translate':
        return Strings.llmUsageOperationSubtitle;
      case 'title_translate':
        return Strings.llmUsageOperationTitle;
      default:
        return operation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = SettingsTheme.pageBackground(context);
    final dateFmt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.llmUsageHistoryTitle),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: Strings.llmUsageClearHistory,
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_totals != null) ...[
                    SettingsGroup(
                      header: Strings.llmUsageHistory,
                      children: [
                        ListTile(
                          title: Text(
                            Strings.llmUsageTotalTokens(_totals!.totalTokens),
                          ),
                          subtitle: Text(
                            Strings.llmUsageTotalCost(
                              _formatCost(_totals!.totalCostUsd),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_balance != null) ...[
                    SettingsGroup(
                      header: Strings.llmOpenRouterBalance,
                      children: [
                        if (_balance!.usageUsd != null)
                          ListTile(
                            title: Text(
                              Strings.llmOpenRouterBalanceUsage(
                                _formatCost(_balance!.usageUsd),
                              ),
                            ),
                          ),
                        if (_balance!.limitUsd != null)
                          ListTile(
                            title: Text(
                              Strings.llmOpenRouterBalanceLimit(
                                _formatCost(_balance!.limitUsd),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          Strings.llmUsageHistoryEmpty,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ..._history.map((record) {
                      final cost = record.totalCostUsd != null
                          ? '\$${_formatCost(record.totalCostUsd)}'
                          : '—';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(_operationLabel(record.operation)),
                          subtitle: Text(
                            [
                              record.model,
                              if (record.trackName != null) record.trackName!,
                              dateFmt.format(record.timestamp),
                            ].join(' · '),
                          ),
                          trailing: Text(
                            Strings.llmUsageRecordLine(
                              record.totalTokens,
                              cost,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
