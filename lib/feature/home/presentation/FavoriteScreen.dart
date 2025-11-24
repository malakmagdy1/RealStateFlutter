import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/utils/card_dimensions.dart';

class FavoriteScreen extends StatefulWidget {
  FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {

  @override
  void initState() {
    super.initState();
    // Load favorites when screen is opened
    print('[FAVORITE SCREEN] Loading favorites on init');
    context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
    context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: CustomText20(l10n.favorites, bold: true, color: AppColors.black),
          bottom: TabBar(
            labelColor: AppColors.mainColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.mainColor,
            tabs: [
              Tab(text: l10n.compounds),
              Tab(text: l10n.units),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCompoundsFavorites(),
            _buildUnitsFavorites(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompoundsFavorites() {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
      builder: (context, state) {
        if (state is CompoundFavoriteUpdated) {
          if (state.favorites.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
                // Wait a bit for the bloc to process
                await Future.delayed(Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apartment, size: 80, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text(
                          'No favorite compounds',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start adding compounds to your favorites!',
                          style: TextStyle(fontSize: 14, color: AppColors.greyText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Vertical grid layout with refresh
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
              await Future.delayed(Duration(milliseconds: 500));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomText20(
                    '${l10n.compounds} (${state.favorites.length})',
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 120, // Extra space at bottom for AI button and card visibility
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.63,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.favorites.length,
                    itemBuilder: (context, index) {
                      final compound = state.favorites[index];
                      return AnimatedListItem(
                        index: index,
                        child: CompoundsName(compound: compound),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (state is CompoundFavoriteError) {
          return _buildErrorState(state.message);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildUnitsFavorites() {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
      builder: (context, state) {
        if (state is UnitFavoriteUpdated) {
          if (state.favorites.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
                await Future.delayed(Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, size: 80, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text(
                          'No favorite units',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start adding units to your favorites!',
                          style: TextStyle(fontSize: 14, color: AppColors.greyText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Vertical grid layout with refresh
          return RefreshIndicator(
            onRefresh: () async {
              context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
              await Future.delayed(Duration(milliseconds: 500));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomText20(
                    '${l10n.units} (${state.favorites.length})',
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 120, // Extra space at bottom for AI button and card visibility
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.63,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.favorites.length,
                    itemBuilder: (context, index) {
                      final unit = state.favorites[index];
                      return AnimatedListItem(
                        index: index,
                        child: UnitCard(unit: unit),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (state is UnitFavoriteError) {
          return _buildErrorState(state.message);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          SizedBox(height: 16),
          Text(
            'Error loading favorites',
            style: TextStyle(
              fontSize: 20,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: AppColors.greyText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
