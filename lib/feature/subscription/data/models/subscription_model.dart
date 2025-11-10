import 'subscription_plan_model.dart';

class SubscriptionModel {
  final int id;
  final int? userId;
  final int? subscriptionPlanId;
  final String? billingCycle; // 'monthly' or 'annual'
  final DateTime startDate;
  final DateTime? endDate; // Nullable for unlimited plans
  final bool autoRenew;
  final String status; // 'active', 'cancelled', 'expired'
  final int searchesUsed;
  final int remainingSearches;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SubscriptionPlanModel? plan;

  SubscriptionModel({
    required this.id,
    this.userId,
    this.subscriptionPlanId,
    this.billingCycle,
    required this.startDate,
    this.endDate,
    this.autoRenew = false,
    required this.status,
    this.searchesUsed = 0,
    this.remainingSearches = -1,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.plan,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats
    final startDateStr = json['started_at'] ?? json['start_date'];
    final endDateStr = json['expires_at'] ?? json['end_date'];

    return SubscriptionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      subscriptionPlanId: json['subscription_plan_id'] as int?,
      billingCycle: json['billing_cycle'] as String?,
      startDate: startDateStr != null
          ? DateTime.parse(startDateStr as String)
          : DateTime.now(),
      endDate: endDateStr != null
          ? DateTime.parse(endDateStr as String)
          : null, // Null for unlimited plans
      autoRenew: json['auto_renew'] == 1 || json['auto_renew'] == true,
      status: json['status'] as String? ?? 'active',
      searchesUsed: json['searches_used'] as int? ?? 0,
      remainingSearches: json['remaining_searches'] as int? ?? -1,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      plan: json['plan'] != null
          ? SubscriptionPlanModel.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      if (subscriptionPlanId != null) 'subscription_plan_id': subscriptionPlanId,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      'started_at': startDate.toIso8601String(),
      'expires_at': endDate?.toIso8601String(),
      'auto_renew': autoRenew,
      'status': status,
      'searches_used': searchesUsed,
      'remaining_searches': remainingSearches,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (plan != null) 'plan': plan!.toJson(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  bool get isUnlimited => remainingSearches == -1 || plan?.isUnlimited == true;

  int get searchesRemaining {
    if (remainingSearches == -1) return -1; // Unlimited
    return remainingSearches;
  }

  bool get hasSearchesLeft {
    if (remainingSearches == -1) return true; // Unlimited
    return remainingSearches > 0;
  }
}
