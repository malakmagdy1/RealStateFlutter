import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/real_estate_product.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';

/// Widget that displays a property card in the chat using existing app cards
class PropertyCardWidget extends StatelessWidget {
  final RealEstateProduct product;

  const PropertyCardWidget({
    super.key,
    required this.product,
  });

  /// Convert AI product to Unit model
  Unit _toUnitModel() {
    return Unit(
      id: (product.id ?? 0).toString(),
      compoundId: '0',
      unitType: product.propertyType,
      area: product.area ?? '0',
      price: product.price.replaceAll(',', '').replaceAll(' EGP', ''),
      bedrooms: product.bedrooms ?? '0',
      bathrooms: product.bathrooms ?? '0',
      floor: '0',
      status: 'Available',
      unitNumber: product.name,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      images: product.imagePath != null ? [product.imagePath!] : [],
      usageType: product.propertyType,
      companyName: 'AI Recommendation',
      companyLogo: null,
      companyId: '0',
      compoundName: product.location,
      code: 'AI-${DateTime.now().millisecondsSinceEpoch}',
      builtUpArea: product.area ?? '0',
      landArea: '0',
      gardenArea: '0',
      roofArea: '0',
      available: true,
      isSold: false,
      notes: product.description,
      noteId: null,
    );
  }

  /// Convert AI product to Compound model
  Compound _toCompoundModel() {
    return Compound(
      id: (product.id ?? 0).toString(),
      companyId: '0',
      project: product.name,
      location: product.location,
      images: product.imagePath != null ? [product.imagePath!] : [],
      builtUpArea: '0',
      howManyFloors: '0',
      completionProgress: null,
      club: '0',
      isSold: '0',
      status: 'in_progress',
      totalUnits: '0',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      companyName: 'AI Recommendation',
      companyLogo: null,
      soldUnits: '0',
      availableUnits: '0',
      sales: [],
      notes: product.description,
      noteId: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 PropertyCardWidget building for type: ${product.type}');

    try {
      // Wrap cards with necessary BLoC providers for icons to work
      if (product.type == 'compound') {
        final compoundBloc = context.read<CompoundFavoriteBloc>();
        print('✅ CompoundFavoriteBloc found in context');

        return BlocProvider.value(
          value: compoundBloc,
          child: CompoundsName(
            compound: _toCompoundModel(),
            showRecommendedBadge: true,
          ),
        );
      } else {
        // Default to unit card
        final unitBloc = context.read<UnitFavoriteBloc>();
        print('✅ UnitFavoriteBloc found in context');

        return BlocProvider.value(
          value: unitBloc,
          child: UnitCard(
            unit: _toUnitModel(),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accessing BLoC in PropertyCardWidget: $e');
      // Return card without favorite functionality if BLoC not available
      if (product.type == 'compound') {
        return CompoundsName(
          compound: _toCompoundModel(),
          showRecommendedBadge: true,
        );
      } else {
        return UnitCard(
          unit: _toUnitModel(),
        );
      }
    }
  }

  Widget _buildImageHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Placeholder icon when no image
          Center(
            child: Icon(
              product.type == 'compound' ? Icons.apartment : Icons.home,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Type badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.type == 'compound' ? 'Compound' : 'Unit',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsRow() {
    final specs = <Map<String, String>>[];

    if (product.area != null && product.area!.isNotEmpty) {
      specs.add({'icon': '📏', 'value': '${product.area} sqm'});
    }
    if (product.bedrooms != null && product.bedrooms!.isNotEmpty) {
      specs.add({'icon': '🛏️', 'value': '${product.bedrooms} BR'});
    }
    if (product.bathrooms != null && product.bathrooms!.isNotEmpty) {
      specs.add({'icon': '🚿', 'value': '${product.bathrooms} BA'});
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: specs.map((spec) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(spec['icon']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                spec['value']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    feature,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
