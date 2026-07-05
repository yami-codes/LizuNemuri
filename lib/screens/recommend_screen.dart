import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/recommend_viewmodel.dart';
import 'package:lizunemu/presentation/widgets/auth/login_dialog.dart';
import 'package:lizunemu/screens/contents/recommend_content.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';

/// Drawer route for personalized recommendations (formerly a bottom tab).
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  late RecommendViewModel _viewModel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final auth = context.read<AuthViewModel>();
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showDialog(
          context: context,
          useRootNavigator: true,
          builder: (_) => const LoginDialog(),
        );
        if (!mounted) return;
        if (!context.read<AuthViewModel>().isLoggedIn) {
          Navigator.of(context).pop();
        }
      });
    }
    _viewModel = RecommendViewModel(auth);
  }

  @override
  void dispose() {
    if (_initialized) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackLeading(),
          automaticallyImplyLeading: false,
          title: Text(Strings.homeTitleRecommend),
        ),
        body: const RecommendContent(),
      ),
    );
  }
}
