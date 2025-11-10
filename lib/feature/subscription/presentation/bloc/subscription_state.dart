import 'package:equatable/equatable.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_status_model.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

// Initial state
class SubscriptionInitial extends SubscriptionState {}

// Loading states
class SubscriptionLoading extends SubscriptionState {}

// Plans loaded successfully
class PlansLoaded extends SubscriptionState {
  final List<SubscriptionPlanModel> plans;

  const PlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

// Single plan loaded
class PlanLoaded extends SubscriptionState {
  final SubscriptionPlanModel plan;

  const PlanLoaded(this.plan);

  @override
  List<Object?> get props => [plan];
}

// Current subscription loaded
class CurrentSubscriptionLoaded extends SubscriptionState {
  final SubscriptionModel? subscription;

  const CurrentSubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

// Subscription status loaded
class SubscriptionStatusLoaded extends SubscriptionState {
  final SubscriptionStatusModel status;

  const SubscriptionStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

// Subscribed successfully
class SubscribeSuccess extends SubscriptionState {
  final SubscriptionModel subscription;
  final String message;

  const SubscribeSuccess(this.subscription, this.message);

  @override
  List<Object?> get props => [subscription, message];
}

// Subscription cancelled successfully
class CancelSubscriptionSuccess extends SubscriptionState {
  final String message;

  const CancelSubscriptionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Subscription history loaded
class SubscriptionHistoryLoaded extends SubscriptionState {
  final List<SubscriptionModel> history;

  const SubscriptionHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

// Free plan assigned
class FreePlanAssigned extends SubscriptionState {
  final SubscriptionModel subscription;

  const FreePlanAssigned(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

// Error state
class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
