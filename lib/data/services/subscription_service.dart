import 'package:upsc_ca_ui/shared/models/profile_data.dart';

enum AccessLevel { full, limited }

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Validates access based on priority:
  /// 1. manualPremium (Highest)
  /// 2. Active Paid Subscription
  /// 3. Free Trial Validity
  AccessLevel checkAccess(ProfileData? profile) {
    if (profile == null) return AccessLevel.limited;

    final now = DateTime.now();

    // 1. Check manualPremium (Overwrites everything)
    if (profile.manualPremium) {
      return AccessLevel.full;
    }

    // 2. Check active paid subscription
    if (profile.subscriptionEndDate != null && profile.subscriptionEndDate!.isAfter(now)) {
      return AccessLevel.full;
    }

    // 3. Check free trial validity (90 days)
    if (profile.trialEndDate != null && profile.trialEndDate!.isAfter(now)) {
      return AccessLevel.full;
    }

    // 4. Default: Lock content
    return AccessLevel.limited;
  }

  /// Calculates remaining trial days
  int getTrialDaysLeft(ProfileData? profile) {
    if (profile?.trialEndDate == null) return 0;
    final remaining = profile!.trialEndDate!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// Determines if a specific item should be free (e.g., first 2 articles of the day)
  bool isItemFree(String type, int index) {
    if (type == 'article' && index < 2) return true;
    return false;
  }
}
