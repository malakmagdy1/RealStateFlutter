import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import '../../../feature_web/widgets/web_compound_card.dart';
import '../../../feature_web/widgets/web_unit_card.dart';

class WebFavoritesScreen extends StatelessWidget {
  WebFavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
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

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display Unit Favorites
                              if (unitFavorites.isNotEmpty) ...[
                                Text(
                                  '${l10n.favoriteProperties} (${unitFavorites.length})',
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
                                  itemCount: unitFavorites.length,
                                  itemBuilder: (context, index) {
                                    return WebUnitCard(
                                      unit: unitFavorites[index],
                                    );
                                  },
                                ),
                                SizedBox(height: 40),
                              ],
                              // Display Compound Favorites
                              if (compoundFavorites.isNotEmpty) ...[
                                Text(
                                  '${l10n.favoriteCompounds} (${compoundFavorites.length})',
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
                                  itemCount: compoundFavorites.length,
                                  itemBuilder: (context, index) {
                                    return WebCompoundCard(
                                      compound: compoundFavorites[index],
                                    );
                                  },
                                ),
                                SizedBox(height: 40),
                              ],
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
