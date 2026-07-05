import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lizunemu/presentation/widgets/auth/register_dialog.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final name = _nameController.text.trim();
    AppLogger.info(LogStrings.logLogindialogLoginAttemptNameN70c23(name));

    final authVM = context.read<AuthViewModel>();
    await authVM.login(name, _passwordController.text);

    if (mounted) {
      if (authVM.error == null) {
        AppLogger.info(LogStrings.logLogindialogLoginOkClosing833b9);
        Navigator.of(context).pop();
      } else {
        AppLogger.error(LogStrings.logLogindialogLoginFailedAuthvmaa6d5(authVM.error));
      }
    }
  }

  void _switchToRegister() {
    final navigator = Navigator.of(context);
    context.read<AuthViewModel>().clearError();
    navigator.pop();
    showDialog(
      context: navigator.context,
      useRootNavigator: true,
      builder: (_) => const RegisterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Strings.loginAction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: Strings.username,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: Strings.password,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 8),
          Consumer<AuthViewModel>(
            builder: (context, authVM, _) {
              if (authVM.error != null) {
                return Text(
                  authVM.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _switchToRegister,
              child: Text(Strings.registerCta),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Strings.cancel),
        ),
        Consumer<AuthViewModel>(
          builder: (context, authVM, _) {
            return FilledButton(
              onPressed: authVM.isLoading ? null : _handleLogin,
              child: authVM.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(Strings.loginAction),
            );
          },
        ),
      ],
    );
  }
} 