import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    AppLogger.d('Analytics: Logged login method: $method');
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    AppLogger.d('Analytics: Logged sign up method: $method');
  }

  Future<void> logSubscriptionView() async {
    await _analytics.logEvent(name: 'subscription_view');
    AppLogger.d('Analytics: Logged subscription view');
  }

  Future<void> logPlanSelected(String planId) async {
    await _analytics.logEvent(
      name: 'plan_selected',
      parameters: {'plan_id': planId},
    );
    AppLogger.d('Analytics: Logged plan selected: $planId');
  }

  Future<void> logInitiateCheckout(String planId) async {
    await _analytics.logBeginCheckout(
      value: _getPlanValue(planId),
      currency: 'INR',
      items: [
        AnalyticsEventItem(
          itemId: planId,
          itemName: 'Premium Subscription $planId',
          itemCategory: 'Subscription',
        ),
      ],
    );
    AppLogger.d('Analytics: Logged initiate checkout: $planId');
  }

  Future<void> logPurchase(String planId) async {
    await _analytics.logPurchase(
      value: _getPlanValue(planId),
      currency: 'INR',
      items: [
        AnalyticsEventItem(
          itemId: planId,
          itemName: 'Premium Subscription $planId',
          itemCategory: 'Subscription',
        ),
      ],
    );
    AppLogger.d('Analytics: Logged purchase: $planId');
  }

  Future<void> logRestorePurchase() async {
    await _analytics.logEvent(name: 'restore_purchase');
    AppLogger.d('Analytics: Logged restore purchase');
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    AppLogger.d('Analytics: Logged screen view: $screenName');
  }

  double? _getPlanValue(String planId) {
    switch (planId) {
      case 'monthly': return 199.0;
      case 'quarterly': return 499.0;
      case 'yearly': return 1499.0;
      default: return null;
    }
  }
}
