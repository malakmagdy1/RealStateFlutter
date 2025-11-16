import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature_web/company/presentation/web_company_detail_screen.dart';
import 'package:real/core/locale/locale_cubit.dart';

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

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
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

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFFE6E6E6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _elevationAnimation.value * 2,
            offset: Offset(0, _elevationAnimation.value),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('[COMPANY CARD] Navigating to company: ${widget.company.id} - ${widget.company.name}');
            try {
              context.push('/company/${widget.company.id}', extra: widget.company.toJson());
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
                    if (widget.company.logo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 550,
                          color: Color(0xFFF8F9FA),
                          padding: EdgeInsets.all(6),
                          child: RobustNetworkImage(
                            imageUrl: widget.company.logo!,
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
                        widget.company.name,
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
                        widget.company.numberOfCompounds,
                        l10n.compounds,
                      ),
                    ),
                    SizedBox(width: 16),
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
          ),
        ),
      ),
            ),
          );
        },
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
          widget.company.name[0].toUpperCase(),
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
