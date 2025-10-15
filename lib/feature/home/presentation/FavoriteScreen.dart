import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: CustomText20('Favorites', bold: true, color: AppColors.black),
          bottom: TabBar(
            labelColor: AppColors.mainColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.mainColor,
            tabs: const [
              Tab(text: 'Compounds'),
              Tab(text: 'Units'),
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
    return BlocBuilder<CompoundFavoriteBloc, CompoundFavoriteState>(
      builder: (context, state) {
        if (state is CompoundFavoriteUpdated) {
          if (state.favorites.isEmpty) {
            return _buildEmptyState(
              icon: Icons.apartment,
              title: 'No favorite compounds',
              subtitle: 'Start adding compounds to your favorites!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.favorites.length,
            itemBuilder: (context, index) {
              final compound = state.favorites[index];
              return SizedBox(
                height: 500,
                child: CompoundsName(compound: compound),
              );
            },
          );
        } else if (state is CompoundFavoriteError) {
          return _buildErrorState(state.message);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildUnitsFavorites() {
    return BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
      builder: (context, state) {
        if (state is UnitFavoriteUpdated) {
          if (state.favorites.isEmpty) {
            return _buildEmptyState(
              icon: Icons.home,
              title: 'No favorite units',
              subtitle: 'Start adding units to your favorites from search!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.favorites.length,
            itemBuilder: (context, index) {
              final unit = state.favorites[index];
              return _buildUnitCard(context, unit);
            },
          );
        } else if (state is UnitFavoriteError) {
          return _buildErrorState(state.message);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildUnitCard(BuildContext context, Unit unit) {
    Color getStatusColor() {
      switch (unit.status.toLowerCase()) {
        case 'available':
          return Colors.green;
        case 'reserved':
          return Colors.orange;
        case 'sold':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitDetailScreen(unit: unit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with favorite button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: unit.images.isNotEmpty
                        ? Image.network(
                            unit.images.first,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.home, size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.home, size: 40, color: Colors.grey),
                          ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                      builder: (context, state) {
                        final bloc = context.read<UnitFavoriteBloc>();
                        final isFavorite = bloc.isFavorite(unit);

                        return GestureDetector(
                          onTap: () => bloc.toggleFavorite(unit),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Type & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            unit.usageType ?? unit.unitType ?? 'Unit',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unit.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Unit Number
                    if (unit.unitNumber != null && unit.unitNumber!.isNotEmpty)
                      Text(
                        'Unit #${unit.unitNumber}',
                        style: TextStyle(fontSize:12, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 8),
                    // Details
                    Row(
                      children: [
                        if (unit.bedrooms != null && unit.bedrooms.isNotEmpty && unit.bedrooms != '0') ...[
                          Icon(Icons.bed, size: 14, color: AppColors.mainColor),
                          const SizedBox(width: 4),
                          Text(
                            '${unit.bedrooms} Beds',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (unit.area != null && unit.area.isNotEmpty && unit.area != '0') ...[
                          Icon(Icons.straighten, size: 14, color: AppColors.mainColor),
                          const SizedBox(width: 4),
                          Text(
                            '${unit.area} m²',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      'EGP ${unit.price}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading favorites',
            style: TextStyle(
              fontSize: 20,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
