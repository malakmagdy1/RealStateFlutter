import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widget/button/showAll.dart';
import '../../../../core/widget/robust_network_image.dart';
import '../../../compound/data/models/compound_model.dart';
import '../../../compound/presentation/bloc/unit/unit_bloc.dart';
import '../../../compound/presentation/bloc/unit/unit_event.dart';
import '../../../compound/presentation/bloc/unit/unit_state.dart';
import '../../../compound/presentation/screen/all_units_screen.dart';

class UnitName extends StatefulWidget {
  final int compoundId;
  final Compound compound;

  UnitName({super.key, required this.compoundId, required this.compound});

  @override
  State<UnitName> createState() => _UnitNameState();
}

class _UnitNameState extends State<UnitName> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    // Fetch units for this compound on init
    context.read<UnitBloc>().add(
      FetchUnitsEvent(compoundId: widget.compoundId.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitBloc, UnitState>(
      builder: (context, state) {
        if (state is UnitLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is UnitSuccess) {
          final units = state.response.data;

          if (units.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No units available for this compound',
                  style: TextStyle(fontSize: 16, color: AppColors.greyText),
                ),
              ),
            );
          }

          // ✅ Toggle between showing 5 or all units
          final displayUnits = _showAll ? units : units.take(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: displayUnits.length,
                itemBuilder: (context, index) {
                  final unit = displayUnits[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllUnitsScreen(
                            compoundId: widget.compoundId,
                            compound: widget.compound,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Image Section ---
                          if (unit.images.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: unit.images.length == 1
                                  ? RobustNetworkImage(
                                      imageUrl: unit.images.first,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context) => Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorBuilder: (context, url) {
                                        return Container(
                                          width: double.infinity,
                                          height: 200,
                                          color: Colors.grey.shade300,
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: AppColors.greyText,
                                          ),
                                        );
                                      },
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: unit.images.length,
                                      itemBuilder: (context, imgIndex) {
                                        return Container(
                                          width: 250,
                                          margin: EdgeInsets.only(
                                            left: imgIndex == 0 ? 0 : 4,
                                            right:
                                                imgIndex ==
                                                    unit.images.length - 1
                                                ? 0
                                                : 4,
                                          ),
                                          child: RobustNetworkImage(
                                            imageUrl: unit.images[imgIndex],
                                            width: 250,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context) => Container(
                                              color: Colors.grey.shade200,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorBuilder: (context, url) {
                                              return Container(
                                                color: Colors.grey.shade300,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: AppColors.greyText,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),

                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Header ---
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      unit.unitType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: unit.status == 'available'
                                            ? Colors.green
                                            : unit.status == 'reserved'
                                            ? Colors.orange
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unit.status.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (unit.unitNumber != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'Unit #${unit.unitNumber}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 16),

                                // --- Details ---
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildUnitDetail(
                                        icon: Icons.square_foot,
                                        label: 'Area',
                                        value: '${unit.area} m²',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildUnitDetail(
                                        icon: Icons.bed,
                                        label: 'Bedrooms',
                                        value: unit.bedrooms,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildUnitDetail(
                                        icon: Icons.bathroom,
                                        label: 'Bathrooms',
                                        value: unit.bathrooms,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildUnitDetail(
                                        icon: Icons.layers,
                                        label: 'Floor',
                                        value: unit.floor,
                                      ),
                                    ),
                                  ],
                                ),

                                if (unit.view != null ||
                                    unit.finishing != null) ...[
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (unit.view != null)
                                        Expanded(
                                          child: _buildUnitDetail(
                                            icon: Icons.visibility,
                                            label: 'View',
                                            value: unit.view!,
                                          ),
                                        ),
                                      if (unit.finishing != null)
                                        Expanded(
                                          child: _buildUnitDetail(
                                            icon: Icons.home_repair_service,
                                            label: 'Finishing',
                                            value: unit.finishing!,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],

                                SizedBox(height: 16),
                                Divider(),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Price',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'EGP ${_formatPrice(unit.price)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ✅ Show All button (toggle)
              if (units.length > 5) ...[
                SizedBox(height: 16),
                ShowAllButton(
                  label: _showAll ? 'Show Less' : 'Show All Units',
                  pressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                ),
              ],
            ],
          );
        } else if (state is UnitError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UnitBloc>().add(
                        FetchUnitsEvent(
                          compoundId: widget.compound.id.toString(),
                        ),
                      );
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox.shrink();
      },
    );
  }

  // 🧩 Helper widget for details
  Widget _buildUnitDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.greyText),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return price;
    }
  }
}
