import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:upsc_ca_ui/core/constants/iap_constants.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Callback to update global premium state
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onError;
  Function(bool)? onLoadingChanged;

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (Object error) {
        AppLogger.e("Billing Stream Error", error);
      },
    );
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      AppLogger.e("Store not available");
      return [];
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails(IapConstants.productIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      AppLogger.w("Products not found: ${response.notFoundIDs}");
    }

    return response.productDetails;
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // For subscriptions, use buyNonConsumable
    // Assuming all our products are subscriptions
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      AppLogger.d("Billing: Purchase Update Received: ${purchaseDetails.productID} | Status: ${purchaseDetails.status}");
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        onLoadingChanged?.call(true);
      } else {
        onLoadingChanged?.call(false);
        
        if (purchaseDetails.status == PurchaseStatus.error) {
          AppLogger.e("Billing: Purchase Error: ${purchaseDetails.error}");
          onError?.call(purchaseDetails.error?.message ?? "Purchase failed");
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          AppLogger.d("Billing: Processing ${purchaseDetails.status.name} for ${purchaseDetails.productID}");
          
          // Grant user premium access
          await onPurchaseSuccess?.call(purchaseDetails);
          
          // Always complete purchase
          if (purchaseDetails.pendingCompletePurchase) {
            AppLogger.d("Billing: Completing purchase for ${purchaseDetails.productID}");
            await _iap.completePurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          AppLogger.d("Billing: Purchase cancelled by user");
        }
      }
    }
  }
}
