import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'web_unit_card.dart';
import 'web_compound_card.dart';

/// Web-optimized widget that displays a property card in the chat
class WebPropertyCardWidget extends StatelessWidget {
  final Unit? unit;
  final Compound? compound;

  const WebPropertyCardWidget({
    super.key,
    this.unit,
    this.compound,
  }) : assert(unit != null || compound != null, 'Either unit or compound must be provided');

  @override
  Widget build(BuildContext context) {
    print('🏠 WebPropertyCardWidget building');
    print('🏠 Has unit: ${unit != null}, Has compound: ${compound != null}');

    try {
      // Wrap cards with necessary BLoC providers for icons to work
      if (compound != null) {
        final compoundBloc = context.read<CompoundFavoriteBloc>();
        print('✅ CompoundFavoriteBloc found in context');
        print('✅ Using database compound: ${compound!.id}');

        return BlocProvider.value(
          value: compoundBloc,
          child: WebCompoundCard(
            compound: compound!,
          ),
        );
      } else if (unit != null) {
        // Use web unit card
        final unitBloc = context.read<UnitFavoriteBloc>();
        print('✅ UnitFavoriteBloc found in context');
        print('✅ Using database unit: ${unit!.id}');

        return BlocProvider.value(
          value: unitBloc,
          child: WebUnitCard(
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
      print('❌ Error accessing BLoC in WebPropertyCardWidget: $e');
      // Return card without favorite functionality if BLoC not available
      if (compound != null) {
        return WebCompoundCard(
          compound: compound!,
        );
      } else if (unit != null) {
        return WebUnitCard(
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
