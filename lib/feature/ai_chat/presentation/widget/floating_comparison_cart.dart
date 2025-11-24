import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../data/models/comparison_item.dart';
import '../../data/services/comparison_list_service.dart';
import '../screen/unified_ai_chat_screen.dart';

/// 🛒 Floating Comparison Cart Widget
/// Shows at the bottom of the screen when items are in the comparison list
/// Allows users to see selected items and start AI comparison
class FloatingComparisonCart extends StatefulWidget {
  final bool isWeb;

  const FloatingComparisonCart({
    Key? key,
    this.isWeb = false,
  }) : super(key: key);

  @override
  State<FloatingComparisonCart> createState() => _FloatingComparisonCartState();
}

class _FloatingComparisonCartState extends State<FloatingComparisonCart> with SingleTickerProviderStateMixin {
  final ComparisonListService _comparisonService = ComparisonListService();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Listen to comparison list changes
    _comparisonService.addListener(_onComparisonListChanged);

    // Show cart if there are items
    if (_comparisonService.isNotEmpty) {
      _animationController.forward();
    }
  }

  void _onComparisonListChanged() {
    if (_comparisonService.isNotEmpty && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (_comparisonService.isEmpty && _animationController.isCompleted) {
      _animationController.reverse();
      setState(() {
        _isExpanded = false;
      });
    } else {
      setState(() {}); // Rebuild to show updated count
    }
  }

  @override
  void dispose() {
    _comparisonService.removeListener(_onComparisonListChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _removeItem(ComparisonItem item) {
    _comparisonService.removeItem(item);
  }

  void _startComparison() {
    final items = _comparisonService.getItems();

    if (items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectAtLeast2Items),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Clear the list after getting items
    _comparisonService.clear();

    // Navigate to AI Chat
    if (widget.isWeb) {
      // Web navigation using GoRouter
      context.push('/ai-chat', extra: {
        'comparison_items': items,
      });
    } else {
      // Mobile navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedAIChatScreen(
            comparisonItems: items,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Comparison list UI is hidden - always return empty widget
    return SizedBox.shrink();
  }

  String _getItemSubtitle(ComparisonItem item) {
    if (item.type == 'unit') {
      final parts = <String>[];
      if (item.data['area'] != null) parts.add('${item.data['area']} m²');
      if (item.data['price'] != null) parts.add('${_formatPrice(item.data['price'])} EGP');
      if (item.data['bedrooms'] != null) parts.add('${item.data['bedrooms']} beds');
      return parts.join(' • ');
    } else if (item.type == 'compound') {
      final parts = <String>[];
      if (item.data['location'] != null) parts.add(item.data['location']);
      if (item.data['company_name'] != null) parts.add(item.data['company_name']);
      return parts.join(' • ');
    } else if (item.type == 'company') {
      final parts = <String>[];
      if (item.data['number_of_compounds'] != null) parts.add('${item.data['number_of_compounds']} compounds');
      if (item.data['number_of_units'] != null) parts.add('${item.data['number_of_units']} units');
      return parts.join(' • ');
    }
    return item.type;
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    try {
      final numPrice = double.parse(price.toString());
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(1)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return price.toString();
    }
  }
}
