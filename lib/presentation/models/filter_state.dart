import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';

class FilterState {
  final String orderField;
  final bool isDescending;

  const FilterState({
    this.orderField = 'create_date',
    this.isDescending = true,
  });

  bool get showSortDirection => orderField != 'random';

  String get sortValue => orderField == 'random' ? 'desc' : (isDescending ? 'desc' : 'asc');

  WorkListFilterPreset get activePreset =>
      WorkListFilterPresetX.fromOrder(
        orderField: orderField,
        isDescending: isDescending,
      );

  FilterState copyWith({
    String? orderField,
    bool? isDescending,
  }) {
    return FilterState(
      orderField: orderField ?? this.orderField,
      isDescending: isDescending ?? this.isDescending,
    );
  }

  FilterState copyWithPreset(WorkListFilterPreset preset) {
    return FilterState(
      orderField: preset.orderField,
      isDescending: preset.isDescending,
    );
  }

  // Serialization
  Map<String, dynamic> toJson() => {
    'orderField': orderField,
    'isDescending': isDescending,
  };

  // Deserialization
  factory FilterState.fromJson(Map<String, dynamic> json) => FilterState(
    orderField: json['orderField'] ?? 'create_date',
    isDescending: json['isDescending'] ?? true,
  );
} 