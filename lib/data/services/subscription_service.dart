import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';

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
    if (profile == null) {
      AppLogger.d("AccessCheck: NULL Profile -> Access: LIMITED");
      return AccessLevel.limited;
    }

    final now = DateTime.now();

    // Debug logging
    AppLogger.d("AccessCheck: ${profile.name} | TrialEnd: ${profile.trialEndDate} | SubEnd: ${profile.subscriptionEndDate} | isPremium: ${profile.isPremium} | manualPremium: ${profile.manualPremium}");

    // 1. Check manualPremium (Overwrites everything)
    if (profile.manualPremium) {
      AppLogger.d("Access: FULL (manualPremium)");
      return AccessLevel.full;
    }

    // 2. Check active paid subscription
    if (profile.isPremium && profile.subscriptionEndDate != null && profile.subscriptionEndDate!.isAfter(now)) {
      AppLogger.d("Access: FULL (Active Subscription)");
      return AccessLevel.full;
    }

    // 3. Check free trial validity (90 days)
    if (profile.trialEndDate != null && profile.trialEndDate!.isAfter(now)) {
      AppLogger.d("Access: FULL (Active Trial)");
      return AccessLevel.full;
    }

    // 4. Default: Lock content
    AppLogger.d("Access: LIMITED (Expired or No Access). Current Time: $now");
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
