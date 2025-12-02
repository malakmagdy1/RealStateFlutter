import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import '../../../feature_web/widgets/web_compound_card.dart';
import '../../../feature_web/widgets/web_unit_card.dart';

class WebFavoritesScreen extends StatefulWidget {
  WebFavoritesScreen({Key? key}) : super(key: key);

  @override
  State<WebFavoritesScreen> createState() => _WebFavoritesScreenState();
}

class _WebFavoritesScreenState extends State<WebFavoritesScreen> {
  // Pagination variables
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 12;
  int _displayedUnitCount = 12;
  int _displayedCompoundCount = 12;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger when 200px from bottom

    if (maxScroll - currentScroll <= delta) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
    });

    // Simulate slight delay for smooth UX
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayedUnitCount += _pageSize;
          _displayedCompoundCount += _pageSize;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 32,
                        color: AppColors.mainColor,
                      ),
                      SizedBox(width: 16),
                      Text(
                        l10n.myFavorites,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.yourSavedCompoundsAndProperties,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 48),
                  BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                    builder: (context, compoundState) {
                      return BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                        builder: (context, unitState) {
                          final compoundFavorites = compoundState is CompoundFavoriteUpdated
                              ? compoundState.favorites
                              : [];
                          final unitFavorites = unitState is UnitFavoriteUpdated
                              ? unitState.favorites
                              : [];

                          // Check if both are empty
                          if (compoundFavorites.isEmpty && unitFavorites.isEmpty) {
                            return SizedBox(
                              height: 400,
                              child: _buildEmptyState(context),
                            );
                          }

                          // Calculate displayed items
                          final displayedUnits = unitFavorites.take(_displayedUnitCount).toList();
                          final displayedCompounds = compoundFavorites.take(_displayedCompoundCount).toList();
                          final hasMoreUnits = unitFavorites.length > _displayedUnitCount;
                          final hasMoreCompounds = compoundFavorites.length > _displayedCompoundCount;
                          final hasMore = hasMoreUnits || hasMoreCompounds;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display Unit Favorites
                              if (unitFavorites.isNotEmpty) ...[
                                Text(
                                  '${l10n.favoriteProperties} (${displayedUnits.length}/${unitFavorites.length})',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 20),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 300, // Unified width (increased by 40)
                                    childAspectRatio: 0.85, // Unified aspect ratio (wider cards, shorter height)
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: displayedUnits.length,
                                  itemBuilder: (context, index) {
                                    return WebUnitCard(
                                      unit: displayedUnits[index],
                                    );
                                  },
                                ),
                                SizedBox(height: 40),
                              ],
                              // Display Compound Favorites
                              if (compoundFavorites.isNotEmpty) ...[
                                Text(
                                  '${l10n.favoriteCompounds} (${displayedCompounds.length}/${compoundFavorites.length})',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 20),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 300, // Unified width (increased by 40)
                                    childAspectRatio: 0.85, // Unified aspect ratio (wider cards, shorter height)
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: displayedCompounds.length,
                                  itemBuilder: (context, index) {
                                    return WebCompoundCard(
                                      compound: displayedCompounds[index],
                                    );
                                  },
                                ),
                                SizedBox(height: 20),
                              ],
                              // Loading indicator when loading more
                              if (_isLoadingMore)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: CustomLoadingDots(size: 60)),
                                ),
                              // Show count indicator if there's more
                              if (hasMore && !_isLoadingMore)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 30),
                                  child: Center(
                                    child: Text(
                                      '${displayedUnits.length + displayedCompounds.length} / ${unitFavorites.length + compoundFavorites.length}',
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(height: 30),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 24),
          Text(
            l10n.noFavoritesYet,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 12),
          Text(
            l10n.startAddingCompounds,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
