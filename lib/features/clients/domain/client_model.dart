class ClientModel {
  final int? id;
  final String name;
  final String? phone;

  const ClientModel({
    this.id,
    required this.name,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
    );
  }

  ClientModel copyWith({
    int? id,
    String? name,
    String? phone,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}