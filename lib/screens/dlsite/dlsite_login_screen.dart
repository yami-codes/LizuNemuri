import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/dlsite/auth/dlsite_auth_repository.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';

/// Cookie-based DLsite Play login (v1 — paste browser cookie).
class DlsiteLoginScreen extends StatefulWidget {
  const DlsiteLoginScreen({super.key});

  @override
  State<DlsiteLoginScreen> createState() => _DlsiteLoginScreenState();
}

class _DlsiteLoginScreenState extends State<DlsiteLoginScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cookie = _controller.text.trim();
    if (cookie.isEmpty) return;
    setState(() => _saving = true);
    await GetIt.I<DlsiteAuthRepository>().savePlayCookie(cookie);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const BackLeading(),
        automaticallyImplyLeading: false,
        title: Text(Strings.dlsiteLoginTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageMobile),
        children: [
          Text(
            Strings.dlsiteDisclaimer,
            style: AppTextStyles.bodyMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: Strings.dlsiteCookieHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(Strings.dlsiteCookieSave),
          ),
        ],
      ),
    );
  }
}
