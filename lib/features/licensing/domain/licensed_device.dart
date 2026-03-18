import 'package:cloud_firestore/cloud_firestore.dart';

class LicensedDevice {
  final String installationId;
  final String deviceName;
  final bool active;
  final DateTime? activatedAt;
  final DateTime? lastAccessAt;

  const LicensedDevice({
    required this.installationId,
    required this.deviceName,
    required this.active,
    this.activatedAt,
    this.lastAccessAt,
  });

  factory LicensedDevice.fromMap(Map<String, dynamic> map) {
    DateTime? parseTs(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return LicensedDevice(
      installationId: (map['installationId'] ?? '').toString(),
      deviceName: (map['deviceName'] ?? 'Aparelho sem nome').toString(),
      active: map['active'] == true,
      activatedAt: parseTs(map['activatedAt']),
      lastAccessAt: parseTs(map['lastAccessAt']),
    );
  }
}