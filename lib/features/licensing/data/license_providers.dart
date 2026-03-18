import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/license_status.dart';
import '../domain/licensed_device.dart';
import 'license_service.dart';

final licenseServiceProvider = Provider<LicenseService>((ref) {
  return LicenseService(
    firestore: FirebaseFirestore.instance,
  );
});

final licenseStatusProvider = FutureProvider<LicenseStatus>((ref) async {
  final service = ref.read(licenseServiceProvider);
  return service.getLicenseStatus();
});

final devicesByKeyProvider =
    StreamProvider.family<List<LicensedDevice>, String>((ref, keyDocId) {
  final service = ref.read(licenseServiceProvider);
  return service.watchDevicesByKeyDocId(keyDocId);
});