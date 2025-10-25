import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import '../home/presentation/web_home_screen.dart';
import '../compounds/presentation/web_compounds_screen.dart';
import '../favorites/presentation/web_favorites_screen.dart';
import '../history/presentation/web_history_screen.dart';
import '../profile/presentation/web_profile_screen.dart';
import '../../../feature/search/data/repositories/search_repository.dart';
import '../../../feature/search/presentation/bloc/search_bloc.dart';
import '../../../feature/search/presentation/bloc/search_event.dart';
import '../../../feature/search/presentation/bloc/search_state.dart';
import '../../../feature/search/data/models/search_result_model.dart';
import '../../../feature/company/data/models/company_model.dart';
import '../../../feature/compound/data/models/compound_model.dart';
import '../../../feature/compound/data/models/unit_model.dart';
import '../../../feature/compound/presentation/screen/unit_detail_screen.dart';
import '../../../feature/company/presentation/web_company_detail_screen.dart';
import '../../../feature/home/presentation/CompoundScreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WebMainScreen extends StatefulWidget {
  static String routeName = '/web-main';

  WebMainScreen({Key? key}) : super(key: key);

  @override
  State<WebMainScreen> createState() => _WebMainScreenState();
}

class _WebMainScreenState extends State<WebMainScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchBloc _searchBloc;
  Timer? _debounceTimer;
  bool _showSearchResults = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final List<Widget> _screens = [
    WebHomeScreen(),
    WebCompoundsScreen(),
    WebFavoritesScreen(),
    WebHistoryScreen(),
    WebProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc(repository: SearchRepository());

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _hideSearchOverlay();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchBloc.close();
    _debounceTimer?.cancel();
    _hideSearchOverlay();
    super.dispose();
  }

  void _performSearch(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _searchBloc.add(ClearSearchEvent());
      _hideSearchOverlay();
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchBloc.add(SearchQueryEvent(query: query.trim()));
      _showSearchOverlay();
    });
  }

  void _showSearchOverlay() {
    _hideSearchOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSearchResults = true);
  }

  void _hideSearchOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showSearchResults = false);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchBloc.add(ClearSearchEvent());
    _hideSearchOverlay();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavBar(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE6E6E6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                // Logo
                Text(
                  '🏘️',
                  style: TextStyle(fontSize: 28),
                ),
                SizedBox(width: 8),
                Text(
                  'Real Estate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainColor,
                  ),
                ),
                SizedBox(width: 32),

                // Search Bar
                Expanded(
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 500),
                      height: 42,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search for companies, compounds, or units...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E8E),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.mainColor,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFFE6E6E6),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFFE6E6E6),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.mainColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 32),

                // Navigation Links
                _buildNavItem('Home', 0, Icons.home_outlined, Icons.home),
                SizedBox(width: 24),
                _buildNavItem('Compounds', 1, Icons.apartment_outlined, Icons.apartment),
                SizedBox(width: 24),
                _buildNavItem('Favorites', 2, Icons.favorite_border, Icons.favorite),
                SizedBox(width: 24),
                _buildNavItem('History', 3, Icons.history_outlined, Icons.history),
                SizedBox(width: 24),
                _buildNavItem('Profile', 4, Icons.person_outline, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, int index, IconData outlinedIcon, IconData filledIcon) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 20,
              color: isSelected ? AppColors.mainColor : Color(0xFF666666),
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.mainColor : Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 500,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFE6E6E6)),
              ),
              child: BlocBuilder<SearchBloc, SearchState>(
                bloc: _searchBloc,
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return Container(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (state is SearchSuccess) {
                    return _buildSearchResultsList(state.response);
                  } else if (state is SearchError) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        state.message,
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(SearchResponse response) {
    final results = response.results;
    final companies = results.where((r) => r.type == 'company').toList();
    final compounds = results.where((r) => r.type == 'compound').toList();
    final units = results.where((r) => r.type == 'unit').toList();

    if (results.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.all(12),
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Found ${response.totalResults} result${response.totalResults == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainColor,
                ),
              ),
              TextButton(
                onPressed: _clearSearch,
                child: Text('Close', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        Divider(height: 1),

        // Companies section
        if (companies.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Text(
              'Companies (${companies.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ...companies.map((result) => _buildCompanyResultItem(result)),
        ],

        // Compounds section
        if (compounds.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Text(
              'Compounds (${compounds.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ...compounds.map((result) => _buildCompoundResultItem(result)),
        ],

        // Units section
        if (units.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Text(
              'Units (${units.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ...units.map((result) => _buildUnitResultItem(result)),
        ],
      ],
    );
  }

  Widget _buildCompanyResultItem(SearchResult result) {
    final data = result.data as CompanySearchData;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppColors.mainColor.withOpacity(0.1),
        radius: 20,
        child: Icon(Icons.business, color: AppColors.mainColor, size: 20),
      ),
      title: Text(
        data.name,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        data.description ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, size: 18),
      onTap: () {
        _clearSearch();
        final company = Company(
          id: data.id,
          name: data.name,
          email: data.email,
          logo: data.logo,
          description: data.description,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebCompanyDetailScreen(company: company),
          ),
        );
      },
    );
  }

  Widget _buildCompoundResultItem(SearchResult result) {
    final data = result.data as CompoundSearchData;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppColors.mainColor.withOpacity(0.1),
        radius: 20,
        child: Icon(Icons.apartment, color: AppColors.mainColor, size: 20),
      ),
      title: Text(
        data.name,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        data.location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, size: 18),
      onTap: () {
        _clearSearch();
        final compound = Compound(
          id: data.id,
          companyId: data.company.id,
          project: data.name,
          location: data.location,
          totalUnits: data.totalUnits.toString(),
          availableUnits: data.availableUnits.toString(),
          status: data.status,
          companyName: data.company.name,
          images: data.images ?? [],
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompoundScreen(compound: compound),
          ),
        );
      },
    );
  }

  Widget _buildUnitResultItem(SearchResult result) {
    final data = result.data as UnitSearchData;

    Color getStatusColor() {
      switch (data.status.toLowerCase()) {
        case 'available':
          return Colors.green;
        case 'sold':
          return Colors.red;
        case 'reserved':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppColors.mainColor.withOpacity(0.1),
        radius: 20,
        child: Icon(Icons.home, color: AppColors.mainColor, size: 20),
      ),
      title: Row(
        children: [
          Text(
            data.unitNumber ?? data.unitType,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              data.status,
              style: TextStyle(
                fontSize: 10,
                color: getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${data.unitType} • ${data.compound.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${data.price.toInt()} EGP',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.mainColor,
        ),
      ),
      onTap: () {
        _clearSearch();
        final unit = Unit(
          id: data.id,
          compoundId: data.compound.id,
          unitType: data.unitType,
          area: data.area.toString(),
          price: data.price.toString(),
          status: data.status,
          unitNumber: data.unitNumber,
          numberOfBeds: data.numberOfBeds,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitDetailScreen(unit: unit),
          ),
        );
      },
    );
  }
}
