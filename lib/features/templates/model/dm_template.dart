class DmTemplate {
  const DmTemplate({
    required this.templateId,
    required this.name,
    required this.body,
    required this.isActive,
    this.sortOrder,
  });

  final String templateId;
  final String name;
  final String body;
  final bool isActive;
  final int? sortOrder;

  static const empty = DmTemplate(
    templateId: '',
    name: '',
    body: '',
    isActive: true,
  );

  DmTemplate copyWith({
    String? templateId,
    String? name,
    String? body,
    bool? isActive,
    int? sortOrder,
  }) {
    return DmTemplate(
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      body: body ?? this.body,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory DmTemplate.fromJson(String templateId, Map<String, dynamic> json) {
    final sortOrderValue = json['sortOrder'];
    return DmTemplate(
      templateId: templateId,
      name: json['name'] is String ? json['name'] as String : '',
      body: json['body'] is String ? json['body'] as String : '',
      isActive: json['isActive'] is bool ? json['isActive'] == true : true,
      sortOrder: sortOrderValue is num ? sortOrderValue.toInt() : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'templateId': templateId,
      'name': name,
      'body': body,
      'isActive': isActive,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }
}
