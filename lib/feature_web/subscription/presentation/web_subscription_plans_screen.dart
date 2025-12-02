import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature/subscription/data/models/subscription_plan_model.dart';

class WebSubscriptionPlansScreen extends StatefulWidget {
  static String routeName = '/web-subscription-plans';

  const WebSubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<WebSubscriptionPlansScreen> createState() =>
      _WebSubscriptionPlansScreenState();
}

class _WebSubscriptionPlansScreenState
    extends State<WebSubscriptionPlansScreen> {
  String _selectedBillingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(LoadPlansEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Choose Your Plan'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscribeSuccess) {
            MessageHelper.showSuccess(context, state.message);
            context.pop(true);
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
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                child: Column(
                  children: [
                    // Header
                    Text(
                      'Choose the Perfect Plan for You',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Unlock unlimited access to premium properties',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48),

                    // Billing cycle toggle
                    Center(
                      child: Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
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
                    ),
                    SizedBox(height: 48),

                    // Plans grid
                    Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 1200),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children:
                              state.plans.map((plan) => _buildPlanCard(plan)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

          return Center(child: CircularProgressIndicator());
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
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isRecommended ? AppColors.mainColor : Colors.grey[300]!,
          width: isRecommended ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with badge
          if (isRecommended || plan.badgeEn != null)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Text(
                  plan.badgeEn?.toUpperCase() ?? '⭐ MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name
                Text(
                  plan.nameEn,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),

                // Description
                if (plan.descriptionEn != null)
                  Text(
                    plan.descriptionEn!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                SizedBox(height: 24),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EGP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      price.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                    SizedBox(width: 8),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        '/ ${_selectedBillingCycle == 'monthly' ? 'mo' : 'yr'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Searches info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: AppColors.mainColor, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plan.isUnlimited
                              ? 'Unlimited searches'
                              : '${plan.searchesAllowed} searches/month',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Features
                if (plan.features.isNotEmpty)
                  ...plan.features.where((f) => f.isIncluded == 1).map((feature) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${feature.featureEn}${feature.valueEn != null ? ': ${feature.valueEn}' : ''}',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                SizedBox(height: 32),

                // Subscribe button
                ElevatedButton(
                  onPressed: plan.isFreeModel
                      ? null
                      : () => _subscribeToPlan(plan.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRecommended ? AppColors.mainColor : Colors.black87,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    plan.isFreeModel ? 'Current Plan' : 'Get Started',
                    style: TextStyle(
                      fontSize: 17,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Subscription'),
        content: Container(
          width: 400,
          child: Text(
            'Are you sure you want to subscribe to this plan?\n\n'
            'Billing Cycle: ${_selectedBillingCycle == 'monthly' ? 'Monthly' : 'Annual'}\n'
            'Auto-renew: Yes',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
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
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Confirm', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
