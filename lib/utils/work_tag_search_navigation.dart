import 'package:flutter/material.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';
import 'package:lizunemu/screens/search_screen.dart';

/// Open [SearchScreen] with an asmr.one tag filter token pre-filled.
void openSearchWithTagToken(BuildContext context, String apiTagName) {
  if (apiTagName.trim().isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchScreen(
        initialKeyword: SearchCommandParser.includeTagToken(apiTagName),
      ),
    ),
  );
}

void openSearchWithExcludeTagToken(BuildContext context, String apiTagName) {
  if (apiTagName.trim().isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchScreen(
        initialKeyword: SearchCommandParser.excludeTagToken(apiTagName),
      ),
    ),
  );
}
