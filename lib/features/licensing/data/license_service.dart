import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/license_status.dart';
import '../domain/licensed_device.dart';

class LicenseService {
  LicenseService({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _firstUseKey = 'trial_first_use_date';
  static const String _installationIdKey = 'app_installation_id';
  static const int _trialDays = 30;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  Future<String> getOrCreateInstallationId() async {
    final prefs = await _prefs();
    final saved = prefs.getString(_installationIdKey);

    if (saved != null && saved.isNotEmpty) return saved;

    final id = const Uuid().v4();
    await prefs.setString(_installationIdKey, id);
    return id;
  }

  Future<DateTime> _getOrCreateFirstUseDate() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_firstUseKey);

    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return _normalizeDate(parsed);
    }

    final now = _normalizeDate(DateTime.now());
    await prefs.setString(_firstUseKey, now.toIso8601String());
    return now;
  }

  Future<LicenseStatus> getLicenseStatus() async {
    final firstUseDate = await _getOrCreateFirstUseDate();
    final trialEndDate = firstUseDate.add(const Duration(days: _trialDays));
    final today = _normalizeDate(DateTime.now());
    final installationId = await getOrCreateInstallationId();

    final licenseDoc =
        await _firestore.collection('app_licenses').doc(installationId).get();

    if (licenseDoc.exists) {
      final data = licenseDoc.data();
      if (data != null && data['active'] == true) {
        await touchCurrentDeviceAccess();

        return LicenseStatus(
          state: LicenseState.activated,
          firstUseDate: firstUseDate,
          trialEndDate: trialEndDate,
          activationKey: data['activationKey'] as String?,
          activatedPlan: data['plan'] as String?,
          deviceName: data['deviceName'] as String?,
          keyDocId: data['keyDocId'] as String?,
        );
      }
    }

    final expired = today.isAfter(trialEndDate);

    return LicenseStatus(
      state: expired ? LicenseState.trialExpired : LicenseState.trialActive,
      firstUseDate: firstUseDate,
      trialEndDate: trialEndDate,
    );
  }

  Future<bool> activateWithKey({
    required String key,
    required String deviceName,
  }) async {
    final normalizedKey = key.trim().toUpperCase();
    final normalizedDeviceName = deviceName.trim().isEmpty
        ? 'Meu aparelho'
        : deviceName.trim();

    if (normalizedKey.isEmpty) return false;

    final installationId = await getOrCreateInstallationId();
    final installationLicenseRef =
        _firestore.collection('app_licenses').doc(installationId);

    return _firestore.runTransaction((transaction) async {
      final existingInstallationLicense =
          await transaction.get(installationLicenseRef);

      if (existingInstallationLicense.exists) {
        final data = existingInstallationLicense.data();
        if (data != null &&
            data['active'] == true &&
            data['activationKey'] == normalizedKey) {
          transaction.set(
            installationLicenseRef,
            {
              'deviceName': normalizedDeviceName,
              'lastAccessAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return true;
        }
      }

      final keyQuery = await _firestore
          .collection('activation_keys')
          .where('key', isEqualTo: normalizedKey)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (keyQuery.docs.isEmpty) return false;

      final keyDoc = keyQuery.docs.first;
      final keyData = keyDoc.data();
      final keyDocId = keyDoc.id;

      final int maxDevices = (keyData['maxDevices'] as num?)?.toInt() ?? 1;

      final devicesCollection = keyDoc.reference.collection('devices');
      final currentDeviceRef = devicesCollection.doc(installationId);
      final currentDeviceSnap = await transaction.get(currentDeviceRef);

      final activeDevicesQuery =
          await devicesCollection.where('active', isEqualTo: true).get();

      final activeDevicesCount = activeDevicesQuery.docs.length;
      final alreadyAuthorized =
          currentDeviceSnap.exists && (currentDeviceSnap.data()?['active'] == true);

      if (!alreadyAuthorized && activeDevicesCount >= maxDevices) {
        return false;
      }

      transaction.set(
        currentDeviceRef,
        {
          'installationId': installationId,
          'deviceName': normalizedDeviceName,
          'active': true,
          'activatedAt': currentDeviceSnap.exists
              ? (currentDeviceSnap.data()?['activatedAt'] ?? FieldValue.serverTimestamp())
              : FieldValue.serverTimestamp(),
          'lastAccessAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        installationLicenseRef,
        {
          'active': true,
          'activationKey': normalizedKey,
          'keyDocId': keyDocId,
          'plan': keyData['plan'] ?? 'premium',
          'installationId': installationId,
          'deviceName': normalizedDeviceName,
          'activatedAt': FieldValue.serverTimestamp(),
          'lastAccessAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        keyDoc.reference,
        {
          'deviceCount': alreadyAuthorized
              ? activeDevicesCount
              : activeDevicesCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    });
  }

  Future<void> touchCurrentDeviceAccess() async {
    final installationId = await getOrCreateInstallationId();
    final installationRef =
        _firestore.collection('app_licenses').doc(installationId);

    final licenseSnap = await installationRef.get();
    final data = licenseSnap.data();

    if (!licenseSnap.exists || data == null || data['active'] != true) return;

    final keyDocId = data['keyDocId'] as String?;
    if (keyDocId == null || keyDocId.isEmpty) return;

    await installationRef.set(
      {
        'lastAccessAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _firestore
        .collection('activation_keys')
        .doc(keyDocId)
        .collection('devices')
        .doc(installationId)
        .set(
      {
        'lastAccessAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<LicensedDevice>> watchDevicesByKeyDocId(String keyDocId) {
    return _firestore
        .collection('activation_keys')
        .doc(keyDocId)
        .collection('devices')
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LicensedDevice.fromMap(doc.data()))
              .toList()
            ..sort((a, b) {
              final aTime = a.lastAccessAt ?? DateTime(2000);
              final bTime = b.lastAccessAt ?? DateTime(2000);
              return bTime.compareTo(aTime);
            }),
        );
  }

  Future<List<LicensedDevice>> getDevicesByKeyDocId(String keyDocId) async {
    final snapshot = await _firestore
        .collection('activation_keys')
        .doc(keyDocId)
        .collection('devices')
        .where('active', isEqualTo: true)
        .get();

    final list = snapshot.docs
        .map((doc) => LicensedDevice.fromMap(doc.data()))
        .toList();

    list.sort((a, b) {
      final aTime = a.lastAccessAt ?? DateTime(2000);
      final bTime = b.lastAccessAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return list;
  }

  Future<void> removeDevice({
    required String keyDocId,
    required String installationId,
  }) async {
    final keyRef = _firestore.collection('activation_keys').doc(keyDocId);
    final deviceRef = keyRef.collection('devices').doc(installationId);
    final licenseRef = _firestore.collection('app_licenses').doc(installationId);

    await _firestore.runTransaction((transaction) async {
      final deviceSnap = await transaction.get(deviceRef);
      final keySnap = await transaction.get(keyRef);

      if (!keySnap.exists) return;

      final currentCount =
          ((keySnap.data()?['deviceCount'] as num?)?.toInt() ?? 0);

      if (deviceSnap.exists) {
        transaction.set(
          deviceRef,
          {
            'active': false,
            'removedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      transaction.set(
        licenseRef,
        {
          'active': false,
          'removedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        keyRef,
        {
          'deviceCount': currentCount > 0 ? currentCount - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> resetTrialForTesting() async {
    final prefs = await _prefs();
    await prefs.remove(_firstUseKey);
  }

  Future<void> resetInstallationForTesting() async {
    final prefs = await _prefs();
    await prefs.remove(_installationIdKey);
  }
}