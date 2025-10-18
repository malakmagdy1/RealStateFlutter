import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/l10n/app_localizations.dart';

class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SaleCard({
    Key? key,
    required this.sale,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.mainColor.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.mainColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.mainColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Header with Discount Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withOpacity(0.15),
                    Colors.red.withOpacity(0.08),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText18(
                          sale.saleName,
                          bold: true,
                          color: AppColors.black,
                        ),
                        const SizedBox(height: 4),
                        CustomText16(
                          sale.itemName,
                          color: AppColors.grey,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CustomText18(
                          '${sale.discountPercentage.toStringAsFixed(0)}%',
                          bold: true,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        CustomText16(
                          l10n.discount,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sale Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Information
                  Row(
                    children: [
                      // Old Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText16(
                              l10n.oldPrice,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 4),
                            CustomText16(
                              '${sale.oldPrice.toStringAsFixed(0)} ${l10n.egp}',
                              bold: true,
                              color: AppColors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ],
                        ),
                      ),
                      // New Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText16(
                              l10n.newPrice,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 4),
                            CustomText18(
                              '${sale.newPrice.toStringAsFixed(0)} ${l10n.egp}',
                              bold: true,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Savings
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        CustomText16(
                          '${l10n.save} ${sale.savings.toStringAsFixed(0)} ${l10n.egp}',
                          bold: true,
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),

                  // Days Remaining
                  if (sale.daysRemaining > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.orange.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        CustomText16(
                          '${l10n.endsIn} ${sale.daysRemaining.toInt()} ${l10n.days}',
                          color: Colors.orange.shade700,
                          bold: true,
                        ),
                      ],
                    ),
                  ],

                  // Sales Person Info
                  if (sale.salesPerson != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.mainColor,
                            child: CustomText16(
                              sale.salesPerson!.name[0].toUpperCase(),
                              color: AppColors.white,
                              bold: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText16(
                                  sale.salesPerson!.name,
                                  bold: true,
                                  color: AppColors.black,
                                ),
                                CustomText16(
                                  sale.salesPerson!.phone,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.phone,
                              color: AppColors.mainColor,
                            ),
                            onPressed: () {
                              // TODO: Implement call functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
