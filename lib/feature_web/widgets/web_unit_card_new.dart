import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_unit_detail_screen.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/core/widgets/note_dialog.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/utils/message_helper.dart';

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
    final bool hasImages = widget.unit.images.isNotEmpty;
    final compoundName = widget.unit.compoundName?.isNotEmpty == true
        ? widget.unit.compoundName!
        : (widget.unit.companyName?.isNotEmpty == true ? widget.unit.companyName! : '');

    final unitType = widget.unit.usageType ?? widget.unit.unitType ?? 'Unit';
    final unitNumber = widget.unit.unitNumber ?? '';

    String unitTitle = unitType;
    if (unitNumber.isNotEmpty) {
      unitTitle += ' $unitNumber';
    }

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
                      builder: (context) => WebUnitDetailScreen(
                        unitId: widget.unit.id,
                        unit: widget.unit,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                hoverColor: AppColors.mainColor.withOpacity(0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          hasImages
                              ? RobustNetworkImage(
                                  imageUrl: widget.unit.images.first,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, url) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),

                          // Top Row: Action Buttons (Left) and Status (Right)
                          Positioned(
                            top: 12,
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
                                        return _actionButton(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          () {
                                            if (isFavorite) {
                                              context.read<UnitFavoriteBloc>().add(
                                                RemoveFavoriteUnit(widget.unit),
                                              );
                                            } else {
                                              context.read<UnitFavoriteBloc>().add(
                                                AddFavoriteUnit(widget.unit),
                                              );
                                            }
                                          },
                                          color: isFavorite ? Colors.red : null,
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8),
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
                                    }),
                                    SizedBox(width: 8),
                                    // Note Button
                                    _actionButton(
                                      widget.unit.notes != null && widget.unit.notes!.isNotEmpty
                                          ? Icons.note
                                          : Icons.note_add_outlined,
                                      () => _showNoteDialog(context),
                                      color: widget.unit.notes != null && widget.unit.notes!.isNotEmpty
                                          ? AppColors.mainColor
                                          : null,
                                    ),
                                  ],
                                ),
                                // Status Badge
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(widget.unit.status ?? 'available'),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor(widget.unit.status ?? 'available').withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _getStatusLabel(widget.unit.status ?? 'available'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom Right: Phone Button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Color(0xFF26A69A), // Teal color
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF26A69A).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),

                          // Update Badge for new/updated/deleted units
                          if (widget.unit.isUpdated == true && widget.unit.changeType != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: _updateBadge(widget.unit.changeType!),
                            ),
                        ],
                      ),
                    ),

                    // Content section
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Unit Title
                            Text(
                              unitTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6),

                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    compoundName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Property Details Row
                            Row(
                              children: [
                                if (widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0')
                                  _detailChip(Icons.bed_outlined, widget.unit.bedrooms),
                                if (widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0' &&
                                    widget.unit.bathrooms.isNotEmpty && widget.unit.bathrooms != '0')
                                  SizedBox(width: 12),
                                if (widget.unit.bathrooms.isNotEmpty && widget.unit.bathrooms != '0')
                                  _detailChip(Icons.bathtub_outlined, widget.unit.bathrooms),
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
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Icon(
          Icons.home_outlined,
          size: 60,
          color: AppColors.mainColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color != null ? color.withOpacity(0.1) : Colors.white.withOpacity(0.95),
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
            icon,
            size: 20,
            color: color ?? Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
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
      initialNote: widget.unit.notes,
      title: widget.unit.notes != null && widget.unit.notes!.isNotEmpty
          ? 'Edit Note'
          : 'Add Note',
    );

    if (result != null && mounted) {
      if (widget.unit.favoriteId != null) {
        final webServices = FavoritesWebServices();
        try {
          await webServices.updateFavoriteNotes(
            favoriteId: widget.unit.favoriteId!,
            notes: result,
          );

          if (mounted) {
            MessageHelper.showSuccess(context, result.isEmpty ? 'Note cleared' : 'Note saved');
            context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
          }
        } catch (e) {
          if (mounted) {
            MessageHelper.showError(context, 'Failed to save note: $e');
          }
        }
      } else {
        if (mounted) {
          MessageHelper.showMessage(
            context: context,
            message: 'Cannot save note: Item not in favorites',
            isSuccess: false,
          );
        }
      }
    }
  }

  Widget _updateBadge(String changeType) {
    Color badgeColor;
    String badgeText;

    switch (changeType.toLowerCase()) {
      case 'new':
        badgeColor = Colors.green;
        badgeText = 'NEW';
        break;
      case 'updated':
        badgeColor = Colors.orange;
        badgeText = 'UPDATED';
        break;
      case 'deleted':
        badgeColor = Colors.red;
        badgeText = 'DELETED';
        break;
      default:
        badgeColor = Colors.blue;
        badgeText = changeType.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
