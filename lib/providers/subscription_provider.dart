import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/data/services/subscription_service.dart';
import 'package:upsc_ca_ui/data/services/billing_service.dart';
import 'package:upsc_ca_ui/core/services/analytics_service.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/core/constants/iap_constants.dart';

class SubscriptionProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final BillingService _billingService = BillingService();

  ProfileData? _profile;
  AccessLevel _accessLevel = AccessLevel.limited;
  bool _isLoading = false;
  List<ProductDetails> _products = [];
  String? _errorMessage;

  ProfileData? get profile => _profile;
  AccessLevel get accessLevel => _accessLevel;
  bool get isLoading => _isLoading;
  bool get isPremium => _accessLevel == AccessLevel.full;
  List<ProductDetails> get products => _products;
  String? get errorMessage => _errorMessage;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  SubscriptionProvider() {
    _init();
    _setupBillingListeners();
  }

  void _setupBillingListeners() {
    _billingService.onPurchaseSuccess = _handlePurchaseSuccess;
    _billingService.onError = (msg) {
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
    };
    _billingService.onLoadingChanged = (loading) {
      _isLoading = loading;
      notifyListeners();
    };
  }

  Future<void> _init() async {
    await refreshStatus();
    await fetchProducts();
    // Silently restore purchases on startup to check current status
    await restorePurchases(silent: true);
  }

  Future<void> fetchProducts() async {
    try {
      _products = await _billingService.fetchProducts();
      notifyListeners();
    } catch (e) {
      AppLogger.e("Error fetching products", e);
    }
  }

  Future<void> refreshStatus({bool forceCloud = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile(forceCloudFetch: forceCloud);
      _accessLevel = _subscriptionService.checkAccess(_profile);
      AppLogger.d("Subscription Status: $_accessLevel | Premium: $isPremium | TrialEnd: ${_profile?.trialEndDate}");

      // Notify early if level changed to limited to trigger locking UI ASAP
      if (_accessLevel == AccessLevel.limited) {
        notifyListeners();
      }

      // 🟢 FRESHNESS CHECK: If trial expired and we haven't validated recently
      if (_accessLevel == AccessLevel.limited && _shouldCheckFreshness(_profile)) {
        await validateWithGooglePlay(); // Await this during forced refresh
      }
    } catch (e) {
      AppLogger.e("Error refreshing subscription status", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _shouldCheckFreshness(ProfileData? profile) {
    if (profile == null) return false;
    final now = DateTime.now();
    
    // 1. Check if trial is expired
    final isTrialExpired = profile.trialEndDate != null && profile.trialEndDate!.isBefore(now);
    
    // 2. Check if we already have an active subscription (no need to check freshness if we already know it's active)
    final hasActiveSub = profile.subscriptionEndDate != null && profile.subscriptionEndDate!.isAfter(now);
    
    if (!isTrialExpired || hasActiveSub) return false;
    
    // 3. Throttle: Don't check more than once every 24 hours to stay within API limits and avoid battery drain
    final lastCheck = profile.lastValidationAt ?? DateTime(2000);
    return now.difference(lastCheck).inHours >= 24;
  }

  Future<void> validateWithGooglePlay() async {
    AppLogger.d("Background: Validating subscription freshness with Google Play...");
    try {
      // restorePurchases() triggers queryPurchasesAsync logic internally in the IAP package
      // which fetches latest receipts from Google Servers.
      await restorePurchases(silent: true);
      
      // Update validation timestamp to throttle next check
      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(lastValidationAt: DateTime.now());
        await _profileService.saveProfile(updatedProfile);
        _profile = updatedProfile;
        notifyListeners(); // 🟢 Ensure UI updates with new validation timestamp
      }
    } catch (e) {
      AppLogger.e("Freshness validation failed", e);
    }
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    final isRestored = purchaseDetails.status == PurchaseStatus.restored;
    AppLogger.d("Handling ${isRestored ? 'restored' : 'new'} purchase: ${purchaseDetails.productID}");
    
    final now = DateTime.now();
    
    String planId = 'monthly';
    if (purchaseDetails.productID == IapConstants.quarterlyPremium) planId = 'quarterly';
    if (purchaseDetails.productID == IapConstants.annualPremium) planId = 'yearly';

    // If it's a restoration, and we already have a valid end date in the future, 
    // we don't necessarily want to overwrite it with "now + 1 month" unless 
    // we are sure it's a fresh restoration of an active sub.
    // For simplicity in this offline-first model, we'll only update if:
    // 1. It's a new purchase
    // 2. It's a restoration AND (current sub is expired OR plan changed)
    
    bool shouldUpdate = !isRestored;
    if (isRestored) {
      final currentEnd = _profile?.subscriptionEndDate;
      if (currentEnd == null || currentEnd.isBefore(now) || _profile?.subscriptionPlan != planId) {
        shouldUpdate = true;
      }
    }

    if (shouldUpdate && _profile != null) {
      final endDate = _calculateEndDate(now, planId);
      final updatedProfile = _profile!.copyWith(
        isPremium: true,
        subscriptionPlan: planId,
        subscriptionStartDate: isRestored ? (_profile?.subscriptionStartDate ?? now) : now,
        subscriptionEndDate: endDate,
        purchasePlatform: 'google_play',
        lastValidationAt: now,
      );

      await _profileService.saveProfile(updatedProfile);
      unawaited(AnalyticsService().logPurchase(planId));
      await refreshStatus();
    } else {
      AppLogger.d("Skipping profile update for restoration as current access is still valid or plan matches.");
    }
  }

  /// Accurate end date calculation based on plan type
  DateTime _calculateEndDate(DateTime start, String planId) {
    switch (planId) {
      case 'monthly':
        return DateTime(start.year, start.month + 1, start.day);
      case 'quarterly':
        return DateTime(start.year, start.month + 3, start.day);
      case 'yearly':
        return DateTime(start.year + 1, start.month, start.day);
      default:
        return start.add(const Duration(days: 30));
    }
  }

  Future<void> purchasePlan(String planId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final productId = _mapPlanIdToProductId(planId);
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception("Product not found"),
    );

    try {
      await _billingService.buyProduct(product);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapPlanIdToProductId(String planId) {
    switch (planId) {
      case 'monthly': return IapConstants.monthlyPremium;
      case 'quarterly': return IapConstants.quarterlyPremium;
      case 'yearly': return IapConstants.annualPremium;
      default: return IapConstants.monthlyPremium;
    }
  }

  Future<void> restorePurchases({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      await _billingService.restorePurchases();
    } catch (e) {
      if (!silent) {
        _errorMessage = e.toString();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
