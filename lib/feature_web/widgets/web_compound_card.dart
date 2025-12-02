import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/sale/data/models/sale_model.dart';
import 'package:real/feature/sale/presentation/widgets/sales_person_selector.dart';
import 'package:real/feature/share/presentation/widgets/advanced_share_bottom_sheet.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature_web/compound/presentation/web_compound_detail_screen.dart';
import 'package:real/core/widgets/note_dialog.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/animations/pulse_animation.dart';
import 'package:real/core/locale/locale_cubit.dart';
// ADDED: Import for comparison functionality
import 'package:real/feature/ai_chat/data/models/comparison_item.dart';
import 'package:real/feature/ai_chat/data/services/comparison_list_service.dart';

class WebCompoundCard extends StatefulWidget {
  final Compound compound;
  final bool showFavoriteButton;

  WebCompoundCard({
    Key? key,
    required this.compound,
    this.showFavoriteButton = true,
  }) : super(key: key);

  @override
  State<WebCompoundCard> createState() => _WebCompoundCardState();
}

class _WebCompoundCardState extends State<WebCompoundCard> with SingleTickerProviderStateMixin {
  String? _currentNote;
  bool _animateFavorite = false;
  bool _isHovering = false;
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(WebCompoundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local note when widget is rebuilt with new data
    print('[WEB COMPOUND CARD] didUpdateWidget called');
    print('[WEB COMPOUND CARD] Old notes: ${oldWidget.compound.notes}');
    print('[WEB COMPOUND CARD] New notes: ${widget.compound.notes}');
    print('[WEB COMPOUND CARD] Old note_id: ${oldWidget.compound.noteId}');
    print('[WEB COMPOUND CARD] New note_id: ${widget.compound.noteId}');

    if (widget.compound.notes != oldWidget.compound.notes ||
        widget.compound.noteId != oldWidget.compound.noteId) {
      setState(() {
        _currentNote = widget.compound.notes;
      });
      print('[WEB COMPOUND CARD] Updated _currentNote to: $_currentNote');
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


  void _showShareSheet(BuildContext context) async {
    // Fetch compound units for advanced share
    final compoundWebServices = CompoundWebServices();
    List<Map<String, dynamic>>? units;

    try {
      final response = await compoundWebServices.getUnitsForCompound(widget.compound.project);
      if (response['success'] == true && response['units'] != null) {
        units = (response['units'] as List).map((unit) => unit as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('[WEB COMPOUND CARD] Error fetching units: $e');
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
    final compound = widget.compound; // Create local variable for convenience
    final companyLogo = compound.fullCompanyLogoUrl ?? ''; // Store fullCompanyLogoUrl to avoid null promotion issues
    final l10n = AppLocalizations.of(context)!;

    // Minimum dimensions to prevent image disappearing
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 200,
        minHeight: 200,
      ),
      child: MouseRegion(
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: _elevationAnimation.value * 2.5,
                    offset: Offset(0, _elevationAnimation.value * 0.67),
                  ),
                ],
              ),
              child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('[WEB COMPOUND CARD] Card tapped - Compound ID: ${compound.id}, Name: ${compound.project}');
            context.push('/compound/${compound.id}');
          },
          borderRadius: BorderRadius.circular(24),
          hoverColor: AppColors.mainColor.withOpacity(0.03),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 🖼 Background Image - fills entire container
                Positioned.fill(
                  child: compound.images != null && compound.images!.isNotEmpty
                      ? RobustNetworkImage(
                    imageUrl: compound.images!.first,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, url) => _buildPlaceholder(),
                  )
                      : _buildPlaceholder(),
                ),

                // 🔝 Top icons & badges
                Positioned(
                  top: 20,
                  left: 12,
                  right: 12,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side icons (on image directly)
                      if (widget.showFavoriteButton)
                        Row(
                          children: [
                            // Favorite Button with BLoC
                            BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                              builder: (context, state) {
                                final bloc = context.read<CompoundFavoriteBloc>();
                                final isFavorite = bloc.isFavorite(compound);

                                return PulseAnimation(
                                  animate: _animateFavorite,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        bloc.toggleFavorite(compound);

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
                            // Compare Button with Active State
                            StreamBuilder<List<ComparisonItem>>(
                              stream: ComparisonListService().comparisonStream,
                              builder: (context, snapshot) {
                                final items = snapshot.data ?? [];
                                final isInComparison = items.any((item) =>
                                  item.id == widget.compound.id && item.type == 'compound'
                                );

                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _showCompareDialog(context),
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isInComparison
                                            ? AppColors.mainColor.withOpacity(0.9)
                                            : Colors.black.withOpacity(0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isInComparison ? Icons.compare : Icons.compare_arrows,
                                        size: 16,
                                        color: Colors.white,
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
                                onTap: () => _showShareSheet(context),
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

                      // Status badge (right side)
                    ],
                  ),
                ),),

                if (compound.updatedUnitsCount > 0)
                  Positioned(
                    top: 20,
                    left: 110,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF3B30).withOpacity(0.5),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_new, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${compound.updatedUnitsCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ⚪ Semi-transparent Info Area
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Compound Name with Company Logo
                      Row(
                        children: [
                          if (companyLogo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[200],
                                child: ClipOval(
                                  child: RobustNetworkImage(
                                    imageUrl: companyLogo,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, url) => Icon(
                                      Icons.business,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              compound.project,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Company Name
                      Padding(
                        padding: EdgeInsets.only(left: companyLogo.isNotEmpty ? 32 : 0),
                        child: Text(
                          compound.companyName.isNotEmpty ? compound.companyName : 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              compound.location.isNotEmpty ? compound.location : 'N/A',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          // 📞 Call Button
                          GestureDetector(
                            onTap: () => _showSalespeople(context),
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: Color(0xFF26A69A),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Color(0xFF26A69A).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      // Row 1: Units, Available, Floors (3 items)
                      Row(
                        children: [
                          _buildInfoIcon(Icons.home_work, '${compound.totalUnits ?? "0"} Units'),
                          SizedBox(width: 2),
                          _buildInfoIcon(Icons.check_circle_outline, '${compound.availableUnits ?? "0"} Available'),
                          SizedBox(width: 2),
                        ],
                      ),
                      SizedBox(height: 2),
                      // Row 2: Area, Progress, Delivery (3 items)
                      Row(
                        children: [
                          if (compound.builtUpArea.isNotEmpty && compound.builtUpArea != '0')
                            _buildInfoIcon(Icons.square_foot, '${compound.builtUpArea} m²')
                          else
                            _buildInfoIcon(Icons.square_foot, 'N/A m²'),

                          SizedBox(width: 2),
                          if (compound.plannedDeliveryDate != null && compound.plannedDeliveryDate!.isNotEmpty)
                            _buildInfoIcon(Icons.calendar_today, _formatDeliveryDate(compound.plannedDeliveryDate!))
                          else
                            _buildInfoIcon(Icons.calendar_today, 'N/A'),
                          SizedBox(width: 2),
                          //  compound.status == 'delivered'
                          //         ? const Color(0xFF4CAF50)
                          //         : Colors.orange,
                          //     lack.withOpacity(0.15),
                          //         blurRadius: 6,
                          //         offset: Offset(0, 2),
                          //       ),
                          //     ],
                          //   ),
                          //   child: Text(
                          //     compound.status.toUpperCase(),
                          //     style: const TextStyle(
                          //       color: Colors.white,
                          //       fontWeight: FontWeight.bold,
                          //       fontSize: 10,
                          //       letterSpacing: 0.3,
                          //     ),
                          //   ),
                          // ),

                         _buildStatusChip(compound.status, l10n),
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
          );
        },
      ),
      ),
    );

  }

  String _formatDeliveryDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';

    // Check for invalid date patterns (all zeros, starts with T, etc.)
    final cleanStr = dateStr.trim();
    if (cleanStr.startsWith('T') ||
        cleanStr.startsWith('0000') ||
        cleanStr == '0' ||
        cleanStr.contains('T00:00:00') && !cleanStr.contains('-')) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(cleanStr);
      // Check for invalid dates (year 0 or 1, or dates before 1900)
      if (date.year < 1900 || date.year > 2100) {
        return 'N/A';
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      // If parsing fails, try to extract just the date part before 'T'
      if (cleanStr.contains('T')) {
        final datePart = cleanStr.split('T')[0];
        if (datePart.startsWith('0000') || datePart == '0') {
          return 'N/A';
        }
        try {
          final date = DateTime.parse(datePart);
          if (date.year < 1900 || date.year > 2100) {
            return 'N/A';
          }
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${months[date.month - 1]} ${date.year}';
        } catch (_) {
          return 'N/A';
        }
      }
      return 'N/A';
    }
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    final statusLower = status.toLowerCase();

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
    return _detailChip(Icons.info_outline, status);
  }

  Widget _buildInfoIcon(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Icon(
          Icons.apartment,
          size: 60,
          color: AppColors.mainColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, {Color? color}) {
    final chipColor = color ?? AppColors.mainColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    print('[WEB COMPOUND CARD] Opening note dialog');
    print('[WEB COMPOUND CARD] _currentNote: $_currentNote');
    print('[WEB COMPOUND CARD] widget.compound.notes: ${widget.compound.notes}');
    print('[WEB COMPOUND CARD] widget.compound.noteId: ${widget.compound.noteId}');

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
        Map<String, dynamic> response;
        if (widget.compound.noteId != null) {
          // Update existing note using new Notes API
          print('[WEB COMPOUND CARD] Updating note with ID: ${widget.compound.noteId}');
          response = await webServices.updateNote(
            noteId: widget.compound.noteId!,
            content: result,
            title: 'Compound Note',
          );
          print('[WEB COMPOUND CARD] Update response: $response');
        } else {
          // Create new note using new Notes API
          print('[WEB COMPOUND CARD] Creating new note for compound: ${widget.compound.id}');
          response = await webServices.createNote(
            content: result,
            title: 'Compound Note',
            compoundId: int.tryParse(widget.compound.id),
          );
          print('[WEB COMPOUND CARD] Create response: $response');
        }

        // Update local state immediately
        setState(() {
          _currentNote = result;
        });
        print('[WEB COMPOUND CARD] Updated _currentNote to: $_currentNote');

        // Trigger bloc refresh to reload favorites with updated noteId
        print('[WEB COMPOUND CARD] Triggering LoadFavoriteCompounds');
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

  // Compare dialog method - Toggle comparison state
  void _showCompareDialog(BuildContext context) {
    final comparisonItem = ComparisonItem.fromCompound(widget.compound);
    final comparisonService = ComparisonListService();
    final l10n = AppLocalizations.of(context)!;

    // Check if already in comparison - toggle behavior
    if (comparisonService.contains(comparisonItem)) {
      // Remove from comparison list
      comparisonService.removeItem(comparisonItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.remove_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.removedFromComparison,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: l10n.undo,
            textColor: Colors.white,
            onPressed: () {
              comparisonService.addItem(comparisonItem);
            },
          ),
        ),
      );
      return;
    }

    // Add to comparison list
    final added = comparisonService.addItem(comparisonItem);

    if (added) {
      // Show success message with Go to AI button
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
              // Go to AI Chat button
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.push('/ai-chat');
                },
                icon: Icon(Icons.smart_toy, color: Colors.white, size: 18),
                label: Text(
                  l10n.goToAI,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(minutes: 2),
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
              // Go to AI Chat button even when full
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();context.push('/ai-chat');
                },
                icon: Icon(Icons.smart_toy, color: Colors.white, size: 18),
                label: Text(
                  l10n.goToAI,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10),
        ),
      );
    }
  }
}
