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
    print('🏠 Has original unit: ${product.originalUnit != null}');

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

        // Use original Unit if available, otherwise convert from product
        final unit = product.originalUnit is Unit
            ? product.originalUnit as Unit
            : _toUnitModel();
        print('✅ Using ${product.originalUnit is Unit ? "original" : "converted"} unit: ${unit.id}');

        return BlocProvider.value(
          value: unitBloc,
          child: UnitCard(
            unit: unit,
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
        final unit = product.originalUnit is Unit
            ? product.originalUnit as Unit
            : _toUnitModel();
        return UnitCard(
          unit: unit,
        );
      }
    }
  }
}
