import 'package:flutter/material.dart';

/// Back button for pushed routes. Use when a [Scaffold.drawer] would otherwise
/// steal the AppBar leading slot on desktop (menu icon with no way to pop).
class BackLeading extends StatelessWidget {
  const BackLeading({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return BackButton(onPressed: () => Navigator.of(context).maybePop());
  }
}

/// AppBar that always shows an explicit back control when the route can pop.
class PoppableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;

  const PoppableAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const BackLeading(),
      automaticallyImplyLeading: false,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
    );
  }
}
