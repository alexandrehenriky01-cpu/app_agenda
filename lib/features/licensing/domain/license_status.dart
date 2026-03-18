enum LicenseState {
  trialActive,
  trialExpired,
  activated,
}

class LicenseStatus {
  final LicenseState state;
  final DateTime? firstUseDate;
  final DateTime? trialEndDate;
  final String? activationKey;
  final String? activatedPlan;
  final String? deviceName;
  final String? keyDocId;

  const LicenseStatus({
    required this.state,
    this.firstUseDate,
    this.trialEndDate,
    this.activationKey,
    this.activatedPlan,
    this.deviceName,
    this.keyDocId,
  });

  bool get isActive =>
      state == LicenseState.trialActive || state == LicenseState.activated;

  bool get isTrial => state == LicenseState.trialActive;
  bool get isActivated => state == LicenseState.activated;
  bool get isExpired => state == LicenseState.trialExpired;

  int get remainingTrialDays {
    if (trialEndDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      trialEndDate!.year,
      trialEndDate!.month,
      trialEndDate!.day,
    );

    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }
}