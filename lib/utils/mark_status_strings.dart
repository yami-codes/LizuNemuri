import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/mark_status.dart';

extension MarkStatusStrings on MarkStatus {
  String get localizedLabel => switch (this) {
        MarkStatus.wantToListen => Strings.markWantToListen,
        MarkStatus.listening => Strings.markListening,
        MarkStatus.listened => Strings.markListened,
        MarkStatus.relistening => Strings.markRelistening,
        MarkStatus.onHold => Strings.markOnHold,
      };
}
