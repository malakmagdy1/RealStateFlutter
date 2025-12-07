#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import shutil

target_file = r'C:\Users\B-Smart\AndroidStudioProjects\real\lib\feature\compound\presentation\screen\unit_detail_screen.dart'

# Read the original file (read is allowed)
with open(target_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Define the old section to replace
old_section = '''          // Delivery & Finishing Info
          if (plan.deliveryDate != null || plan.finishingType != null) ...[
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 8),
            Row(
              children: [
                if (plan.deliveryDate != null &&
                    plan.deliveryDate!.isNotEmpty) ...[
                  Icon(Icons.event_available, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Delivery: ${plan.deliveryDate}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  SizedBox(width: 16),
                ],
                if (plan.finishingType != null &&
                    plan.finishingType!.isNotEmpty) ...[
                  Icon(Icons.format_paint, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    plan.finishingType!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ],'''

new_section = '''          // Payment Summary Info (for installment plans)
          if (!isCash && duration != '0') ...[
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 8),
            _buildPaymentSummarySection(plan, l10n),
          ],'''

# New method to add after _hasAdditionalCosts
payment_summary_method = '''
  Widget _buildPaymentSummarySection(PaymentPlan plan, AppLocalizations l10n) {
    final duration = plan.durationYears ?? '0';
    final durationNum = int.tryParse(duration) ?? 0;
    final totalMonths = durationNum * 12;

    // Calculate remaining balance after down payment
    double? remainingBalance;
    if (plan.price != null && plan.downPaymentAmount != null) {
      final totalPrice = double.tryParse(plan.price!.replaceAll(',', '')) ?? 0;
      final downPayment = double.tryParse(plan.downPaymentAmount!.replaceAll(',', '')) ?? 0;
      if (totalPrice > 0 && downPayment > 0) {
        remainingBalance = totalPrice - downPayment;
      }
    }

    // Calculate price per sqm if area is available
    double? pricePerSqm;
    if (plan.price != null && plan.totalArea != null) {
      final totalPrice = double.tryParse(plan.price!.replaceAll(',', '')) ?? 0;
      final totalArea = double.tryParse(plan.totalArea!.replaceAll(',', '')) ?? 0;
      if (totalPrice > 0 && totalArea > 0) {
        pricePerSqm = totalPrice / totalArea;
      }
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Total number of installments
        if (totalMonths > 0)
          _buildSummaryChip(
            Icons.format_list_numbered,
            '$totalMonths ${l10n.months}',
            l10n.totalInstallments,
            Colors.indigo,
          ),
        // Remaining balance after down payment
        if (remainingBalance != null && remainingBalance > 0)
          _buildSummaryChip(
            Icons.account_balance_wallet,
            'EGP ${_formatPrice(remainingBalance.toStringAsFixed(0))}',
            l10n.balanceAfterDown,
            Colors.deepOrange,
          ),
        // Price per sqm
        if (pricePerSqm != null)
          _buildSummaryChip(
            Icons.grid_view,
            'EGP ${_formatPrice(pricePerSqm.toStringAsFixed(0))}',
            l10n.pricePerSqm,
            Colors.teal,
          ),
      ],
    );
  }

  Widget _buildSummaryChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

'''

if old_section in content:
    # Replace the old section
    content = content.replace(old_section, new_section)

    # Find where to insert the new methods (after _hasAdditionalCosts)
    insert_marker = '''  bool _hasAdditionalCosts(PaymentPlan plan) {
    return (plan.maintenanceDeposit != null &&
        plan.maintenanceDeposit!.isNotEmpty) ||
        (plan.clubMembership != null && plan.clubMembership!.isNotEmpty) ||
        (plan.garagePrice != null && plan.garagePrice!.isNotEmpty) ||
        (plan.storagePrice != null && plan.storagePrice!.isNotEmpty);
  }

  Widget _buildPaymentDetailRow'''

    new_insert = '''  bool _hasAdditionalCosts(PaymentPlan plan) {
    return (plan.maintenanceDeposit != null &&
        plan.maintenanceDeposit!.isNotEmpty) ||
        (plan.clubMembership != null && plan.clubMembership!.isNotEmpty) ||
        (plan.garagePrice != null && plan.garagePrice!.isNotEmpty) ||
        (plan.storagePrice != null && plan.storagePrice!.isNotEmpty);
  }
''' + payment_summary_method + '''  Widget _buildPaymentDetailRow'''

    if insert_marker in content:
        content = content.replace(insert_marker, new_insert)
        # Write to a new file
        output_file = r'C:\Users\B-Smart\AndroidStudioProjects\real\unit_detail_screen_updated.dart'
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Successfully created updated file: {output_file}')
        print('To apply changes, run:')
        print(f'copy /Y "{output_file}" "{target_file}"')
    else:
        print('Could not find insert marker for methods')
else:
    print('Could not find the exact match in file')
    if '// Delivery & Finishing Info' in content:
        print('Found partial match - Delivery & Finishing Info comment exists')
    else:
        print('No partial match found')
