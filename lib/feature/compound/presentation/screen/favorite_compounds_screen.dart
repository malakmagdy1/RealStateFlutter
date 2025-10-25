import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';

class FavoriteCompoundsScreen extends StatelessWidget {
  static String routeName = '/favorite-compounds';

  FavoriteCompoundsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText18('Favorite Compounds', color: AppColors.white),
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.white,
      ),
      body: BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
        builder: (context, state) {
          if (state is CompoundFavoriteUpdated) {
            if (state.favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: AppColors.grey,
                    ),
                    SizedBox(height: 16),
                    CustomText20(
                      'No favorites yet',
                      bold: true,
                      color: AppColors.grey,
                    ),
                    SizedBox(height: 8),
                    CustomText16(
                      'Start adding compounds to your favorites!',
                      color: AppColors.grey,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: state.favorites.length,
              itemBuilder: (context, index) {
                final compound = state.favorites[index];
                return SizedBox(
                  height: 220,
                  child: CompoundsName(compound: compound),
                );
              },
            );
          } else if (state is CompoundFavoriteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: AppColors.grey),
                  SizedBox(height: 16),
                  CustomText20(
                    'Error loading favorites',
                    bold: true,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 8),
                  CustomText16(
                    state.message,
                    align: TextAlign.center,
                    color: AppColors.grey,
                  ),
                ],
              ),
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
