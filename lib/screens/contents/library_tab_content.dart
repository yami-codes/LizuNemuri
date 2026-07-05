import 'package:flutter/material.dart';
import 'package:xuro/screens/contents/home_content.dart';

/// Interim online-library shell until Milestone F local scan.
///
/// Reuses [HomeContent] (asmr.one browse + filters). Replace this widget when
/// `LibraryViewModel` / scan roots land — see
/// `docs/todos/active/20260705-eara-nav-milestone.md`.
class LibraryTabContent extends StatelessWidget {
  const LibraryTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContent();
  }
}
