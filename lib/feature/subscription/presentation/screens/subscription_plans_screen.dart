import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';
import '../../data/models/subscription_plan_model.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  static String routeName = '/subscription-plans';

  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String _selectedBillingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(LoadPlansEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Your Plan'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscribeSuccess) {
            MessageHelper.showSuccess(context, state.message);
            Navigator.pop(context, true);
          } else if (state is SubscriptionError) {
            MessageHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is PlansLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Billing cycle toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildBillingToggle('Monthly', 'monthly'),
                        ),
                        Expanded(
                          child: _buildBillingToggle('Annual', 'annual'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Plan cards
                  ...state.plans.map((plan) => _buildPlanCard(plan)),
                ],
              ),
            );
          }

          if (state is SubscriptionError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load plans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<SubscriptionBloc>().add(LoadPlansEvent());
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initial state - trigger loading
          if (state is SubscriptionInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<SubscriptionBloc>().add(LoadPlansEvent());
            });
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildBillingToggle(String label, String value) {
    final isSelected = _selectedBillingCycle == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBillingCycle = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan) {
    final price = _selectedBillingCycle == 'monthly'
        ? plan.monthlyPrice
        : plan.annualPrice;
    final isRecommended = plan.isFeatured;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? AppColors.mainColor : Colors.grey[300]!,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with badge
          if (isRecommended || plan.badgeEn != null)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  plan.badgeEn?.toUpperCase() ?? 'RECOMMENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name
                Text(
                  plan.nameEn,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                // Description
                if (plan.descriptionEn != null)
                  Text(
                    plan.descriptionEn!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                SizedBox(height: 16),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EGP ${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                    SizedBox(width: 8),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ ${_selectedBillingCycle == 'monthly' ? 'month' : 'year'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Searches info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        plan.isUnlimited
                            ? 'Unlimited searches'
                            : '${plan.searchesAllowed} searches per month',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Features
                if (plan.features.isNotEmpty)
                  ...plan.features.where((f) => f.isIncluded == 1).map((feature) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${feature.featureEn}${feature.valueEn != null ? ': ${feature.valueEn}' : ''}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                SizedBox(height: 16),

                // Subscribe button
                ElevatedButton(
                  onPressed: plan.isFreeModel
                      ? null
                      : () => _subscribeToPlan(plan.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    plan.isFreeModel ? 'Current Plan' : 'Subscribe Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _subscribeToPlan(int planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Subscription'),
        content: Text(
          'Are you sure you want to subscribe to this plan?\n\n'
          'Billing Cycle: ${_selectedBillingCycle == 'monthly' ? 'Monthly' : 'Annual'}\n'
          'Auto-renew: Yes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SubscriptionBloc>().add(
                    SubscribeEvent(
                      subscriptionPlanId: planId,
                      billingCycle: _selectedBillingCycle,
                      autoRenew: true,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
