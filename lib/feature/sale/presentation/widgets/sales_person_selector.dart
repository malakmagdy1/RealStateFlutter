import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/l10n/app_localizations.dart';

class SalesPersonSelector {
  static void show(
    BuildContext context, {
    required List<SalesPerson> salesPersons,
  }) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText20(
                      l10n.selectSalesPerson,
                      bold: true,
                      color: AppColors.black,
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Sales persons list
              Expanded(
                child: salesPersons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 64,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            CustomText18(
                              l10n.noSalesPersonAvailable,
                              color: AppColors.grey,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: salesPersons.length,
                        itemBuilder: (context, index) {
                          final salesPerson = salesPersons[index];
                          return _buildSalesPersonCard(context, salesPerson, l10n);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildSalesPersonCard(
    BuildContext context,
    SalesPerson salesPerson,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.mainColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.mainColor.withOpacity(0.15),
                  AppColors.mainColor.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.mainColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: salesPerson.image != null && salesPerson.image!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      salesPerson.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: CustomText20(
                            salesPerson.name.isNotEmpty
                                ? salesPerson.name[0].toUpperCase()
                                : 'S',
                            bold: true,
                            color: AppColors.mainColor,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: CustomText20(
                      salesPerson.name.isNotEmpty
                          ? salesPerson.name[0].toUpperCase()
                          : 'S',
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Sales Person Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText18(
                  salesPerson.name,
                  bold: true,
                  color: AppColors.black,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomText16(
                        salesPerson.email,
                        color: AppColors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 6),
                    CustomText16(
                      salesPerson.phone,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call Actions
          Column(
            children: [
              // Call button
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  onPressed: () async {
                    final Uri phoneUri = Uri(
                      scheme: 'tel',
                      path: salesPerson.phone,
                    );
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: CustomText16(
                              l10n.calling2(salesPerson.name),
                              color: AppColors.white,
                            ),
                            backgroundColor: AppColors.mainColor,
                          ),
                        );
                      }
                    }
                  },
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 8),
              // WhatsApp button (optional)
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.message,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  onPressed: () async {
                    // WhatsApp link
                    final Uri whatsappUri = Uri.parse(
                      'https://wa.me/${salesPerson.phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                    );
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
