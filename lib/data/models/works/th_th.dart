import 'package:freezed_annotation/freezed_annotation.dart';

part 'th_th.freezed.dart';
part 'th_th.g.dart';

@freezed
class ThTh with _$ThTh {
  factory ThTh({
    String? name,
    List<dynamic>? history,
  }) = _ThTh;

  factory ThTh.fromJson(Map<String, dynamic> json) => _$ThThFromJson(json);
}
