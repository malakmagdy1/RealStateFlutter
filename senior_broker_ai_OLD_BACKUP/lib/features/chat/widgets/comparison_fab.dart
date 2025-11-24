import 'package:flutter/material.dart';

/// 🔄 Comparison Floating Action Button
/// Quick access to property comparison feature
class ComparisonFab extends StatefulWidget {
  final VoidCallback onCompare;
  final int itemCount;
  
  const ComparisonFab({
    super.key,
    required this.onCompare,
    this.itemCount = 0,
  });

  @override
  State<ComparisonFab> createState() => _ComparisonFabState();
}

class _ComparisonFabState extends State<ComparisonFab> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          _controller.forward().then((_) => _controller.reverse());
          widget.onCompare();
        },
        backgroundColor: const Color(0xFF1E3A5F),
        icon: Stack(
          children: [
            const Icon(Icons.compare_arrows_rounded),
            if (widget.itemCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${widget.itemCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        label: Text(isArabic ? 'مقارنة' : 'Compare'),
      ),
    );
  }
}

/// 📊 Comparison Selection Bottom Sheet
class ComparisonSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> availableUnits;
  final Function(List<Map<String, dynamic>>) onCompare;
  
  const ComparisonSelectionSheet({
    super.key,
    required this.availableUnits,
    required this.onCompare,
  });

  @override
  State<ComparisonSelectionSheet> createState() => _ComparisonSelectionSheetState();
}

class _ComparisonSelectionSheetState extends State<ComparisonSelectionSheet> {
  final Set<int> _selectedIndices = {};
  
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'اختر للمقارنة' : 'Select to Compare',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isArabic 
                                ? 'اختر 2-4 وحدات للمقارنة'
                                : 'Select 2-4 units to compare',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selected count badge
                    if (_selectedIndices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedIndices.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Units list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.availableUnits.length,
                  itemBuilder: (context, index) {
                    final unit = widget.availableUnits[index];
                    final isSelected = _selectedIndices.contains(index);
                    
                    return _buildUnitCard(unit, index, isSelected, isArabic);
                  },
                ),
              ),
              // Compare button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedIndices.length >= 2
                          ? () {
                              final selectedUnits = _selectedIndices
                                  .map((i) => widget.availableUnits[i])
                                  .toList();
                              widget.onCompare(selectedUnits);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isArabic 
                            ? 'مقارنة (${_selectedIndices.length})'
                            : 'Compare (${_selectedIndices.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnitCard(
    Map<String, dynamic> unit,
    int index,
    bool isSelected,
    bool isArabic,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIndices.remove(index);
          } else if (_selectedIndices.length < 4) {
            _selectedIndices.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1E3A5F).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1E3A5F)
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? const Color(0xFF1E3A5F)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF1E3A5F)
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Unit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit['name'] ?? 'Unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (unit['price'] != null) ...[
                        Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                        Text(
                          '${unit['price']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (unit['area'] != null) ...[
                        Icon(Icons.square_foot, size: 14, color: Colors.grey[600]),
                        Text(
                          '${unit['area']} m²',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                  if (unit['location'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            unit['location'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
