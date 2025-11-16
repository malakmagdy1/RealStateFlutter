import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/widget/robust_network_image.dart';
import '../../data/models/unit_model.dart';
import '../screen/unit_detail_screen.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/core/widgets/note_dialog.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/core/animations/pulse_animation.dart';
import 'package:real/core/locale/language_service.dart';

class UnitCard extends StatefulWidget {
  final Unit unit;

  UnitCard({Key? key, required this.unit}) : super(key: key);

  @override
  State<UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<UnitCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  String? _currentNote;
  bool _animateFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.unit.notes;
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(UnitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unit.notes != oldWidget.unit.notes ||
        widget.unit.noteId != oldWidget.unit.noteId) {
      setState(() {
        _currentNote = widget.unit.notes;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitImages = widget.unit.images ?? [];
    final bool hasImages = unitImages.isNotEmpty;

    final compoundLocation = widget.unit.compoundLocation?.isNotEmpty == true
        ? widget.unit.compoundLocation!
        : 'N/A';

    final unitType = widget.unit.usageType ?? widget.unit.unitType ?? 'Unit';
    final unitNumber = widget.unit.unitNumber ?? '';
    String unitName = unitNumber.isNotEmpty ? unitNumber : 'Unit';

    // Hide sold units completely
    if (widget.unit.status?.toLowerCase() == 'sold') {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: AspectRatio(
          aspectRatio: 0.72, // Width to height ratio for card (reduced from 0.85 to make it smaller/taller)
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.unit.status?.toLowerCase() == 'sold') {
                  MessageHelper.showError(context, 'This unit is no longer available');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnitDetailScreen(unit: widget.unit),
                  ),
                );
              },
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              borderRadius: BorderRadius.circular(24),
              hoverColor: AppColors.mainColor.withOpacity(0.03),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Background Image - fills entire container
                    Positioned.fill(
                      child: hasImages
                          ? RobustNetworkImage(
                              imageUrl: unitImages.first,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, url) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),

                    // Top Row: Action Buttons (Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Action Buttons Row
                          Row(
                            children: [
                              // Favorite Button
                              BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                                builder: (context, state) {
                                  bool isFavorite = false;
                                  if (state is UnitFavoriteUpdated) {
                                    isFavorite = state.favorites.any((u) => u.id == widget.unit.id);
                                  }
                                  return PulseAnimation(
                                    animate: _animateFavorite,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isFavorite) {
                                          context.read<UnitFavoriteBloc>().add(
                                            RemoveFavoriteUnit(widget.unit),
                                          );
                                        } else {
                                          context.read<UnitFavoriteBloc>().add(
                                            AddFavoriteUnit(widget.unit),
                                          );
                                        }

                                        setState(() {
                                          _animateFavorite = true;
                                        });
                                        Future.delayed(Duration(milliseconds: 600), () {
                                          if (mounted) {
                                            setState(() {
                                              _animateFavorite = false;
                                            });
                                          }
                                        });
                                      },
                                      child: Container(
                                        height: 28,
                                        width: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          size: 14,
                                          color: isFavorite ? Colors.red : Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 4),
                              // Note Button
                              GestureDetector(
                                onTap: () => _showNoteDialog(context),
                                child: Container(
                                  height: 28,
                                  width: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _currentNote != null && _currentNote!.isNotEmpty
                                        ? AppColors.mainColor.withOpacity(0.9)
                                        : Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _currentNote != null && _currentNote!.isNotEmpty
                                        ? Icons.note
                                        : Icons.note_add_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sale badge (higher priority, shown at top)
                    if (widget.unit.sale != null && widget.unit.sale!.isCurrentlyActive)
                      Positioned(
                        top: 8,
                        right: -35,
                        child: Transform.rotate(
                          angle: 0.785398, // 45 degrees
                          child: _saleBadge(widget.unit.sale!),
                        ),
                      ),

                    // Update badge (shown below sale badge if both exist)
                    if (widget.unit.isUpdated == true && widget.unit.changeType != null)
                      Positioned(
                        top: widget.unit.sale != null && widget.unit.sale!.isCurrentlyActive ? 48 : 8,
                        right: -35,
                        child: Transform.rotate(
                          angle: 0.785398, // 45 degrees
                          child: _updateBadge(widget.unit.changeType!),
                        ),
                      ),

                    // Semi-transparent Info Area at bottom
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unit Name/Number with Company Logo
                          Row(
                            children: [
                              if (widget.unit.companyLogo != null && widget.unit.companyLogo!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundImage: NetworkImage(widget.unit.companyLogo!),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  unitName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),

                          // Unit Type (Villa, Apartment, etc.)
                          Text(
                            unitType,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),

                          // Compound Name
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 11, color: Colors.grey[600]),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  compoundLocation.isNotEmpty ? compoundLocation : 'N/A',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 3),

                          // Property Details Row 1
                          Row(
                            children: [
                              _detailChip(Icons.home_work, widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0' ? '${widget.unit.bedrooms} Bed' : 'N/A'),
                              SizedBox(width: 2),
                              _detailChip(Icons.bathtub_outlined, widget.unit.bathrooms.isNotEmpty && widget.unit.bathrooms != '0' ? widget.unit.bathrooms : 'N/A'),
                              SizedBox(width: 2),
                            ],
                          ),

                          SizedBox(height: 2),
                          Row(
                            children: [
                              _detailChip(Icons.square_foot, widget.unit.area.isNotEmpty && widget.unit.area != '0' ? '${widget.unit.area}m²' : 'N/A'),
                              SizedBox(width: 2),
                              widget.unit.status.toLowerCase().contains('progress')
                                  ? _detailChip(Icons.pending, 'Progress', color: Colors.orange)
                                  : widget.unit.status.toLowerCase() == 'available'
                                      ? _detailChip(Icons.check_circle, 'Available', color: Colors.green)
                                      : _detailChip(Icons.info_outline, widget.unit.status),
                            ],
                          ),

                          SizedBox(height: 3),
                          // Delivery Date Row
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 11, color: Colors.grey[600]),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty
                                      ? widget.unit.deliveryDate!
                                      : 'N/A',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 3),
                          // Price and Phone Button Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'EGP ${_formatPrice(_getBestPrice())}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Phone Button
                              GestureDetector(
                                onTap: () => _showSalespeople(context),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.mainColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.mainColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ), // Stack closing
              ), // ClipRRect closing
            ), // InkWell closing
          ), // Material closing
        ), // Container closing
      ), // AspectRatio closing
      ), // Transform.scale closing
    ); // AnimatedBuilder closing
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFE9ECEF),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: AppColors.mainColor.withOpacity(0.3),
            ),
            SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getBestPrice() {
    if (widget.unit.sale != null && widget.unit.sale!.isCurrentlyActive) {
      return widget.unit.sale!.newPrice.toString();
    }
    if (widget.unit.discountedPrice != null &&
        widget.unit.discountedPrice!.isNotEmpty &&
        widget.unit.discountedPrice != '0') {
      return widget.unit.discountedPrice;
    }
    if (widget.unit.totalPrice != null &&
        widget.unit.totalPrice!.isNotEmpty &&
        widget.unit.totalPrice != '0') {
      return widget.unit.totalPrice;
    }
    if (widget.unit.normalPrice != null &&
        widget.unit.normalPrice!.isNotEmpty &&
        widget.unit.normalPrice != '0') {
      return widget.unit.normalPrice;
    }
    if (widget.unit.originalPrice != null &&
        widget.unit.originalPrice!.isNotEmpty &&
        widget.unit.originalPrice != '0') {
      return widget.unit.originalPrice;
    }
    return widget.unit.price;
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty || price == '0') {
      return 'Contact for Price';
    }
    try {
      final numPrice = double.parse(price);
      if (numPrice == 0) {
        return 'Contact for Price';
      }
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return '${numPrice.toStringAsFixed(0)}';
    } catch (e) {
      return 'Contact for Price';
    }
  }

  Widget _detailChip(IconData icon, String value, {Color? color}) {
    final chipColor = color ?? Colors.grey[700]!;
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: chipColor),
            SizedBox(width: 2),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: chipColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    final result = await NoteDialog.show(
      context,
      initialNote: _currentNote,
      title: _currentNote != null && _currentNote!.isNotEmpty
          ? 'Edit Note'
          : 'Add Note',
    );

    if (result != null && mounted) {
      final webServices = FavoritesWebServices();
      final bloc = context.read<UnitFavoriteBloc>();

      try {
        if (widget.unit.noteId != null) {
          await webServices.updateNote(
            noteId: widget.unit.noteId!,
            content: result,
            title: 'Unit Note',
          );
        } else {
          await webServices.createNote(
            content: result,
            title: 'Unit Note',
            unitId: int.tryParse(widget.unit.id),
          );
        }

        setState(() {
          _currentNote = result;
        });

        bloc.add(LoadFavoriteUnits());

        if (mounted) {
          MessageHelper.showSuccess(context, 'Note saved successfully');
        }
      } catch (e) {
        if (mounted) {
          MessageHelper.showError(context, 'Failed to save note: $e');
        }
      }
    }
  }

  Future<void> _showSalespeople(BuildContext context) async {
    final compoundWebServices = CompoundWebServices();
    final l10n = AppLocalizations.of(context)!;

    try {
      final compoundName = widget.unit.compoundName ?? '';
      if (compoundName.isEmpty) {
        if (context.mounted) {
          MessageHelper.showMessage(
            context: context,
            message: l10n.noSalesPersonAvailable,
            isSuccess: true,
          );
        }
        return;
      }

      final response = await compoundWebServices.getSalespeopleByCompound(compoundName);

      if (response['success'] == true && response['salespeople'] != null) {
        final salespeople = (response['salespeople'] as List)
            .map((sp) => SalesPerson.fromJson(sp as Map<String, dynamic>))
            .toList();

        if (salespeople.isNotEmpty && context.mounted) {
          SalesPersonSelector.show(
            context,
            salesPersons: salespeople,
          );
        } else if (context.mounted) {
          MessageHelper.showMessage(
            context: context,
            message: l10n.noSalesPersonAvailable,
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(context, '${l10n.error}: $e');
      }
    }
  }

  Widget _updateBadge(String changeType) {
    Color badgeColor;
    String badgeText;
    final isArabic = LanguageService.currentLanguage == 'ar';

    switch (changeType.toLowerCase()) {
      case 'new':
      case 'جديد':
        badgeColor = Color(0xFF4CAF50);
        badgeText = isArabic ? 'جديد' : 'NEW';
        break;
      case 'updated':
      case 'محدث':
        badgeColor = Color(0xFFFF9800);
        badgeText = isArabic ? 'محدث' : 'UPDATED';
        break;
      case 'deleted':
      case 'محذوف':
        badgeColor = Colors.red[700]!;
        badgeText = isArabic ? 'محذوف' : 'DELETED';
        break;
      default:
        badgeColor = Colors.blue[700]!;
        badgeText = changeType.toUpperCase();
    }

    return Container(
      width: 140,
      height: 25,
      padding: EdgeInsets.only(
        left: 35,
        right: 10,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          badgeText,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _saleBadge(Sale sale) {
    return Container(
      width: 140,
      height: 25,
      padding: EdgeInsets.only(
        left: 35,
        right: 10,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFF6B6B),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${sale.discountPercentage.toInt()}% OFF',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
