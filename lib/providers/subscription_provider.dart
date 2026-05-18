import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/data/services/subscription_service.dart';
import 'package:upsc_ca_ui/data/services/billing_service.dart';
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
    } catch (e) {
      AppLogger.e("Error refreshing subscription status", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    AppLogger.d("Handling successful purchase: ${purchaseDetails.productID}");
    
    final now = DateTime.now();
    // Note: In a real app, you should verify the purchase on your backend.
    // Here we'll update the profile directly as per the guide.
    
    String planId = 'monthly';
    if (purchaseDetails.productID == IapConstants.quarterlyPremium) planId = 'quarterly';
    if (purchaseDetails.productID == IapConstants.annualPremium) planId = 'yearly';

    final endDate = _calculateEndDate(now, planId);

    if (_profile != null) {
      final updatedProfile = _profile!.copyWith(
        isPremium: true,
        subscriptionPlan: planId,
        subscriptionStartDate: now,
        subscriptionEndDate: endDate,
        purchasePlatform: 'google_play',
        lastValidationAt: now,
      );

      await _profileService.saveProfile(updatedProfile);
      await refreshStatus();
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
