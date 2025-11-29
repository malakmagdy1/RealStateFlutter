import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';

/// Widget that displays a property card in the chat using existing app cards
class PropertyCardWidget extends StatelessWidget {
  final Unit? unit;
  final Compound? compound;

  const PropertyCardWidget({
    super.key,
    this.unit,
    this.compound,
  }) : assert(unit != null || compound != null, 'Either unit or compound must be provided');

  @override
  Widget build(BuildContext context) {
    print('🏠 PropertyCardWidget building');
    try {
      // Wrap cards with necessary BLoC providers for icons to work
      if (compound != null) {
        final compoundBloc = context.read<CompoundFavoriteBloc>();
        print('✅ CompoundFavoriteBloc found in context');

        return BlocProvider.value(
          value: compoundBloc,
          child: CompoundsName(
            compound: compound!,
            showRecommendedBadge: true,
          ),
        );
      } else if (unit != null) {
        // Use unit card
        final unitBloc = context.read<UnitFavoriteBloc>();
        print('✅ UnitFavoriteBloc found in context');
        print('✅ Using database unit: ${unit!.id}');

        return BlocProvider.value(
          value: unitBloc,
          child: UnitCard(
            unit: unit!,
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Text('No property data available'),
        );
      }
    } catch (e) {
      print('❌ Error accessing BLoC in PropertyCardWidget: $e');
      // Return card without favorite functionality if BLoC not available
      if (compound != null) {
        return CompoundsName(
          compound: compound!,
          showRecommendedBadge: true,
        );
      } else if (unit != null) {
        return UnitCard(
          unit: unit!,
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Text('No property data available'),
        );
      }
    }
  }
}
