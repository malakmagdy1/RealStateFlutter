import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature_web/company/presentation/web_company_detail_screen.dart';

class WebCompanyCard extends StatelessWidget {
  final Company company;

  WebCompanyCard({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFFE6E6E6),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('[COMPANY CARD] Navigating to company: ${company.id} - ${company.name}');
            try {
              context.push('/company/${company.id}', extra: company.toJson());
            } catch (e) {
              print('[COMPANY CARD] Navigation error: $e');
            }
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.mainColor.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (company.logo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 550,
                          color: Color(0xFFF8F9FA),
                          padding: EdgeInsets.all(6),
                          child: RobustNetworkImage(
                            imageUrl: company.logo!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (context, url) => _buildPlaceholderLogo(),
                          ),
                        ),
                      )
                    else
                      _buildPlaceholderLogo(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        company.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        company.numberOfCompounds,
                        'Compounds',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStat(
                        company.numberOfAvailableUnits,
                        'Units',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.mainColor,
      ),
      child: Center(
        child: Text(
          company.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.mainColor,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
