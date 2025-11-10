import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_unit_detail_screen.dart';
import 'package:real/feature/share/presentation/widgets/share_bottom_sheet.dart';
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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

    // Get unit name and compound name
    final unitNumber = widget.unit.unitNumber ?? '';
    final compoundName = widget.unit.compoundName?.isNotEmpty == true ? widget.unit.compoundName! : (widget.unit.companyName?.isNotEmpty == true ? widget.unit.companyName! : 'Property');

    // Build unit title from unitNumber if it contains a proper name, otherwise build from components
    String unitTitle = 'Unit';
    if (unitNumber.isNotEmpty && unitNumber.length > 10) {
      // If unitNumber is long, it likely contains the full unit name
      unitTitle = unitNumber;
    } else if (widget.unit.unitType.isNotEmpty) {
      // Build from components
      unitTitle = widget.unit.unitType;
      if (widget.unit.bedrooms.isNotEmpty && widget.unit.bedrooms != '0') {
        unitTitle += ' - ${widget.unit.bedrooms} Bed';
      }
      if (unitNumber.isNotEmpty) {
        unitTitle += ' ($unitNumber)';
      }
    } else if (unitNumber.isNotEmpty) {
      unitTitle = 'Unit $unitNumber';
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08 + (_isHovering ? 0.04 : 0.0)),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Prevent navigation if unit is sold
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
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.mainColor.withOpacity(0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    hasImages
                        ? RobustNetworkImage(
                            imageUrl: widget.unit.images.first,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                      // Share Button
                      Positioned(
                        top: 10,
                        left: 10,
                        child: MouseRegion(
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
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.share,
                                size: 18,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 10,
                        left: 50,
                        child: BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                          builder: (context, state) {
                            bool isFavorite = false;
                            if (state is UnitFavoriteUpdated) {
                              isFavorite = state.favorites.any((u) => u.id == widget.unit.id);
                            }
                            return MouseRegion(
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
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    size: 18,
                                    color: isFavorite ? Colors.red : AppColors.mainColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Note Button
                      Positioned(
                        top: 10,
                        left: 90,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _showNoteDialog(context),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.unit.notes != null && widget.unit.notes!.isNotEmpty
                                    ? AppColors.mainColor
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.unit.notes != null && widget.unit.notes!.isNotEmpty
                                    ? Icons.note
                                    : Icons.note_add_outlined,
                                size: 18,
                                color: widget.unit.notes != null && widget.unit.notes!.isNotEmpty
                                    ? Colors.white
                                    : AppColors.mainColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Update Badge for new/updated/deleted units
                      if (widget.unit.isUpdated == true && widget.unit.changeType != null)
                        _updateBadge(widget.unit.changeType!),
                      // Status Badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.unit.status ?? 'available'),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _getStatusLabel(widget.unit.status ?? 'available'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content section
              Flexible(
                child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Name with Code
                    Text(
                      unitTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    // Compound Name (subtitle)
                    Text(
                      compoundName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),

                    // Unit Details Row
                    _buildDetailRow(
                      Icons.villa_outlined,
                      widget.unit.unitType,
                      Icons.bed_outlined,
                      '${widget.unit.bedrooms} Beds',
                    ),
                    SizedBox(height: 10),

                    Spacer(),

                    // Price
                    Text(
                      _formatPrice(widget.unit.price),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      height: 160,
      width: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Icon(
          Icons.home_outlined,
          size: 50,
          color: AppColors.mainColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon1, String label1, IconData icon2, String label2) {
    return Row(
      children: [
        Icon(icon1, size: 18, color: AppColors.mainColor),
        SizedBox(width: 6),
        Text(
          label1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(width: 20),
        Icon(icon2, size: 18, color: AppColors.mainColor),
        SizedBox(width: 6),
        Text(
          label2,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
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
        return '${(numPrice / 1000000).toStringAsFixed(2)}M EGP';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K EGP';
      }
      return '${numPrice.toStringAsFixed(0)} EGP';
    } catch (e) {
      return 'Contact for Price';
    }
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'available':
        return Color(0xFF4CAF50); // Green
      case 'reserved':
        return Colors.orange;
      case 'sold':
        return Color(0xFFF44336); // Red
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
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'sold':
        return 'Sold';
      case 'in_progress':
        return 'In Progress';
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
      // Update notes via API
      if (widget.unit.favoriteId != null) {
        final webServices = FavoritesWebServices();
        try {
          await webServices.updateFavoriteNotes(
            favoriteId: widget.unit.favoriteId!,
            notes: result,
          );

          // Show success message
          if (mounted) {
            MessageHelper.showSuccess(context, result.isEmpty ? 'Note cleared' : 'Note saved');

            // Refresh favorites to show updated note
            context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
          }
        } catch (e) {
          if (mounted) {
            MessageHelper.showError(context, 'Failed to save note: $e');
          }
        }
      } else {
        // No favorite ID - shouldn't happen, but show warning
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

    return Positioned(
      bottom: 10,
      left: 10,
      child: Container(
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
      ),
    );
  }
}
