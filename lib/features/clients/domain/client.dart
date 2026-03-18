import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final String id;
  final String name;
  final String phoneE164; // ex: +5511999999999
  final String? notes;
  final DateTime createdAt;

  /// NOVO: data de nascimento (somente dia/mês/ano)
  final DateTime? birthDate;

  const Client({
    required this.id,
    required this.name,
    required this.phoneE164,
    required this.createdAt,
    this.notes,
    this.birthDate,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phoneE164': phoneE164,
        'notes': notes,
        'createdAt': createdAt.toUtc(),

        // salva como Timestamp (UTC). Mantém como meia-noite pra evitar “virar o dia”
        'birthDate': birthDate == null
            ? null
            : Timestamp.fromDate(
                DateTime(birthDate!.year, birthDate!.month, birthDate!.day).toUtc(),
              ),
      };

  factory Client.fromMap(String id, Map<String, dynamic> map) {
    final birthRaw = map['birthDate'];

    DateTime? birth;
    if (birthRaw is Timestamp) {
      final d = birthRaw.toDate();
      birth = DateTime(d.year, d.month, d.day);
    }

    final createdRaw = map['createdAt'];
    DateTime created;
    if (createdRaw is Timestamp) {
      created = createdRaw.toDate();
    } else {
      created = DateTime.now();
    }

    return Client(
      id: id,
      name: (map['name'] ?? '') as String,
      phoneE164: (map['phoneE164'] ?? '') as String,
      notes: map['notes'] as String?,
      createdAt: created,
      birthDate: birth,
    );
  }

  @override
  List<Object?> get props => [id, name, phoneE164, notes, createdAt, birthDate];
}
