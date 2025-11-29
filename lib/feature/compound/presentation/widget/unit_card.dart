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
import 'package:real/feature/ai_chat/data/models/comparison_item.dart';
import 'package:real/feature/ai_chat/data/services/comparison_list_service.dart';
import 'package:real/feature/ai_chat/presentation/widget/comparison_selection_sheet.dart';
import 'package:real/feature/ai_chat/presentation/screen/unified_ai_chat_screen.dart';

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
  bool _animateCompare = false;

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

    // Get localized compound location based on current locale
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n?.localeName == 'ar';
    final localizedCompoundLocation = widget.unit.getLocalizedCompoundLocation(isArabic);
    final compoundLocation = localizedCompoundLocation?.isNotEmpty == true
        ? localizedCompoundLocation!
        : 'N/A';

    final unitType = widget.unit.usageType ?? widget.unit.unitType ?? 'Unit';
    final unitNumber = widget.unit.unitNumber ?? '';
    final unitCode = widget.unit.code ?? '';
    String unitName = unitNumber.isNotEmpty
        ? unitNumber
        : (unitCode.isNotEmpty ? unitCode : 'Unit');

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

                    // Top Row: Action Buttons (positioned based on text direction)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                              SizedBox(width: 2),
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
                              SizedBox(width: 2),
                              // Share Button
                              GestureDetector(
                                onTap: () => _showShareDialog(context),
                                child: Container(
                                  height: 28,
                                  width: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.share_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2),
                              // Compare Button with Animation
                              StreamBuilder<List<ComparisonItem>>(
                                stream: ComparisonListService().comparisonStream,
                                builder: (context, snapshot) {
                                  final items = snapshot.data ?? [];
                                  final isInComparison = items.any((item) => item.id == widget.unit.id);

                                  return PulseAnimation(
                                    animate: _animateCompare,
                                    child: GestureDetector(
                                      onTap: () {
                                        _toggleCompare(context, isInComparison);
                                        setState(() {
                                          _animateCompare = true;
                                        });
                                        Future.delayed(Duration(milliseconds: 600), () {
                                          if (mounted) {
                                            setState(() {
                                              _animateCompare = false;
                                            });
                                          }
                                        });
                                      },
                                      child: Container(
                                        height: 28,
                                        width: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isInComparison
                                              ? AppColors.mainColor.withOpacity(0.9)
                                              : Colors.black.withOpacity(0.35),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isInComparison ? Icons.compare : Icons.compare_arrows,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                    ),

                    // Sale badge (higher priority, shown at top)
                    if (widget.unit.sale != null && widget.unit.sale!.isCurrentlyActive)
                      PositionedDirectional(
                        top: 8,
                        end: -35,
                        child: Transform.rotate(
                          angle: Directionality.of(context) == TextDirection.rtl ? -0.785398 : 0.785398, // 45 degrees, mirrored for RTL
                          child: _saleBadge(widget.unit.sale!),
                        ),
                      ),

                    // Update badge (shown below sale badge if both exist)
                    if (widget.unit.isUpdated == true && widget.unit.changeType != null)
                      PositionedDirectional(
                        top: widget.unit.sale != null && widget.unit.sale!.isCurrentlyActive ? 48 : 8,
                        end: -35,
                        child: Transform.rotate(
                          angle: Directionality.of(context) == TextDirection.rtl ? -0.785398 : 0.785398, // 45 degrees, mirrored for RTL
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
                                    fontSize: 14,
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
                              fontSize: 11,
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
                                    fontSize: 10,
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
                              _buildStatusChip(context),
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
                                  _formatDeliveryDate(widget.unit.deliveryDate),
                                  style: TextStyle(
                                    fontSize: 10,
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
                                    fontSize: 14,
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
    final l10n = AppLocalizations.of(context);
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
              l10n?.noImageAvailable ?? 'No Image Available',
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

  /// Format delivery date - removes ISO format (T00:00:00.000Z) and shows clean date
  String _formatDeliveryDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      // Parse ISO date format
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  Widget _buildStatusChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLower = widget.unit.status.toLowerCase();

    // Check for in_progress status (English and Arabic)
    if (statusLower.contains('progress') || statusLower == 'قيد الإنشاء' || statusLower == 'قيد التنفيذ') {
      return _detailChip(Icons.pending, l10n.inProgress, color: Colors.orange);
    }
    // Check for available status (English and Arabic)
    else if (statusLower == 'available' || statusLower == 'متاح') {
      return _detailChip(Icons.check_circle, l10n.available, color: Colors.green);
    }
    // Check for reserved status (English and Arabic)
    else if (statusLower == 'reserved' || statusLower == 'محجوز') {
      return _detailChip(Icons.bookmark, l10n.reserved, color: Colors.orange);
    }
    // Check for sold status (English and Arabic)
    else if (statusLower == 'sold' || statusLower == 'مباع') {
      return _detailChip(Icons.sell, l10n.sold, color: Colors.red);
    }
    // Default: show the status as-is
    return _detailChip(Icons.info_outline, widget.unit.status);
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
            Icon(icon, size: 12, color: chipColor),
            SizedBox(width: 2),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 9,
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
    final l10n = AppLocalizations.of(context)!;
    final result = await NoteDialog.show(
      context,
      initialNote: _currentNote,
      title: _currentNote != null && _currentNote!.isNotEmpty
          ? l10n.editNote
          : l10n.addNote,
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

  void _showShareDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedShareBottomSheet(
        type: 'unit',
        id: widget.unit.id,
      ),
    );
  }

  void _toggleCompare(BuildContext context, bool isInComparison) {
    final comparisonItem = ComparisonItem.fromUnit(widget.unit);
    final comparisonService = ComparisonListService();
    final l10n = AppLocalizations.of(context)!;

    if (isInComparison) {
      // Remove from comparison
      comparisonService.removeItem(comparisonItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.remove_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Removed from comparison',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Add to comparison list
      final added = comparisonService.addItem(comparisonItem);

      if (added) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.addedToComparison,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error (list is full)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.comparisonListFull,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
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
