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

class _CompoundsNameState extends State<CompoundsName> {
  bool _animateFavorite = false;
  bool _animateShare = false;
  String? _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.compound.notes;
  }

  @override
  void didUpdateWidget(CompoundsName oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local note when widget is rebuilt with new data
    print('[COMPOUNDS NAME] didUpdateWidget called');
    print('[COMPOUNDS NAME] Old notes: ${oldWidget.compound.notes}');
    print('[COMPOUNDS NAME] New notes: ${widget.compound.notes}');
    print('[COMPOUNDS NAME] Old note_id: ${oldWidget.compound.noteId}');
    print('[COMPOUNDS NAME] New note_id: ${widget.compound.noteId}');

    if (widget.compound.notes != oldWidget.compound.notes ||
        widget.compound.noteId != oldWidget.compound.noteId) {
      setState(() {
        _currentNote = widget.compound.notes;
      });
      print('[COMPOUNDS NAME] Updated _currentNote to: $_currentNote');
    }
  }

  String _formatDate(String dateStr) {
    try {
      // Parse the date string
      final date = DateTime.parse(dateStr);
      // Format as day/month/year
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
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
    // Get the first image from the compound's images array
    final bool hasImages = widget.compound.images.isNotEmpty;
    final String? displayImage = hasImages ? widget.compound.images.first : null;

    // Use responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final double imageHeight = screenWidth * 0.30; // 30% of screen width for image (matches unit cards)
    final double borderRadius = 16;
    final double iconSize = 18.0; // Fixed icon size (matches unit cards)
    final double buttonSize = 32.0; // Fixed button size (matches unit cards)
    final double phoneButtonSize = 36.0; // Fixed size for phone button (matches unit cards)
    final double fontSize = 10.0; // Fixed font size
    final double titleFontSize = 16.0; // Fixed title font size

    // Debug company logo
    print('========================================');
    print('[COMPOUND CARD] Compound: ${widget.compound.project}');
    print('[COMPOUND CARD] Company: ${widget.compound.companyName}');
    print('[COMPOUND CARD] Company Logo URL: ${widget.compound.companyLogo ?? "NULL"}');
    print('[COMPOUND CARD] Has Logo: ${widget.compound.companyLogo != null && widget.compound.companyLogo!.isNotEmpty}');
    print('========================================');

    return HoverScaleAnimation(
      child: Hero(
        tag: 'compound_${widget.compound.id}${widget.heroTagSuffix != null ? "_${widget.heroTagSuffix}" : ""}',
        child: GestureDetector(
          onTap:
              widget.onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompoundScreen(compound: widget.compound),
                  ),
                );
              },
          behavior: HitTestBehavior.opaque,
          child: Container(
        // No fixed width/height - let parent GridView control sizing
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (hasImages)
              Stack(
                children: [
                  RobustNetworkImage(
                    imageUrl: displayImage!,
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    loadingBuilder: (context) => Container(
                      width: double.infinity,
                      height: imageHeight,
                      color: Colors.grey[200],
                      child: Center(child: CircularProgressIndicator(color: AppColors.mainColor)),
                    ),
                    errorBuilder: (context, url) {
                      return Container(
                        width: double.infinity,
                        height: imageHeight,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: imageHeight * 0.25,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),

                  // Recommended Badge - Top Center
                  if (widget.showRecommendedBadge)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.mainColor,
                                AppColors.mainColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.mainColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.recommend,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'RECOMMENDED',
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

                  // Top Row: Action Buttons (Left) and Status (Right)
                  Positioned(
                    top: widget.showRecommendedBadge ? 38 : 6, // Push down if recommended badge is showing (matches unit cards)
                    left: 6,
                    right: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Action Buttons Row - Wrapped in Flexible to prevent overflow
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite Button
                              BlocBuilder<
                                CompoundFavoriteBloc,
                                CompoundFavoriteState
                              >(
                                builder: (context, state) {
                                  final bloc = context.read<CompoundFavoriteBloc>();
                                  final isFavorite = bloc.isFavorite(widget.compound);

                                  return PulseAnimation(
                                    animate: _animateFavorite,
                                    child: _actionButton(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      () {
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
                                      buttonSize,
                                      iconSize,
                                      color: isFavorite ? Colors.red : null,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 4), // Matches unit cards
                              // Share Button
                              PulseAnimation(
                                animate: _animateShare,
                                child: _actionButton(Icons.share, () async {
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

                                  // Fetch compound units for advanced share
                                  final compoundWebServices = CompoundWebServices();
                                  List<Map<String, dynamic>>? units;

                                  try {
                                    final response = await compoundWebServices.getUnitsForCompound(widget.compound.project);
                                    if (response['success'] == true && response['units'] != null) {
                                      units = (response['units'] as List).map((unit) => unit as Map<String, dynamic>).toList();
                                    }
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
                                }, buttonSize, iconSize),
                              ),
                              SizedBox(width: 4), // Matches unit cards
                              // Note Button
                              _actionButton(
                                _currentNote != null && _currentNote!.isNotEmpty
                                    ? Icons.note
                                    : Icons.note_add_outlined,
                                () => _showNoteDialog(context),
                                buttonSize,
                                iconSize,
                                color: _currentNote != null && _currentNote!.isNotEmpty
                                    ? AppColors.mainColor
                                    : null,
                              ),
                              // Update Badge (NEW)
                              if (widget.compound.updatedUnitsCount > 0) ...[
                                SizedBox(width: 2), // Reduced from 4
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Reduced padding
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFFFF3B30).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fiber_new,
                                        color: Colors.white,
                                        size: 9, // Reduced from 10
                                      ),
                                      SizedBox(width: 1), // Reduced from 2
                                      Text(
                                        '${widget.compound.updatedUnitsCount}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8, // Reduced from 9
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 2), // Small spacer (reduced from 3)
                        // Status Badge - Also wrapped in Flexible
                        // Flexible(
                        //   child: Container(
                        //     padding: EdgeInsets.symmetric(
                        //       horizontal: 5, // Reduced from 6
                        //       vertical: 2,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: widget.compound.status == 'delivered'
                        //           ? Color(0xFF4CAF50)
                        //           : Color(0xFFFF9800),
                        //       borderRadius: BorderRadius.circular(20),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           color: (widget.compound.status == 'delivered'
                        //               ? Color(0xFF4CAF50)
                        //               : Color(0xFFFF9800)).withOpacity(0.3),
                        //           blurRadius: 8,
                        //           offset: Offset(0, 2),
                        //         ),
                        //       ],
                        //     ),
                        //     child: Text(
                        //       widget.compound.status.toUpperCase(),
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 7, // Reduced from 8
                        //         fontWeight: FontWeight.bold,
                        //         letterSpacing: 0.3,
                        //       ),
                        //       maxLines: 1,
                        //       overflow: TextOverflow.ellipsis,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),

            // Content Section - Flexible to fill remaining space
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3), // Further reduced to minimize white area
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Compound Title + Status Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.compound.project,
                          style: TextStyle(
                            fontSize: 13, // Reduced for compact look
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
                  SizedBox(height: 0.5),

                  // Company Name
                  Text(
                    widget.compound.companyName.isNotEmpty ? widget.compound.companyName : 'N/A',
                    style: TextStyle(
                      fontSize: 10, // Reduced for compact look
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5), // Minimized spacing

                  // Location and Phone Button Row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 11, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.compound.location.isNotEmpty ? widget.compound.location : 'N/A',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      // Phone Button with CircleAvatar
                      GestureDetector(
                        onTap: () => _showSalespeople(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF26A69A).withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 14, // 28 diameter - slightly smaller
                            backgroundColor: Color(0xFF26A69A),
                            child: Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1), // Minimized spacing

                  // Row 1: Units, Available, Floors (3 items in grey containers)
                  Row(
                    children: [
                      _detailChip(Icons.home_work, '${widget.compound.totalUnits ?? "0"}'),
                      SizedBox(width: 2),
                      _detailChip(Icons.check_circle_outline, '${widget.compound.availableUnits ?? "0"}', color: Colors.green),
                      SizedBox(width: 2),
                      _detailChip(Icons.layers, '${widget.compound.howManyFloors ?? "N/A"}'),
                    ],
                  ),

                  SizedBox(height: 1), // Minimized spacing

                  // Row 2: Area, Progress, Delivery (3 items in grey containers)
                  Row(
                    children: [
                      _detailChip(
                        Icons.square_foot,
                        widget.compound.builtUpArea.isNotEmpty && widget.compound.builtUpArea != '0'
                            ? '${widget.compound.builtUpArea}m²'
                            : 'N/A',
                      ),
                      SizedBox(width: 2),
                      if (widget.compound.completionProgress != null && widget.compound.completionProgress!.isNotEmpty)
                        _detailChip(Icons.trending_up, '${widget.compound.completionProgress}%', color: AppColors.mainColor)
                      else if (widget.compound.status.toLowerCase().contains('progress'))
                        _detailChip(Icons.pending, 'Progress', color: Colors.orange)
                      else
                        _detailChip(Icons.trending_up, 'N/A'),
                      SizedBox(width: 2),
                      _detailChip(
                        Icons.calendar_today,
                        widget.compound.plannedDeliveryDate != null && widget.compound.plannedDeliveryDate!.isNotEmpty
                            ? _formatDate(widget.compound.plannedDeliveryDate!)
                            : 'N/A',
                      ),
                    ],
                  ),

                  // Latest Update Note (if exists)
                  if (widget.compound.latestUpdateNote != null &&
                      widget.compound.latestUpdateNote!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF3B30).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFFFF3B30).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Color(0xFFFF3B30),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.compound.latestUpdateNote!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 3, // more room for text
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 8),

                  // Additional Info Chips - Always show
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildInfoChip(
                        icon: Icons.apartment,
                        label: widget.compound.totalUnits ?? '0',
                      ),
                      _buildInfoChip(
                        icon: Icons.check_circle_outline,
                        label: widget.compound.availableUnits ?? '0',
                        color: Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),

          ],
        ),
          ), // Container
        ), // GestureDetector
      ), // Hero
    ); // HoverScaleAnimation
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, double size, double iconSize, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
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

  Widget _detailChip(IconData icon, String value, {Color? color}) {
    final chipColor = color ?? Colors.grey[700]!;
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: color != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 9, color: chipColor),
            SizedBox(width: 1.5),
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.mainColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
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

    if (result != null && context.mounted) {
      final webServices = FavoritesWebServices();
      final bloc = context.read<CompoundFavoriteBloc>();

      try {
        if (widget.compound.noteId != null) {
          // Update existing note using new Notes API
          await webServices.updateNote(
            noteId: widget.compound.noteId!,
            content: result,
            title: 'Compound Note',
          );
        } else {
          // Create new note using new Notes API
          await webServices.createNote(
            content: result,
            title: 'Compound Note',
            compoundId: int.tryParse(widget.compound.id),
          );
        }

        // Update local state immediately
        setState(() {
          _currentNote = result;
        });

        // Trigger bloc refresh to reload favorites with updated noteId
        bloc.add(LoadFavoriteCompounds());

        if (context.mounted) {
          MessageHelper.showSuccess(context, 'Note saved successfully');
        }
      } catch (e) {
        if (context.mounted) {
          MessageHelper.showError(context, 'Failed to save note: $e');
        }
      }
    }
  }
}

// Company Logo Widget with fallback to API fetch
class _CompanyLogo extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String? companyLogo;

  _CompanyLogo({
    required this.companyId,
    required this.companyName,
    this.companyLogo,
  });

  @override
  State<_CompanyLogo> createState() => _CompanyLogoState();
}

class _CompanyLogoState extends State<_CompanyLogo> {
  String? _fetchedLogo;
  bool _isLoading = false;
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    // If no logo provided, fetch it from API
    if ((widget.companyLogo == null || widget.companyLogo!.isEmpty) && !_hasFetched) {
      _fetchCompanyLogo();
    }
  }

  Future<void> _fetchCompanyLogo() async {
    if (_isLoading || _hasFetched) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final companyWebServices = CompanyWebServices();
      final companyData = await companyWebServices.getCompanyById(widget.companyId);

      print('[COMPANY LOGO] Fetched company data: $companyData');

      if (mounted) {setState(() {
          _fetchedLogo = companyData['logo']?.toString();
          _isLoading = false;
          _hasFetched = true;
          print('[COMPANY LOGO] Logo URL: $_fetchedLogo');
        });
      }
    } catch (e) {
      print('[COMPANY LOGO] Error fetching company: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFetched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.companyLogo ?? _fetchedLogo;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: hasLogo
          ? ClipOval(
              child: RobustNetworkImage(
                imageUrl: logoUrl,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                loadingBuilder: (context) => Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                ),
                errorBuilder: (context, url) {
                  print('[COMPANY LOGO ERROR] Failed to load logo: $url');
                  return Container(
                    color: AppColors.mainColor.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        widget.companyName.isNotEmpty
                            ? widget.companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : Container(
              color: _isLoading ? Colors.grey.shade100 : AppColors.mainColor.withOpacity(0.1),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.mainColor,
                        ),
                      )
                    : Text(
                        widget.companyName.isNotEmpty
                            ? widget.companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
              ),
            ),
    );
  }
}
