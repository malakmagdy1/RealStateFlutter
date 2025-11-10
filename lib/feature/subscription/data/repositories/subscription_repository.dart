import '../web_services/subscription_web_services.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_status_model.dart';

class SubscriptionRepository {
  final SubscriptionWebServices _webServices;

  SubscriptionRepository({SubscriptionWebServices? webServices})
      : _webServices = webServices ?? SubscriptionWebServices();

  Future<List<SubscriptionPlanModel>> getAllPlans() async {
    try {
      return await _webServices.getAllPlans();
    } catch (e) {
      print('Repository Get All Plans Error: $e');
      rethrow;
    }
  }

  Future<SubscriptionPlanModel> getPlan(int planId) async {
    try {
      return await _webServices.getPlan(planId);
    } catch (e) {
      print('Repository Get Plan Error: $e');
      rethrow;
    }
  }

  Future<SubscriptionModel?> getCurrentSubscription() async {
    try {
      return await _webServices.getCurrentSubscription();
    } catch (e) {
      print('Repository Get Current Subscription Error: $e');
      rethrow;
    }
  }

  Future<SubscriptionStatusModel> getSubscriptionStatus() async {
    try {
      return await _webServices.getSubscriptionStatus();
    } catch (e) {
      print('Repository Get Subscription Status Error: $e');
      rethrow;
    }
  }

  Future<SubscriptionModel> subscribe({
    required int subscriptionPlanId,
    required String billingCycle,
    bool autoRenew = true,
  }) async {
    try {
      return await _webServices.subscribe(
        subscriptionPlanId: subscriptionPlanId,
        billingCycle: billingCycle,
        autoRenew: autoRenew,
      );
    } catch (e) {
      print('Repository Subscribe Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelSubscription({String? reason}) async {
    try {
      return await _webServices.cancelSubscription(reason: reason);
    } catch (e) {
      print('Repository Cancel Subscription Error: $e');
      rethrow;
    }
  }

  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    try {
      return await _webServices.getSubscriptionHistory();
    } catch (e) {
      print('Repository Get Subscription History Error: $e');
      rethrow;
    }
  }

  Future<SubscriptionModel> assignFreePlan() async {
    try {
      return await _webServices.assignFreePlan();
    } catch (e) {
      print('Repository Assign Free Plan Error: $e');
      rethrow;
    }
  }
}
