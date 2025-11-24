import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature_web/company/presentation/web_company_detail_screen.dart';
import 'package:real/core/locale/locale_cubit.dart';
import 'package:real/feature/ai_chat/data/models/comparison_item.dart';
import 'package:real/feature/ai_chat/data/services/comparison_list_service.dart';
import 'package:real/feature/ai_chat/presentation/widget/comparison_selection_sheet.dart';
import 'package:real/feature_web/widgets/unified_web_card.dart';

class WebCompanyCard extends StatefulWidget {
  final Company company;

  WebCompanyCard({Key? key, required this.company}) : super(key: key);

  @override
  State<WebCompanyCard> createState() => _WebCompanyCardState();
}

class _WebCompanyCardState extends State<WebCompanyCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with BlocBuilder to rebuild when locale changes
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return _buildCard(context);
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return UnifiedWebCard(
      imageUrl: widget.company.logo,
      onTap: () {
        print('[COMPANY CARD] Navigating to company: ${widget.company.id} - ${widget.company.name}');
        try {
          context.push('/company/${widget.company.id}', extra: widget.company.toJson());
        } catch (e) {
          print('[COMPANY CARD] Navigation error: $e');
        }
      },
      placeholder: Container(
        color: AppColors.mainColor.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.business,
            size: 80,
            color: AppColors.mainColor.withOpacity(0.3),
          ),
        ),
      ),
      bottomInfo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Company Name with Logo
          Row(
            children: [
              UnifiedCompanyLogo(logoUrl: widget.company.logo),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.company.name,
                  style: TextStyle(
                    fontSize: UnifiedWebCardConfig.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: UnifiedWebCardConfig.spacing),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  widget.company.numberOfCompounds,
                  l10n.compounds,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStat(
                  widget.company.numberOfAvailableUnits,
                  l10n.units,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return UnifiedDetailChip(
      icon: label == 'Compounds' || label.contains('كمبوند')
          ? Icons.apartment
          : Icons.home_work,
      value: value,
      color: AppColors.mainColor,
    );
  }
}
