import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../feature_web/widgets/web_compound_card.dart';
import 'package:real/core/widget/robust_network_image.dart';

import '../../compound/presentation/web_compound_detail_screen.dart';

class WebCompanyDetailScreen extends StatelessWidget {
  static String routeName = '/web-company-detail';
  final Company company;

  WebCompanyDetailScreen({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.mainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          company.name,
          style: TextStyle(
            color: AppColors.mainColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyHeader(l10n),
                  SizedBox(height: 32),
                  _buildStatsSection(l10n),
                  SizedBox(height: 48),
                  _buildContactInfo(l10n),
                  SizedBox(height: 48),
                  if (company.sales.isNotEmpty) ...[
                    _buildSalespeopleSection(l10n),
                    SizedBox(height: 48),
                  ],
                  if (company.compounds.isNotEmpty) _buildCompoundsSection(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.mainColor.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (company.logo != null)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mainColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: RobustNetworkImage(
                imageUrl: company.logo!,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, url) => Icon(
                  Icons.business,
                  size: 70,
                  color: AppColors.mainColor,
                ),
              ),
            )
          else
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  company.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DEVELOPER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  company.name,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: AppColors.mainColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      company.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.apartment,
            company.numberOfCompounds,
            l10n.compounds ?? 'Compounds',
            AppColors.mainColor,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            Icons.home_outlined,
            company.numberOfAvailableUnits,
            'Available Units',
            Color(0xFF4CAF50),
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            Icons.people_outline,
            company.salesCount.toString(),
            'Sales Team',
            Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, size: 28, color: AppColors.mainColor),
              SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on, color: AppColors.mainColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Head Office',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cairo, Egypt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.email, color: AppColors.mainColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      company.email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalespeopleSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.support_agent, size: 28, color: AppColors.mainColor),
            SizedBox(width: 12),
            Text(
              'Sales Team',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: company.sales.length,
          itemBuilder: (context, index) {
            final sales = company.sales[index];
            return Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.06),
                    blurRadius: 15,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            sales.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sales.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 18, color: AppColors.mainColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sales.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.email, size: 18, color: AppColors.mainColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sales.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompoundsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_city, size: 28, color: AppColors.mainColor),
            SizedBox(width: 12),
            Text(
              'Our Projects',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: company.compounds.length,
          itemBuilder: (context, index) {
            final compoundData = company.compounds[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebCompoundDetailScreen(compoundId: compoundData.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                hoverColor: AppColors.mainColor.withOpacity(0.03),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compoundData.images.isNotEmpty)
                    Stack(
                      children: [
                        RobustNetworkImage(
                          imageUrl: compoundData.images.first,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, url) => Container(
                            height: 140,
                            color: Color(0xFFF8F9FA),
                            child: Center(
                              child: Icon(
                                Icons.apartment,
                                size: 50,
                                color: AppColors.mainColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              compoundData.status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compoundData.project,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppColors.mainColor,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                compoundData.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
