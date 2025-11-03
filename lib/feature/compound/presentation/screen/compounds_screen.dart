import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/core/animations/page_transitions.dart';

// Simple filter class to track filter state
class CompoundFilter {
  String? location;
  String? priceRange;

  int get activeFiltersCount {
    int count = 0;
    if (location != null && location!.isNotEmpty) count++;
    if (priceRange != null && priceRange!.isNotEmpty) count++;
    return count;
  }

  bool get isEmpty => activeFiltersCount == 0;
}

class CompoundsScreen extends StatefulWidget {
  static String routeName = '/compounds';

  CompoundsScreen({Key? key}) : super(key: key);

  @override
  State<CompoundsScreen> createState() => _CompoundsScreenState();
}

class _CompoundsScreenState extends State<CompoundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();

  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'location'
  bool _showAllAvailableCompounds = false;
  CompoundFilter _currentFilter = CompoundFilter();

  @override
  void initState() {
    super.initState();
    // Fetch compounds when screen loads
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _openFilterBottomSheet() {
    // TODO: Implement filter bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter feature coming soon!')),
    );
  }

  List<Compound> _filterAndSortCompounds(List<Compound> compounds) {
    // Filter by search query
    List<Compound> filtered = compounds;
    if (_searchQuery.isNotEmpty) {
      filtered = compounds.where((compound) {
        return compound.project.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            compound.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'location':
          return a.location.toLowerCase().compareTo(b.location.toLowerCase());
        case 'name':
        default:
          return a.project.toLowerCase().compareTo(b.project.toLowerCase());
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Header with Back Button and Title
          Container(
            padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
            color: AppColors.white,
            child: Column(
              children: [

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        key: _searchKey,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            setState(() {
                              _performSearch(value);
                            });
                          },
                          decoration: InputDecoration(
                            hintText: l10n.searchFor,
                            hintStyle: TextStyle(color: AppColors.greyText),
                            prefixIcon: Icon(Icons.search, color: AppColors.greyText),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.greyText),
                              onPressed: _clearSearch,
                            )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Filter button with badge
                    Stack(
                      key: _filterKey,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _currentFilter.isEmpty
                                ? Colors.grey.shade200
                                : AppColors.mainColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.filter_list,
                              color: _currentFilter.isEmpty
                                  ? Colors.grey
                                  : AppColors.mainColor,
                            ),
                            onPressed: _openFilterBottomSheet,
                          ),
                        ),
                        if (_currentFilter.activeFiltersCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  '${_currentFilter.activeFiltersCount}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Compounds List
          Expanded(
            child: BlocBuilder<CompoundBloc, CompoundState>(
              builder: (context, state) {
                if (state is CompoundLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CompoundError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CompoundBloc>().add(
                              FetchCompoundsEvent(page: 1, limit: 100),
                            );
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CompoundSuccess) {
                  final allCompounds = state.response.data;
                  final filteredCompounds = _filterAndSortCompounds(allCompounds);

                  if (filteredCompounds.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No compounds found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Determine how many to show
                  final displayCompounds = _showAllAvailableCompounds
                      ? filteredCompounds
                      : filteredCompounds.take(3).toList();

                  return Column(
                    children: [
                      // Header with count and toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText20(
                              '${l10n.availableCompounds} (${filteredCompounds.length})',
                            ),
                            if (filteredCompounds.length > 3)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAllAvailableCompounds = !_showAllAvailableCompounds;
                                  });
                                },
                                icon: Icon(
                                  _showAllAvailableCompounds
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 18,
                                  color: AppColors.mainColor,
                                ),
                                label: Text(
                                  _showAllAvailableCompounds
                                      ? l10n.showLess
                                      : l10n.showAll,
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Compounds Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: displayCompounds.length,
                          itemBuilder: (context, index) {
                            final compound = displayCompounds[index];
                            return AnimatedListItem(
                              index: index,
                              child: _buildCompoundCard(compound),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompoundCard(Compound compound) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadePageRoute(
            page: CompoundScreen(
              compound: compound,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: RobustNetworkImage(
                  imageUrl: compound.images.isNotEmpty ? compound.images.first : '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    compound.project,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          compound.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  }
}
