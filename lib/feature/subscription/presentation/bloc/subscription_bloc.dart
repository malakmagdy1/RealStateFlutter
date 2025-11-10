import 'package:flutter_bloc/flutter_bloc.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';
import '../../data/repositories/subscription_repository.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<LoadPlansEvent>(_onLoadPlans);
    on<LoadPlanEvent>(_onLoadPlan);
    on<LoadCurrentSubscriptionEvent>(_onLoadCurrentSubscription);
    on<LoadSubscriptionStatusEvent>(_onLoadSubscriptionStatus);
    on<SubscribeEvent>(_onSubscribe);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<LoadSubscriptionHistoryEvent>(_onLoadSubscriptionHistory);
    on<AssignFreePlanEvent>(_onAssignFreePlan);
  }

  Future<void> _onLoadPlans(
    LoadPlansEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final plans = await repository.getAllPlans();
      emit(PlansLoaded(plans));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onLoadPlan(
    LoadPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final plan = await repository.getPlan(event.planId);
      emit(PlanLoaded(plan));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onLoadCurrentSubscription(
    LoadCurrentSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await repository.getCurrentSubscription();
      emit(CurrentSubscriptionLoaded(subscription));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionStatus(
    LoadSubscriptionStatusEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final status = await repository.getSubscriptionStatus();
      emit(SubscriptionStatusLoaded(status));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onSubscribe(
    SubscribeEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await repository.subscribe(
        subscriptionPlanId: event.subscriptionPlanId,
        billingCycle: event.billingCycle,
        autoRenew: event.autoRenew,
      );
      emit(SubscribeSuccess(subscription, 'Successfully subscribed!'));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final response = await repository.cancelSubscription(reason: event.reason);
      emit(CancelSubscriptionSuccess(
        response['message'] ?? 'Subscription cancelled successfully',
      ));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionHistory(
    LoadSubscriptionHistoryEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final history = await repository.getSubscriptionHistory();
      emit(SubscriptionHistoryLoaded(history));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onAssignFreePlan(
    AssignFreePlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await repository.assignFreePlan();
      emit(FreePlanAssigned(subscription));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
