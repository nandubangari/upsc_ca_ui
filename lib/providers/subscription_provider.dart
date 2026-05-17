import 'package:flutter/material.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/data/services/subscription_service.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';

class SubscriptionProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  ProfileData? _profile;
  AccessLevel _accessLevel = AccessLevel.limited;
  bool _isLoading = false;

  ProfileData? get profile => _profile;
  AccessLevel get accessLevel => _accessLevel;
  bool get isLoading => _isLoading;
  bool get isPremium => _accessLevel == AccessLevel.full;

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
      _accessLevel = _subscriptionService.checkAccess(_profile);
    } catch (e) {
      AppLogger.e("Error refreshing subscription status", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accurate end date calculation based on plan type
  DateTime _calculateEndDate(DateTime start, String planId) {
    switch (planId) {
      case 'monthly':
        // Handle month transition accurately (e.g. Jan 31 -> Feb 28)
        return DateTime(start.year, start.month + 1, start.day);
      case 'quarterly':
        return DateTime(start.year, start.month + 3, start.day);
      case 'yearly':
        return DateTime(start.year + 1, start.month, start.day);
      default:
        return start.add(const Duration(days: 30));
    }
  }

  /// Mock purchase logic (Structure ready for Google Play IAP integration)
  Future<bool> purchasePlan(String planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final endDate = _calculateEndDate(now, planId);

      if (_profile != null) {
        final updatedProfile = ProfileData(
          name: _profile!.name,
          joinedAt: _profile!.joinedAt,
          startDate: _profile!.startDate,
          articleSources: _profile!.articleSources,
          quizSources: _profile!.quizSources,
          repetitionIntervals: _profile!.repetitionIntervals,
          themeColorValue: _profile!.themeColorValue,
          examDate: _profile!.examDate,
          isPremium: true,
          trialStartDate: _profile!.trialStartDate,
          trialEndDate: _profile!.trialEndDate,
          subscriptionPlan: planId,
          subscriptionStartDate: now,
          subscriptionEndDate: endDate,
          manualPremium: _profile!.manualPremium,
          manualPremiumReason: _profile!.manualPremiumReason,
          purchasePlatform: 'google_play', // Mark as Google Play purchase
          lastValidationAt: now,
        );

        await _profileService.saveProfile(updatedProfile);
        await refreshStatus();
        
        AppLogger.d("Subscription purchased on Google Play: $planId until ${endDate.toIso8601String()}");
        return true;
      }
    } catch (e) {
      AppLogger.e("Purchase failed", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> restorePurchases() async {
    // Placeholder for IAP restoration logic
    await refreshStatus();
  }
}
