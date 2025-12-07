import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/home/presentation/widget/location.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/company/data/web_services/company_web_services.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/animations/hover_scale_animation.dart';
import 'package:real/core/animations/pulse_animation.dart';
import 'package:real/core/widgets/note_dialog.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/utils/card_dimensions.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/utils/text_style.dart';
import '../CompoundScreen.dart';
import '../../../ai_chat/data/models/comparison_item.dart';
import '../../../ai_chat/data/services/comparison_list_service.dart';

class CompoundsName extends StatefulWidget {
  final Compound compound;
  final VoidCallback? onTap;
  final String? heroTagSuffix;
  final bool showRecommendedBadge;

  CompoundsName({
    Key? key,
    required this.compound,
    this.onTap,
    this.heroTagSuffix,
    this.showRecommendedBadge = false,
  }) : super(key: key);

  @override
  State<CompoundsName> createState() => _CompoundsNameState();
}

class _CompoundsNameState extends State<CompoundsName> with SingleTickerProviderStateMixin {
  bool _animateFavorite = false;
  bool _animateShare = false;
  String? _currentNote;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.compound.notes;

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
  void didUpdateWidget(CompoundsName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.compound.notes != oldWidget.compound.notes ||
        widget.compound.noteId != oldWidget.compound.noteId) {
      setState(() {
        _currentNote = widget.compound.notes;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  /// Format area value - rounds to nearest integer or 1 decimal place
  String _formatArea(String? areaStr) {
    if (areaStr == null || areaStr.isEmpty) return 'N/A';
    try {
      final area = double.parse(areaStr);
      // If it's a whole number, show without decimals
      if (area == area.roundToDouble()) {
        return area.toInt().toString();
      }
      // Otherwise show with 1 decimal place
      return area.toStringAsFixed(1);
    } catch (e) {
      return areaStr;
    }
  }

  Future<void> _showSalespeople(BuildContext context) async {
    final compoundWebServices = CompoundWebServices();
    final l10n = AppLocalizations.of(context)!;

    try {
      final response = await compoundWebServices.getSalespeopleByCompound(widget.compound.project);

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
    final bool hasImages = widget.compound.images.isNotEmpty;
    final String? displayImage = hasImages ? widget.compound.images.first : null;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
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
              onTap: widget.onTap ??
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompoundScreen(compound: widget.compound),
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
                child: SizedBox(
                  height: double.infinity,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                    // Background Image - fills entire container
                    Positioned.fill(
                      child: hasImages
                          ? RobustNetworkImage(
                              imageUrl: displayImage!,
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
                              BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                                builder: (context, state) {
                                  final bloc = context.read<CompoundFavoriteBloc>();
                                  final isFavorite = bloc.isFavorite(widget.compound);

                                  return PulseAnimation(
                                    animate: _animateFavorite,
                                    child: GestureDetector(
                                      onTap: () {
                                        bloc.toggleFavorite(widget.compound);
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
                                  );
                                },
                              ),
                              SizedBox(width: 8),
                              // Share Button
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    _animateShare = true;
                                  });
                                  Future.delayed(Duration(milliseconds: 600), () {
                                    if (mounted) {
                                      setState(() {
                                        _animateShare = false;
                                      });
                                    }
                                  });

                                  final compoundWebServices = CompoundWebServices();
                                  List<Map<String, dynamic>>? units;

                                  try {
                                    final response = await compoundWebServices.getUnitsForCompound(widget.compound.project);
                                    // Handle multiple response structures
                                    if (response['success'] == true) {
                                      if (response['units'] != null) {
                                        units = (response['units'] as List).map((unit) => unit as Map<String, dynamic>).toList();
                                      } else if (response['data'] != null && response['data'] is List) {
                                        units = (response['data'] as List).map((unit) => unit as Map<String, dynamic>).toList();
                                      }
                                    }
                                    print('[COMPOUND CARD] Fetched ${units?.length ?? 0} units for share');
                                  } catch (e) {
                                    print('[COMPOUND CARD] Error fetching units: $e');
                                  }

                                  if (context.mounted) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => AdvancedShareBottomSheet(
                                        type: 'compound',
                                        id: widget.compound.id.toString(),
                                        units: units,
                                      ),
                                    );
                                  }
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
                              SizedBox(width: 4),
                              // Compare Button with Active State
                              StreamBuilder<List<ComparisonItem>>(
                                stream: ComparisonListService().comparisonStream,
                                builder: (context, snapshot) {
                                  final items = snapshot.data ?? [];
                                  final isInComparison = items.any((item) =>
                                    item.id == widget.compound.id && item.type == 'compound'
                                  );

                                  return GestureDetector(
                                    onTap: () => _showCompareDialog(context),
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
                                  );
                                },
                              ),
                              SizedBox(width: 4),
                              // Note Button
                              GestureDetector(
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
                            ],
                          ),
                    ),

                    // Update Badge (NEW units)
                    if (widget.compound.updatedUnitsCount > 0)
                      PositionedDirectional(
                        top: 8,
                        end: -35,
                        child: Transform.rotate(
                          angle: Directionality.of(context) == TextDirection.rtl ? -0.785398 : 0.785398, // 45 degrees, mirrored for RTL
                          child: Container(
                            width: 140,
                            height: 25,
                            padding: EdgeInsets.only(
                              left: 35,
                              right: 10,
                              top: 6,
                              bottom: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fiber_new, color: Colors.white, size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.compound.updatedUnitsCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                          // Compound Name with Company Logo
                          Row(
                            children: [
                              if (widget.compound.fullCompanyLogoUrl != null && widget.compound.fullCompanyLogoUrl!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundImage: NetworkImage(widget.compound.fullCompanyLogoUrl!),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  widget.compound.project,
                                  style: TextStyle(
                                    fontSize: 15,
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
                          SizedBox(height: 2),

                          // Company Name
                          Text(
                            widget.compound.companyName.isNotEmpty ? widget.compound.companyName : 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),

                          // Location
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                              SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.compound.location.isNotEmpty ? widget.compound.location : 'N/A',
                                  style: TextStyle(
                                    fontSize: 11,
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
                              _detailChip(Icons.home_work, '${widget.compound.totalUnits ?? "0"}'),
                              SizedBox(width: 3),
                              _detailChip(Icons.check_circle_outline, '${widget.compound.availableUnits ?? "0"}', color: Colors.green),
                              SizedBox(width: 3),
                              _detailChip(Icons.layers, '${widget.compound.howManyFloors ?? "N/A"}'),
                            ],
                          ),

                          SizedBox(height: 3),

                          // Property Details Row 2
                          Row(
                            children: [
                              _detailChip(
                                Icons.square_foot,
                                widget.compound.builtUpArea.isNotEmpty && widget.compound.builtUpArea != '0'
                                    ? '${_formatArea(widget.compound.builtUpArea)}m²'
                                    : 'N/A',
                              ),
                              SizedBox(width: 3),
                              if (widget.compound.completionProgress != null && widget.compound.completionProgress!.isNotEmpty)
                                _detailChip(Icons.trending_up, '${widget.compound.completionProgress}%', color: AppColors.mainColor)
                              else if (widget.compound.status.toLowerCase().contains('progress'))
                                _detailChip(Icons.pending, 'Progress', color: Colors.orange)
                              else
                                _detailChip(Icons.trending_up, 'N/A'),
                            ],
                          ),

                          SizedBox(height: 4),

                          // Delivery Date and Phone Button Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                    SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        widget.compound.plannedDeliveryDate != null && widget.compound.plannedDeliveryDate!.isNotEmpty
                                            ? _formatDate(widget.compound.plannedDeliveryDate!)
                                            : 'N/A',
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

  Widget _detailChip(IconData icon, String value, {Color? color}) {
    final chipColor = color ?? Colors.grey[700]!;
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: chipColor),
            SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 10,
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
      title: _currentNote != null && _currentNote!.isNotEmpty ? l10n.editNote : l10n.addNote,
    );

    if (result != null && mounted) {
      final webServices = FavoritesWebServices();
      final bloc = context.read<CompoundFavoriteBloc>();

      try {
        if (widget.compound.noteId != null) {
          await webServices.updateNote(
            noteId: widget.compound.noteId!,
            content: result,
            title: 'Compound Note',
          );
        } else {
          await webServices.createNote(
            content: result,
            title: 'Compound Note',
            compoundId: int.tryParse(widget.compound.id),
          );
        }

        setState(() {
          _currentNote = result;
        });

        bloc.add(LoadFavoriteCompounds());

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

  void _showCompareDialog(BuildContext context) {
    final comparisonItem = ComparisonItem.fromCompound(widget.compound);
    final comparisonService = ComparisonListService();
    final l10n = AppLocalizations.of(context)!;

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
          action: SnackBarAction(
            label: l10n.undo,
            textColor: Colors.white,
            onPressed: () {
              comparisonService.removeItem(comparisonItem);
            },
          ),
        ),
      );
    } else {
      // Show error (already in list or list is full)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  comparisonService.isFull
                      ? l10n.comparisonListFull
                      : l10n.alreadyInComparison,
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
}
