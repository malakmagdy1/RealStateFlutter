import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../data/models/comparison_item.dart';

/// Bottom sheet for selecting items to compare
class ComparisonSelectionSheet extends StatefulWidget {
  final List<ComparisonItem> preSelectedItems;
  final Function(List<ComparisonItem>) onCompare;

  const ComparisonSelectionSheet({
    Key? key,
    this.preSelectedItems = const [],
    required this.onCompare,
  }) : super(key: key);

  @override
  State<ComparisonSelectionSheet> createState() => _ComparisonSelectionSheetState();

  static Future<void> show(
    BuildContext context, {
    List<ComparisonItem> preSelectedItems = const [],
    required Function(List<ComparisonItem>) onCompare,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComparisonSelectionSheet(
        preSelectedItems: preSelectedItems,
        onCompare: onCompare,
      ),
    );
  }
}

class _ComparisonSelectionSheetState extends State<ComparisonSelectionSheet> {
  late List<ComparisonItem> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.preSelectedItems);
  }

  void _removeItem(ComparisonItem item) {
    setState(() {
      _selectedItems.removeWhere((i) => i.id == item.id && i.type == item.type);
    });
  }

  void _addItem(ComparisonItem item) {
    setState(() {
      // Limit to 4 items for comparison
      if (_selectedItems.length < 4) {
        _selectedItems.add(item);
      }
    });
  }

  bool _isSelected(ComparisonItem item) {
    return _selectedItems.any((i) => i.id == item.id && i.type == item.type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                CustomText20(l10n.aiCompare, bold: true, color: AppColors.black),
                SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // Selected items display
          if (_selectedItems.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: AppColors.mainColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.compare_arrows, color: AppColors.mainColor),
                      SizedBox(width: 8),
                      CustomText16(
                        '${l10n.selectedForComparison} (${_selectedItems.length}/4)',
                        bold: true,
                        color: AppColors.mainColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedItems.map((item) {
                      return Chip(
                        avatar: Icon(
                          item.type == 'unit'
                              ? Icons.home
                              : item.type == 'compound'
                                  ? Icons.apartment
                                  : Icons.business,
                          size: 18,
                          color: AppColors.mainColor,
                        ),
                        label: Text(
                          item.name,
                          style: TextStyle(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () => _removeItem(item),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.compareInstructions,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedItems.length >= 2
                        ? () {
                            widget.onCompare(_selectedItems);
                            Navigator.pop(context);
                          }
                        : null,
                    icon: Icon(Icons.compare_arrows),
                    label: Text(l10n.compareWithAI),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mainColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.mainColor),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Tab info message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              l10n.toAddItemsForComparison,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(height: 8),

          // Quick access hints
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHintItem(l10n.searchUnitsAndCompare),
                _buildHintItem(l10n.viewCompoundAndCompare),
                _buildHintItem(l10n.browseCompaniesAndCompare),
              ],
            ),
          ),

          Spacer(),

          // Bottom action bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _selectedItems.length >= 2
                    ? () {
                        widget.onCompare(_selectedItems);
                        Navigator.pop(context);
                      }
                    : null,
                icon: Icon(Icons.smart_toy),
                label: Text(
                  _selectedItems.length >= 2
                      ? l10n.startAIComparisonChat
                      : l10n.selectAtLeast2Items,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
