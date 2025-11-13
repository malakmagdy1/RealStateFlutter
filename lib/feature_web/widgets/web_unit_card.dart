import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_unit_detail_screen.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/core/widgets/note_dialog.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/animations/pulse_animation.dart';

class WebUnitCard extends StatefulWidget {
  final Unit unit;

  WebUnitCard({Key? key, required this.unit}) : super(key: key);

  @override
  State<WebUnitCard> createState() => _WebUnitCardState();
}

class _WebUnitCardState extends State<WebUnitCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(WebUnitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local note when widget is rebuilt with new data
    print('[WEB UNIT CARD] didUpdateWidget called');
    print('[WEB UNIT CARD] Old notes: ${oldWidget.unit.notes}');
    print('[WEB UNIT CARD] New notes: ${widget.unit.notes}');
    print('[WEB UNIT CARD] Old note_id: ${oldWidget.unit.noteId}');
    print('[WEB UNIT CARD] New note_id: ${widget.unit.noteId}');

    if (widget.unit.notes != oldWidget.unit.notes ||
        widget.unit.noteId != oldWidget.unit.noteId) {
      setState(() {
        _currentNote = widget.unit.notes;
      });
      print('[WEB UNIT CARD] Updated _currentNote to: $_currentNote');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for badges
    if (widget.unit.changeType != null) {
      print('[WEB UNIT CARD] Unit ${widget.unit.id}: changeType=${widget.unit.changeType}, isUpdated=${widget.unit.isUpdated}');
    }

    // Fallback to compound images if unit images are empty
    final unitImages = widget.unit.images ?? [];
    final bool hasImages = unitImages.isNotEmpty;

    // Use compound location for the location display, fallback to compound name if not available
    final compoundLocation = widget.unit.compoundLocation?.isNotEmpty == true
        ? widget.unit.compoundLocation!
        : (widget.unit.compoundName?.isNotEmpty == true ? widget.unit.compoundName! : '');

    final unitType = widget.unit.usageType ?? widget.unit.unitType ?? 'Unit';
    final unitNumber = widget.unit.unitNumber ?? '';

    // Display unit number/name separately from type
    String unitName = unitNumber.isNotEmpty ? unitNumber : 'Unit';

    // Hide sold units completely
    if (widget.unit.status?.toLowerCase() == 'sold') {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _animationController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _animationController.reverse();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08 + (_isHovering ? 0.04 : 0.0)),
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
                  context.push('/unit/${widget.unit.id}', extra: widget.unit.toJson());
                },
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

                      // Top Row: Action Buttons (Left) and Status (Right)
                      Positioned(
                        top: 20,
                        left: 12,
                        right: 12,
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
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
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
                                              },
                                              child: Container(
                                                height: 32,
                                                width: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.35),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                                  size: 16,
                                                  color: isFavorite ? Colors.red : Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    // Share Button
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => AdvancedShareBottomSheet(
                                              type: 'unit',
                                              id: widget.unit.id,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 32,
                                          width: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.35),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.share_outlined,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Note Button
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => _showNoteDialog(context),
                                        child: Container(
                                          height: 32,
                                          width: 32,
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
                                            size: 16,
                                            color: Colors.white,
                                          ),
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
                          right: -35,  // Extended further out for triangle effect
                          child: Transform.rotate(
                            angle: 0.785398, // 45 degrees
                            child: _saleBadge(widget.unit.sale!),
                          ),
                        ),

                      // Update badge (shown below sale badge if both exist)
                      if (widget.unit.isUpdated == true && widget.unit.changeType != null)
                        Positioned(
                          top: widget.unit.sale != null && widget.unit.sale!.isCurrentlyActive ? 48 : 8,  // Offset if sale badge exists
                          right: -35,  // Extended further out for triangle effect
                          child: Transform.rotate(
                            angle: 0.785398, // 45 degrees
                            child: _updateBadge(widget.unit.changeType!),
                          ),
                        ),
                      // Semi-transparent Info Area at bottom
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
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
                                    padding: const EdgeInsets.only(right: 6),
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundImage: NetworkImage(widget.unit.companyLogo!),
                                      backgroundColor: Colors.grey[200],
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    unitName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3),

                            // Unit Type (Villa, Apartment, etc.)
                            Text(
                              unitType,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),

                            // Compound Name
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                                SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    compoundLocation.isNotEmpty ? compoundLocation : 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 4),

                            // Property Details Row 1
                            Row(
                              children: [
                                _detailChip(Icons.bed_outlined, widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0' ? widget.unit.bedrooms : 'N/A'),
                                SizedBox(width: 3),
                                _detailChip(Icons.bathtub_outlined, widget.unit.bathrooms.isNotEmpty && widget.unit.bathrooms != '0' ? widget.unit.bathrooms : 'N/A'),
                                SizedBox(width: 3),
                                _detailChip(Icons.square_foot, widget.unit.area.isNotEmpty && widget.unit.area != '0' ? '${widget.unit.area}m²' : 'N/A'),
                              ],
                            ),

                            SizedBox(height: 3),
                            Row(
                              children: [
                                widget.unit.status.toLowerCase().contains('progress')
                                    ? _detailChip(Icons.pending, 'In Progress', color: Colors.orange)
                                    : widget.unit.status.toLowerCase() == 'available'
                                        ? _detailChip(Icons.check_circle, 'Available', color: Colors.green)
                                        : _detailChip(Icons.info_outline, widget.unit.status),
                                SizedBox(width: 3),
                                // Delivery Date
                                _detailChip(
                                  Icons.calendar_today,
                                  widget.unit.deliveryDate != null && widget.unit.deliveryDate!.isNotEmpty
                                      ? widget.unit.deliveryDate!
                                      : 'N/A',
                                ),
                              ],
                            ),

                            SizedBox(height: 4),
                            // Price and Phone Button Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'EGP ${_formatPrice(_getBestPrice())}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.mainColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Phone Button
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _showSalespeople(context),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF26A69A),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF26A69A).withOpacity(0.4),
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
            ),
          ),
        ),
      ),
    );
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

  Widget _actionButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return _AnimatedActionButton(
      icon: icon,
      onTap: onTap,
      color: color,
    );
  }

  String? _getBestPrice() {
    // Priority: sale price > discountedPrice > totalPrice > normalPrice > originalPrice > price
    // Check if unit has an active sale
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: chipColor),
            SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
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
    print('[WEB UNIT CARD] Opening note dialog');
    print('[WEB UNIT CARD] _currentNote: $_currentNote');
    print('[WEB UNIT CARD] widget.unit.notes: ${widget.unit.notes}');
    print('[WEB UNIT CARD] widget.unit.noteId: ${widget.unit.noteId}');

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

        // Update local state immediately
        setState(() {
          _currentNote = result;
        });

        // Trigger bloc refresh to reload favorites with updated noteId
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
      // Get compound name from unit
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

    switch (changeType.toLowerCase()) {
      case 'new':
        badgeColor = Color(0xFF4CAF50);
        badgeText = 'NEW';
        break;
      case 'updated':
        badgeColor = Color(0xFFFF9800);
        badgeText = 'UPDATED';
        break;
      case 'deleted':
        badgeColor = Colors.red[700]!;
        badgeText = 'DELETED';
        break;
      default:
        badgeColor = Colors.blue[700]!;
        badgeText = changeType.toUpperCase();
    }

    return Container(
      width: 140,
      height: 25,
      padding: EdgeInsets.only(
        left: 35,   // Push text to center of visible ribbon
        right: 10,
        top: 6,
        bottom: 6,
      ),// Add fixed height
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
      child: Center(  // Use Center widget instead of alignment
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
        left: 35,   // Push text to center of visible ribbon
        right: 10,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFF6B6B),  // Red/pink color for sale
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
// Animated Action Button Widget
class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _AnimatedActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _controller.forward().then((_) {
            _controller.reverse();
            widget.onTap();
          });
        },
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color != null ? widget.color!.withOpacity(0.1) : Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.color ?? Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
