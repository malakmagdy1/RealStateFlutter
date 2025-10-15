import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import '../../../../core/widget/button/showAll.dart';
import '../../data/models/compound_model.dart';
import '../bloc/unit/unit_bloc.dart';
import '../bloc/unit/unit_event.dart';
import '../bloc/unit/unit_state.dart';
import '../widget/unit_card.dart';

class AllUnitsScreen extends StatefulWidget {
  static const String routeName = '/all-units';
  final Compound compound;

  const AllUnitsScreen({Key? key, required this.compound, required int compoundId})
      : super(key: key);

  @override
  State<AllUnitsScreen> createState() => _AllUnitsScreenState();
}

class _AllUnitsScreenState extends State<AllUnitsScreen> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    context.read<UnitBloc>().add(FetchUnitsEvent(compoundId: widget.compound.id, limit: 1000));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: CustomText18(
          'All Units - ${widget.compound.project}',
          color: Colors.white,
        ),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
      ),
      body: BlocBuilder<UnitBloc, UnitState>(
        builder: (context, state) {
          if (state is UnitLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UnitSuccess) {
            if (state.response.data.isEmpty) {
              return _emptyState();
            }

            final units = state.response.data;
            final displayList = _showAll
                ? units
                : units.take(units.length > 5 ? 5 : units.length).toList();

            return Column(
              children: [
                _headerSection(state.response.count, state.response.total),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayList.length + (_showAll ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index < displayList.length) {
                        return UnitCard(unit: displayList[index]);
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ShowAllButton(
                            label: 'Show All Units',
                            pressed: () => setState(() => _showAll = true),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          } else if (state is UnitError) {
            return _errorState(state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _headerSection(int count, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.mainColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.mainColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText16(
              'Found $count units (Total: $total)',
              bold: true,
              color: AppColors.mainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: AppColors.grey),
          const SizedBox(height: 16),
          CustomText18('No units available', bold: true, color: AppColors.grey),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.grey),
            const SizedBox(height: 16),
            CustomText18('Error loading units', bold: true, color: AppColors.grey),
            const SizedBox(height: 8),
            CustomText16(message, align: TextAlign.center, color: AppColors.grey),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<UnitBloc>().add(
                  FetchUnitsEvent(compoundId: widget.compound.id, limit: 1000),
                );
              },
              icon: const Icon(Icons.refresh),
              label: CustomText16('Retry', color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//jir-7104-75