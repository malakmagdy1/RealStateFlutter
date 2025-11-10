import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

// Load all subscription plans
class LoadPlansEvent extends SubscriptionEvent {}

// Load single plan by ID
class LoadPlanEvent extends SubscriptionEvent {
  final int planId;

  const LoadPlanEvent(this.planId);

  @override
  List<Object?> get props => [planId];
}

// Load current active subscription
class LoadCurrentSubscriptionEvent extends SubscriptionEvent {}

// Load subscription status
class LoadSubscriptionStatusEvent extends SubscriptionEvent {}

// Subscribe to a plan
class SubscribeEvent extends SubscriptionEvent {
  final int subscriptionPlanId;
  final String billingCycle; // 'monthly' or 'annual'
  final bool autoRenew;

  const SubscribeEvent({
    required this.subscriptionPlanId,
    required this.billingCycle,
    this.autoRenew = true,
  });

  @override
  List<Object?> get props => [subscriptionPlanId, billingCycle, autoRenew];
}

// Cancel subscription
class CancelSubscriptionEvent extends SubscriptionEvent {
  final String? reason;

  const CancelSubscriptionEvent({this.reason});

  @override
  List<Object?> get props => [reason];
}

// Load subscription history
class LoadSubscriptionHistoryEvent extends SubscriptionEvent {}

// Assign free plan
class AssignFreePlanEvent extends SubscriptionEvent {}
