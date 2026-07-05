import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/presentation/viewmodels/downloads_viewmodel.dart';
import 'package:xuro/screens/contents/downloads_hub_content.dart';
import 'package:xuro/widgets/common/back_leading.dart';

/// Full-page downloads hub (sidebar route).
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DownloadsViewModel(),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackLeading(),
          automaticallyImplyLeading: false,
          title: Text(Strings.downloadsTitle),
        ),
        body: const DownloadsHubContent(),
      ),
    );
  }
}
