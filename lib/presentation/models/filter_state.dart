class FilterState {
  final String orderField;
  final bool isDescending;

  const FilterState({
    this.orderField = 'create_date',
    this.isDescending = true,
  });

  bool get showSortDirection => orderField != 'random';

  String get sortValue => orderField == 'random' ? 'desc' : (isDescending ? 'desc' : 'asc');

  FilterState copyWith({
    String? orderField,
    bool? isDescending,
  }) {
    return FilterState(
      orderField: orderField ?? this.orderField,
      isDescending: isDescending ?? this.isDescending,
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