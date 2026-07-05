import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/playlists_viewmodel.dart';
import 'package:lizunemu/presentation/widgets/auth/login_dialog.dart';
import 'package:lizunemu/screens/contents/playlists_content.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';

/// Drawer route for user playlists (liked / marked / custom lists).
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  bool _loginChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loginChecked) return;
    _loginChecked = true;
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
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlaylistsViewModel(),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackLeading(),
          automaticallyImplyLeading: false,
          title: Text(Strings.playlistsTitle),
        ),
        body: const PlaylistsContent(),
      ),
    );
  }
}
