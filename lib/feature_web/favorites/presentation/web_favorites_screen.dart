import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import '../../../feature_web/widgets/web_compound_card.dart';

class WebFavoritesScreen extends StatelessWidget {
  WebFavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 32,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'My Favorites',
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
                  'Your saved compounds and properties',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 48),
                Expanded(
                  child: BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
                    builder: (context, state) {
                      if (state is CompoundFavoriteUpdated) {
                        if (state.favorites.isEmpty) {
                          return _buildEmptyState();
                        }
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: state.favorites.length,
                          itemBuilder: (context, index) {
                            return WebCompoundCard(
                              compound: state.favorites[index],
                            );
                          },
                        );
                      } else if (state is CompoundFavoriteError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      return _buildEmptyState();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No favorites yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Start adding compounds to your favorites',
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
