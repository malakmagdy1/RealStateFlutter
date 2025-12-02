import 'package:real/feature/search/data/models/search_filter_model.dart';

/// Service to persist search and filter state across navigation
/// This allows the state to be preserved when navigating to detail screens and back
class WebSearchFilterStateService {
  // Singleton instance
  static final WebSearchFilterStateService _instance = WebSearchFilterStateService._internal();
  factory WebSearchFilterStateService() => _instance;
  WebSearchFilterStateService._internal();

  // Search state
  String? searchQuery;
  bool showSearchResults = false;

  // Filter state
  SearchFilter currentFilter = SearchFilter.empty();
  String? selectedLocation;
  String? selectedCompanyId;
  String? selectedPropertyType;
  int? selectedBedrooms;
  String? selectedFinishing;
  DateTime? deliveredAtFrom;
  DateTime? deliveredAtTo;
  bool? hasBeenDelivered;
  bool hasClub = false;
  bool hasRoof = false;
  bool hasGarden = false;
  String? selectedSortBy;

  // Payment plan filter state
  int? selectedPaymentDuration;
  String? minPrice;
  String? maxPrice;
  String? minMonthlyPayment;
  String? maxMonthlyPayment;

  // Pagination state
  int currentPage = 1;

  /// Save current state
  void saveState({
    String? searchQuery,
    bool? showSearchResults,
    SearchFilter? currentFilter,
    String? selectedLocation,
    String? selectedCompanyId,
    String? selectedPropertyType,
    int? selectedBedrooms,
    String? selectedFinishing,
    DateTime? deliveredAtFrom,
    DateTime? deliveredAtTo,
    bool? hasBeenDelivered,
    bool? hasClub,
    bool? hasRoof,
    bool? hasGarden,
    String? selectedSortBy,
    int? selectedPaymentDuration,
    String? minPrice,
    String? maxPrice,
    String? minMonthlyPayment,
    String? maxMonthlyPayment,
    int? currentPage,
  }) {
    if (searchQuery != null) this.searchQuery = searchQuery;
    if (showSearchResults != null) this.showSearchResults = showSearchResults;
    if (currentFilter != null) this.currentFilter = currentFilter;
    if (selectedLocation != null) this.selectedLocation = selectedLocation;
    if (selectedCompanyId != null) this.selectedCompanyId = selectedCompanyId;
    if (selectedPropertyType != null) this.selectedPropertyType = selectedPropertyType;
    if (selectedBedrooms != null) this.selectedBedrooms = selectedBedrooms;
    if (selectedFinishing != null) this.selectedFinishing = selectedFinishing;
    if (deliveredAtFrom != null) this.deliveredAtFrom = deliveredAtFrom;
    if (deliveredAtTo != null) this.deliveredAtTo = deliveredAtTo;
    if (hasBeenDelivered != null) this.hasBeenDelivered = hasBeenDelivered;
    if (hasClub != null) this.hasClub = hasClub;
    if (hasRoof != null) this.hasRoof = hasRoof;
    if (hasGarden != null) this.hasGarden = hasGarden;
    if (selectedSortBy != null) this.selectedSortBy = selectedSortBy;
    if (selectedPaymentDuration != null) this.selectedPaymentDuration = selectedPaymentDuration;
    if (minPrice != null) this.minPrice = minPrice;
    if (maxPrice != null) this.maxPrice = maxPrice;
    if (minMonthlyPayment != null) this.minMonthlyPayment = minMonthlyPayment;
    if (maxMonthlyPayment != null) this.maxMonthlyPayment = maxMonthlyPayment;
    if (currentPage != null) this.currentPage = currentPage;
  }

  /// Check if there is any saved state
  bool get hasState {
    return searchQuery != null && searchQuery!.isNotEmpty ||
           !currentFilter.isEmpty ||
           selectedLocation != null ||
           selectedCompanyId != null ||
           selectedPropertyType != null ||
           selectedBedrooms != null ||
           selectedFinishing != null;
  }

  /// Clear all saved state
  void clearState() {
    searchQuery = null;
    showSearchResults = false;
    currentFilter = SearchFilter.empty();
    selectedLocation = null;
    selectedCompanyId = null;
    selectedPropertyType = null;
    selectedBedrooms = null;
    selectedFinishing = null;
    deliveredAtFrom = null;
    deliveredAtTo = null;
    hasBeenDelivered = null;
    hasClub = false;
    hasRoof = false;
    hasGarden = false;
    selectedSortBy = null;
    selectedPaymentDuration = null;
    minPrice = null;
    maxPrice = null;
    minMonthlyPayment = null;
    maxMonthlyPayment = null;
    currentPage = 1;
  }
}
