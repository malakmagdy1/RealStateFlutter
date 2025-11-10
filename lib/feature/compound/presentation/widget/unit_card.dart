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

    _elevationAnimation = Tween<double>(begin: 4.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(UnitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local note when widget is rebuilt with new data
    print('[UNIT CARD] didUpdateWidget called');
    print('[UNIT CARD] Old notes: ${oldWidget.unit.notes}');
    print('[UNIT CARD] New notes: ${widget.unit.notes}');
    print('[UNIT CARD] Old note_id: ${oldWidget.unit.noteId}');
    print('[UNIT CARD] New note_id: ${widget.unit.noteId}');

    if (widget.unit.notes != oldWidget.unit.notes ||
        widget.unit.noteId != oldWidget.unit.noteId) {
      setState(() {
        _currentNote = widget.unit.notes;
      });
      print('[UNIT CARD] Updated _currentNote to: $_currentNote');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showSalespeople(BuildContext context) async {
    final compoundWebServices = CompoundWebServices();
    final l10n = AppLocalizations.of(context)!;

    try {
      final response = await compoundWebServices.getSalespeopleByCompound(widget.unit.compoundId);

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final unitImages = widget.unit.images ?? [];
    final bool hasImages = unitImages.isNotEmpty;

    final compoundName = widget.unit.compoundName?.isNotEmpty == true
        ? widget.unit.compoundName!
        : '';

    final unitType = widget.unit.usageType ?? widget.unit.unitType ?? 'Unit';
    final unitNumber = widget.unit.unitNumber ?? '';

    // Display unit number/name separately from type
    String unitName = unitNumber.isNotEmpty ? unitNumber : 'Unit';

    // Hide sold units completely
    if (widget.unit.status?.toLowerCase() == 'sold') {
      return SizedBox.shrink();
    }

    // Fixed sizing for consistency with compound cards
    final double imageHeight = screenWidth * 0.30; // 30% of screen width (matches compound cards)
    final double borderRadius = 16;
    final double actionButtonSize = 32.0; // Fixed size (matches compound cards)
    final double actionIconSize = 18.0; // Fixed size (matches compound cards)
    final double phoneButtonSize = 36.0; // Fixed size (matches compound cards)
    final double phoneIconSize = 20.0; // Fixed size for better visibility
    final double contentPadding = 6; // Reduced padding for compact text area
    final double titleFontSize = screenWidth * 0.033; // 3.3% of screen width (reduced)
    final double subtitleFontSize = screenWidth * 0.024; // 2.4% of screen width (reduced)
    final double priceFontSize = screenWidth * 0.037; // 3.7% of screen width (reduced)

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: _elevationAnimation.value,
                offset: Offset(0, 4),
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
              borderRadius: BorderRadius.circular(borderRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                    child: Stack(
                      children: [
                        hasImages
                            ? RobustNetworkImage(
                                imageUrl: unitImages.first,
                                height: imageHeight,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, url) => _buildPlaceholder(imageHeight),
                              )
                            : _buildPlaceholder(imageHeight),

                        // Top Row: Action Buttons (Left) and Status (Right)
                        Positioned(
                          top: 6,
                          left: 6,
                          right: 6,
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
                                      print('[UNIT CARD] Favorite button state - Unit ${widget.unit.id}: isFavorite=$isFavorite');
                                      return PulseAnimation(
                                        animate: _animateFavorite,
                                        child: _actionButton(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          () {
                                            print('[UNIT CARD] Favorite button clicked - Unit ${widget.unit.id}, current state: $isFavorite');
                                            try {
                                              if (isFavorite) {
                                                print('[UNIT CARD] Removing from favorites');
                                                context.read<UnitFavoriteBloc>().add(
                                                  RemoveFavoriteUnit(widget.unit),
                                                );
                                              } else {
                                                print('[UNIT CARD] Adding to favorites');
                                                context.read<UnitFavoriteBloc>().add(
                                                  AddFavoriteUnit(widget.unit),
                                                );
                                              }

                                              // Trigger pulse animation
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
                                            } catch (e) {
                                              print('[UNIT CARD] Error toggling favorite: $e');
                                            }
                                          },
                                          actionButtonSize,
                                          actionIconSize,
                                          color: isFavorite ? Colors.red : null,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 4),
                                  // Share Button
                                  _actionButton(Icons.share, () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => AdvancedShareBottomSheet(
                                        type: 'unit',
                                        id: widget.unit.id,
                                      ),
                                    );
                                  }, actionButtonSize, actionIconSize),
                                  SizedBox(width: 4),
                                  // Note Button
                                  _actionButton(
                                    _currentNote != null && _currentNote!.isNotEmpty
                                        ? Icons.note
                                        : Icons.note_add_outlined,
                                    () => _showNoteDialog(context),
                                    actionButtonSize,
                                    actionIconSize,
                                    color: _currentNote != null && _currentNote!.isNotEmpty
                                        ? AppColors.mainColor
                                        : null,
                                  ),
                                ],
                              ),
                              // Status Badge - REMOVED per user request
                            ],
                          ),
                        ),

                        // Update Badge - REMOVED per user request (was rotated ribbon)
                      ],
                    ),
                  ),

                  // Content section
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.all(3), // Further reduced to prevent overflow
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
                                    fontSize: titleFontSize,
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
                          SizedBox(height: 0.5),

                          // Unit Type (Villa, Apartment, etc.)
                          Text(
                            unitType,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5),

                          // Location
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: subtitleFontSize, color: Colors.grey[600]),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  compoundName,
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 0.5),

                          // Property Details Row 1
                          Row(
                            children: [
                              _detailChip(Icons.bed_outlined, widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0' ? widget.unit.bedrooms : 'N/A', subtitleFontSize),
                              SizedBox(width: 3),
                              _detailChip(Icons.bathtub_outlined, widget.unit.bathrooms.isNotEmpty && widget.unit.bathrooms != '0' ? widget.unit.bathrooms : 'N/A', subtitleFontSize),
                              SizedBox(width: 3),
                              _detailChip(Icons.square_foot, widget.unit.area.isNotEmpty && widget.unit.area != '0' ? '${widget.unit.area}m²' : 'N/A', subtitleFontSize),
                            ],
                          ),

                          SizedBox(height: 0.3),

                          // Property Details Row 2 (Floor, Status/Progress, Delivery)
                          Row(
                            children: [
                              _detailChip(Icons.stairs, 'Floor: ${widget.unit.floor.isNotEmpty && widget.unit.floor != '0' ? widget.unit.floor : 'N/A'}', subtitleFontSize * 0.9),
                              SizedBox(width: 3),
                              // Status/Progress
                              widget.unit.status.toLowerCase().contains('progress')
                                  ? _detailChip(Icons.pending, 'In Progress', subtitleFontSize * 0.9, color: Colors.orange)
                                  : widget.unit.status.toLowerCase() == 'available'
                                      ? _detailChip(Icons.check_circle, 'Available', subtitleFontSize * 0.9, color: Colors.green)
                                      : _detailChip(Icons.info_outline, widget.unit.status, subtitleFontSize * 0.9),
                              SizedBox(width: 3),
                              // Delivery Date
                              _detailChip(
                                Icons.calendar_today,
                                widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty
                                    ? widget.unit.deliveryDate!
                                    : 'N/A',
                                subtitleFontSize * 0.9,
                              ),
                            ],
                          ),

                          SizedBox(height: 0.3),

                          // Price and Phone Button Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'EGP ${_formatPrice(_getBestPrice())}',
                                  style: TextStyle(
                                    fontSize: priceFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Phone Button with CircleAvatar
                              GestureDetector(
                                onTap: () => _showSalespeople(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF26A69A).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: phoneButtonSize / 2,
                                    backgroundColor: Color(0xFF26A69A),
                                    child: Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                      size: phoneIconSize,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
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
              size: height * 0.3,
              color: AppColors.mainColor.withOpacity(0.3),
            ),
            SizedBox(height: 6),
            Text(
              'No Image Available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, double buttonSize, double iconSize, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: color != null ? color.withOpacity(0.1) : Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: color ?? Colors.grey[700],
        ),
      ),
    );
  }

  String? _getBestPrice() {
    // Priority: discountedPrice > totalPrice > normalPrice > originalPrice > price
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

  Widget _detailChip(IconData icon, String value, double fontSize, {Color? color}) {
    final chipColor = color ?? Colors.grey[700]!;
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: color != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: fontSize * 1.15, color: chipColor),
            SizedBox(width: 2),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize * 0.9,
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

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'available':
        return Color(0xFF4CAF50);
      case 'reserved':
        return Colors.orange;
      case 'sold':
        return Color(0xFFF44336);
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'available':
        return 'AVAILABLE';
      case 'reserved':
        return 'RESERVED';
      case 'sold':
        return 'SOLD';
      case 'in_progress':
        return 'IN PROGRESS';
      default:
        return status.toUpperCase();
    }
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
          // Update existing note using new Notes API
          await webServices.updateNote(
            noteId: widget.unit.noteId!,
            content: result,
            title: 'Unit Note',
          );
        } else {
          // Create new note using new Notes API
          await webServices.createNote(
            content: result,
            title: 'Unit Note',
            unitId: int.tryParse(widget.unit.id),
          );
        }

        setState(() {
          _currentNote = result;
        });

        // Reload favorites to get updated noteId
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

  Widget _updateBadge(String changeType, double screenWidth) {
    Color badgeColor;
    String badgeText;

    switch (changeType.toLowerCase()) {
      case 'new':
        badgeColor = Color(0xFF4CAF50); // Green
        badgeText = 'NEW';
        break;
      case 'updated':
        badgeColor = Color(0xFFFF9800); // Orange
        badgeText = 'UPDATED';
        break;
      case 'deleted':
        badgeColor = Colors.red[700]!; // Red
        badgeText = 'DELETED';
        break;
      default:
        badgeColor = Colors.blue[700]!;
        badgeText = changeType.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      color: badgeColor,
      child: Text(
        badgeText,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
