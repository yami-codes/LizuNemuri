import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';

void showTagFilterSnackBar(
  BuildContext context, {
  required String tagLabel,
  required bool excluded,
}) {
  final text = excluded
      ? Strings.filterTagAddedExclude(tagLabel)
      : Strings.filterTagAddedInclude(tagLabel);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
