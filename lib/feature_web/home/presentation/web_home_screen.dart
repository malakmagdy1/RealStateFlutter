import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';
import '../../../core/utils/text_style.dart';
import '../../company/presentation/web_company_detail_screen.dart';
import '../../../feature/compound/presentation/bloc/compound_bloc.dart';
import '../../../feature/compound/presentation/bloc/compound_event.dart';
import '../../../feature/compound/presentation/bloc/compound_state.dart';
import '../../widgets/web_company_logo.dart';
import '../../widgets/web_compound_card.dart';
import '../../widgets/web_unit_card.dart';
import '../../widgets/web_sale_slider.dart';
import '../../../feature/auth/presentation/bloc/user_bloc.dart';
import '../../../feature/auth/presentation/bloc/user_state.dart';
import '../../../feature/sale/presentation/bloc/sale_bloc.dart';
import '../../../feature/sale/presentation/bloc/sale_state.dart';
import '../../../l10n/app_localizations.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/core/animations/page_transitions.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/core/widgets/image_carousel_slider.dart';
import 'package:real/core/widgets/sale_carousel_slider.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/feature/ai_chat/presentation/widget/floating_comparison_cart.dart';

class WebHomeScreen extends StatefulWidget {
  static String routeName = '/web-home';

  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep the widget state alive when navigating away
  bool _showAllAvailableCompounds = false;

  // Recommended compounds pagination
  int _recommendedPage = 1;
  int _recommendedLimit = 9;
  bool _hasMoreRecommended = true;
  bool _isLoadingMoreRecommended = false;
  final ScrollController _recommendedScrollController = ScrollController();

  // Unit sections
  List<Unit> _newArrivals = [];
  List<Unit> _recentlyUpdated = [];
  List<Unit> _recommendedUnits = [];
  List<Unit> _updated24Hours = [];
  bool _isLoadingNewArrivals = false;
  bool _isLoadingRecentlyUpdated = false;
  bool _isLoadingRecommendedUnits = false;
  bool _isLoadingUpdated24Hours = false;
  final CompoundWebServices _webServices = CompoundWebServices();

  // Scroll controllers for unit sections
  final ScrollController _newArrivalsScrollController = ScrollController();
  final ScrollController _updated24HoursScrollController = ScrollController();
  final ScrollController _companiesScrollController = ScrollController();

  // Track if initial load is done and if we should show recommended
  bool _hasInitialized = false;
  bool _showRecommendedCompounds = true;

  @override
  void initState() {
    super.initState();

    // Setup scroll listener for recommended compounds - FIXED: Added debounce check
    _recommendedScrollController.addListener(_onRecommendedScroll);

    // Load initial data and favorites after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch data only once on initialization
      _refreshData();
      context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
      context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
    });
  }

  // FIXED: Added timestamp to prevent rapid re-triggering
  DateTime? _lastLoadMoreTime;

  void _onRecommendedScroll() {
    if (_isLoadingMoreRecommended || !_hasMoreRecommended) return;

    // FIXED: Debounce - prevent triggering more than once per second
    final now = DateTime.now();
    if (_lastLoadMoreTime != null &&
        now.difference(_lastLoadMoreTime!).inMilliseconds < 1000) {
      return;
    }

    // Check if scrolled near the end (80% of max scroll extent)
    if (_recommendedScrollController.hasClients &&
        _recommendedScrollController.position.maxScrollExtent > 0 &&
        _recommendedScrollController.position.pixels >=
            _recommendedScrollController.position.maxScrollExtent * 0.8) {
      _lastLoadMoreTime = now;
      _loadMoreRecommended();
    }
  }

  void _loadMoreRecommended() {
    if (_isLoadingMoreRecommended || !_hasMoreRecommended) return;

    setState(() {
      _isLoadingMoreRecommended = true;
    });

    // Load 5 more compounds
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _recommendedLimit += 5;
          _isLoadingMoreRecommended = false;
          // Update _hasMoreRecommended here to prevent infinite loop
          _hasMoreRecommended = true; // Will be checked on next scroll
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark as initialized and check if we need to load data
    if (!_hasInitialized) {
      _hasInitialized = true;

      // Check if BLoC has data, if not, fetch it
      final compoundState = context.read<CompoundBloc>().state;
      if (compoundState is! CompoundSuccess || compoundState.response.data.isEmpty) {
        print('[WEB HOME] No compound data found, fetching recommendations...');
        context.read<CompoundBloc>().add(FetchWeeklyRecommendedCompoundsEvent());
      } else {
        print('[WEB HOME] Compound data already loaded (${compoundState.response.data.length} compounds)');
      }
    }
  }

  /// Refresh all data on the home screen
  void _refreshData() {
    // Fetch companies and AI-recommended compounds
    context.read<CompanyBloc>().add(FetchCompaniesEvent());
    context.read<CompoundBloc>().add(FetchWeeklyRecommendedCompoundsEvent());

    // Fetch unit sections
    _fetchNewArrivals();
    _fetchUpdated24Hours();
  }

  @override
  void dispose() {
    _recommendedScrollController.removeListener(_onRecommendedScroll); // FIXED: Remove listener
    _recommendedScrollController.dispose();
    _newArrivalsScrollController.dispose();
    _updated24HoursScrollController.dispose();
    _companiesScrollController.dispose();
    super.dispose();
  }

  // Scroll recommended compounds to the left (4 containers)
  void _scrollRecommendedLeft() {
    final currentPosition = _recommendedScrollController.offset;
    final containerWidth = 260.0; // Unified width for all cards
    final spacing = 10.0; // Spacing between cards
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _recommendedScrollController.animateTo(
      currentPosition - scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll recommended compounds to the right (4 containers)
  void _scrollRecommendedRight() {
    final currentPosition = _recommendedScrollController.offset;
    final containerWidth = 260.0; // Unified width for all cards
    final spacing = 10.0; // Spacing between cards
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _recommendedScrollController.animateTo(
      currentPosition + scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll new arrivals to the left (4 containers)
  void _scrollNewArrivalsLeft() {
    final currentPosition = _newArrivalsScrollController.offset;
    final containerWidth = 260.0; // Width of each unit card
    final spacing = 10.0; // Spacing between cards
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _newArrivalsScrollController.animateTo(
      currentPosition - scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll new arrivals to the right (4 containers)
  void _scrollNewArrivalsRight() {
    final currentPosition = _newArrivalsScrollController.offset;
    final containerWidth = 260.0; // Width of each unit card
    final spacing = 10.0; // Spacing between cards
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _newArrivalsScrollController.animateTo(
      currentPosition + scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll updated 24 hours to the left (4 containers)
  void _scrollUpdated24HoursLeft() {
    final currentPosition = _updated24HoursScrollController.offset;
    final containerWidth = 260.0; // Width of each unit card
    final spacing = 10.0; // Spacing between cards
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _updated24HoursScrollController.animateTo(
      currentPosition - scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll updated 24 hours to the right (4 containers)
  void _scrollUpdated24HoursRight() {
    final currentPosition = _updated24HoursScrollController.offset;
    final containerWidth = 260.0; // Width of each unit card
    final spacing = 10.0; // Spacing between cards
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _updated24HoursScrollController.animateTo(
      currentPosition + scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll companies to the left (4 containers)
  void _scrollCompaniesLeft() {
    final currentPosition = _companiesScrollController.offset;
    final containerWidth = 120.0; // Width of each company logo
    final spacing = 16.0; // Spacing between logos
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _companiesScrollController.animateTo(
      currentPosition - scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Scroll companies to the right (4 containers)
  void _scrollCompaniesRight() {
    final currentPosition = _companiesScrollController.offset;
    final containerWidth = 120.0; // Width of each company logo
    final spacing = 16.0; // Spacing between logos
    final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

    _companiesScrollController.animateTo(
      currentPosition + scrollAmount,
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  // Get banner images for carousel
  List<String> _getBannerImages() {
    // TODO: Replace with actual banner images from your backend/API
    // For now, using placeholder images - you can update these URLs
    return [
      'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800',
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
      'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=800',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0), // FIXED: Added bottom padding for FloatingComparisonCart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        if (state is UserSuccess) {
                          return ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              "${l10n.welcome} ${state.user.name.split(' ').first}",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            l10n.welcome,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // Companies section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText20(l10n.companiesName),
                        // Navigation arrows
                        BlocBuilder<CompanyBloc, CompanyState>(
                          builder: (context, state) {
                            final showArrows = state is CompanySuccess && state.response.companies.isNotEmpty;
                            if (!showArrows) return SizedBox.shrink();

                            return Row(
                              children: [
                                // Left arrow
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _scrollCompaniesLeft,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.arrow_back_ios_new,
                                        color: AppColors.mainColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Right arrow
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _scrollCompaniesRight,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppColors.mainColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    BlocBuilder<CompanyBloc, CompanyState>(
                      builder: (context, state) {
                        if (state is CompanyLoading) {
                          return SizedBox(
                            height: 100,
                            child: Center(child: CustomLoadingDots(size: 80)),
                          );
                        }

                        else if (state is CompanySuccess) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SizedBox(
                              height: 100,
                              child: ListView.builder(
                                controller: _companiesScrollController,
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                itemCount: state.response.companies.length,
                                itemBuilder: (context, index) {
                                  final company = state.response.companies[index];

                                  return WebCompanyLogo(
                                    company: company,
                                    onTap: () async {
                                      // Navigate using go_router with company data
                                      await context.push(
                                        '/company/${company.id}',
                                        extra: company.toJson(),
                                      );

                                      // Check if context is still mounted before using it
                                      if (context.mounted) {
                                        context.read<CompoundBloc>().add(
                                            FetchWeeklyRecommendedCompoundsEvent()
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        else if (state is CompanyError) {
                          return SizedBox(
                            height: 100,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText16('Error: ${state.message}', color: Colors.red, align: TextAlign.center),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<CompanyBloc>().add(FetchCompaniesEvent());
                                    },
                                    child: CustomText16(l10n.retry, color: AppColors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SizedBox(height: 100);
                      },
                    ),
                    // Sales Carousel
                    BlocBuilder<SaleBloc, SaleState>(
                      builder: (context, state) {
                        if (state is SaleLoading) {
                          return SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: CustomLoadingDots(size: 80),
                              ),
                            ),
                          );
                        }

                        if (state is SaleError) {
                          // Show error with placeholder carousel
                          return ImageCarouselSlider(
                            images: _getBannerImages(),
                            height: 220,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 4),
                            autoPlayAnimationDuration: Duration(seconds: 2),
                          );
                        }

                        if (state is SaleSuccess) {
                          // Filter only currently active sales
                          final activeSales = state.response.sales
                              .where((sale) => sale.isCurrentlyActive)
                              .toList();

                          // If we have active sales, show them with sale carousel
                          if (activeSales.isNotEmpty) {
                            return SaleCarouselSlider(
                              sales: activeSales,
                              height: 220,
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 4),
                              autoPlayAnimationDuration: Duration(seconds: 2),
                              isWeb: true,
                            );
                          }
                        }

                        // Fallback to placeholder images
                        return ImageCarouselSlider(
                          images: _getBannerImages(),
                          height: 220,
                          autoPlay: true,
                          autoPlayInterval: Duration(seconds: 4),
                          autoPlayAnimationDuration: Duration(seconds: 2),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // 🔄 Updated Units (24h)
                    _buildWebUnitSection(
                      title: l10n.updatedInLast24Hours,
                      icon: Icons.history_toggle_off,
                      iconColor: Colors.teal,
                      gradientColors: [Colors.teal, Colors.tealAccent],
                      units: _updated24Hours,
                      isLoading: _isLoadingUpdated24Hours,
                      emptyMessage: l10n.noUnitsUpdatedLast24Hours,
                      scrollController: _updated24HoursScrollController,
                      onScrollLeft: _scrollUpdated24HoursLeft,
                      onScrollRight: _scrollUpdated24HoursRight,
                    ),
                    SizedBox(height: 16),

                    // 🆕 New Arrivals Section
                    _buildWebUnitSection(
                      title: l10n.newArrivals,
                      icon: Icons.fiber_new,
                      iconColor: Colors.teal,
                      gradientColors: [Colors.teal, Colors.tealAccent],
                      units: _newArrivals,
                      isLoading: _isLoadingNewArrivals,
                      emptyMessage: l10n.noNewArrivals,
                      scrollController: _newArrivalsScrollController,
                      onScrollLeft: _scrollNewArrivalsLeft,
                      onScrollRight: _scrollNewArrivalsRight,
                    ),
                    SizedBox(height: 16),
                    // Recommended Compounds Section (hidden when navigating back)
                    if (_showRecommendedCompounds)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                                  SizedBox(width: 12),
                                  CustomText20(
                                    l10n.recommendedCompounds,
                                    bold: true,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                              // Navigation arrows
                              Row(
                                children: [
                                  // Left arrow
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _scrollRecommendedLeft,
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_new,
                                          color: AppColors.mainColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Right arrow
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _scrollRecommendedRight,
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.mainColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                      ),

                    if (_showRecommendedCompounds)
                      BlocBuilder<CompoundBloc, CompoundState>(
                        builder: (context, state) {
                          if (state is CompoundLoading) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: CustomLoadingDots(size: 120),
                              ),
                            );
                          } else if (state is CompoundSuccess) {
                            if (state.response.data.isEmpty) {
                              return SizedBox(
                                height: 200,
                                child: Center(
                                  child: CustomText16(l10n.noCompoundsAvailable, color: AppColors.grey),
                                ),
                              );
                            }

                            final compoundsWithImages = state.response.data
                                .where((compound) => compound.images.isNotEmpty)
                                .toList();

                            final recommendedCompounds = compoundsWithImages.isNotEmpty
                                ? compoundsWithImages
                                : state.response.data;

                            final displayCount = recommendedCompounds.length > _recommendedLimit
                                ? _recommendedLimit
                                : recommendedCompounds.length;

                            final hasMore = recommendedCompounds.length > _recommendedLimit;

                            // REMOVED: This was causing infinite rebuild loop
                            // Update hasMoreRecommended state only when needed, not on every build

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: SizedBox(
                                height: 300,
                                child: ListView.builder(
                                  clipBehavior: Clip.none,
                                  controller: _recommendedScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(bottom: 20),
                                  itemCount: displayCount + (_isLoadingMoreRecommended && hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    // Show loading indicator at the end
                                    if (index == displayCount && _isLoadingMoreRecommended) {
                                      return Container(
                                        width: 250,
                                        margin: EdgeInsets.only(right: 10),
                                        child: Center(
                                          child: CustomLoadingDots(size: 80),
                                        ),
                                      );
                                    }

                                    final compound = recommendedCompounds[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index < displayCount - 1 ? 10 : 0,
                                      ),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            print('[WEB HOME] Compound tapped: ${compound.project}');
                                            context.push('/compound/${compound.id}');
                                          },
                                          child: SizedBox(
                                            width: 270,
                                            child: WebCompoundCard(compound: compound),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } else if (state is CompoundError) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomText16(
                                      'Error: ${state.message}',
                                      color: Colors.red,
                                      align: TextAlign.center,
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<CompoundBloc>().add(
                                          FetchWeeklyRecommendedCompoundsEvent(),
                                        );
                                      },
                                      child: CustomText16(l10n.retry, color: AppColors.white),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return SizedBox(height: 200);
                        },
                      ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        // FIXED: FloatingComparisonCart moved to Stack level (outside SingleChildScrollView)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingComparisonCart(isWeb: true),
        ),
      ],
    );
  }

  // Fetch new arrivals
  Future<void> _fetchNewArrivals() async {
    if (_isLoadingNewArrivals) return;

    setState(() {
      _isLoadingNewArrivals = true;
    });

    try {
      final response = await _webServices.getNewArrivals(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<Unit> units = [];

        // Check if data has nested 'data' property (pagination structure)
        if (data is Map && data['data'] != null) {
          units = (data['data'] as List)
              .map((unit) {
            final unitJson = Map<String, dynamic>.from(unit as Map<String, dynamic>);
            // Parse action as change_type if present
            if (unitJson['action'] != null) {
              print('[NEW ARRIVALS] Found action: ${unitJson['action']} for unit ${unitJson['id']}');
              unitJson['change_type'] = unitJson['action'];
              unitJson['is_updated'] = true;
            }
            return Unit.fromJson(unitJson);
          })
              .toList();
        } else if (data is List) {
          // Fallback: if data is directly a list
          units = data
              .map((unit) {
            final unitJson = Map<String, dynamic>.from(unit as Map<String, dynamic>);
            // Parse action as change_type if present
            if (unitJson['action'] != null) {
              unitJson['change_type'] = unitJson['action'];
              unitJson['is_updated'] = true;
            }
            return Unit.fromJson(unitJson);
          })
              .toList();
        }

        if (mounted) {
          setState(() {
            _newArrivals = units;
            _isLoadingNewArrivals = false;
          });
        }
      }
    } catch (e) {
      print('[WebHomeScreen] Error fetching new arrivals: $e');
      if (mounted) {
        setState(() {
          _isLoadingNewArrivals = false;
        });
      }
    }
  }


  // Fetch updated units (last 24 hours)
  Future<void> _fetchUpdated24Hours() async {
    if (_isLoadingUpdated24Hours) return;

    setState(() {
      _isLoadingUpdated24Hours = true;
    });

    try {
      final response = await _webServices.getUpdatedUnitsLast24Hours(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        // The data is nested in activities object
        final data = response['data'];
        List<Unit> units = [];

        if (data is Map && data['activities'] != null) {
          final activities = data['activities'];
          if (activities is List) {
            units = activities
                .map((activity) {
              // Extract unit from activity
              if (activity['unit'] != null) {
                final unitJson = Map<String, dynamic>.from(activity['unit'] as Map<String, dynamic>);
                // Add action as change_type
                if (activity['action'] != null) {
                  print('[UPDATED 24H] Found action: ${activity['action']} for unit ${unitJson['id']}');
                  unitJson['change_type'] = activity['action'];
                  unitJson['is_updated'] = true;
                }
                // Add properties (changes and original values)
                if (activity['properties'] != null) {
                  print('[UPDATED 24H] Found properties: ${activity['properties']}');
                  unitJson['change_properties'] = activity['properties'];
                }
                return Unit.fromJson(unitJson);
              }
              return null;
            })
                .whereType<Unit>() // Filter out nulls
                .toList();
          }
        }

        if (mounted) {
          setState(() {
            _updated24Hours = units;
            _isLoadingUpdated24Hours = false;
          });
        }
      }
    } catch (e) {
      print('[WebHomeScreen] Error fetching updated units (24h): $e');
      if (mounted) {
        setState(() {
          _isLoadingUpdated24Hours = false;
        });
      }
    }
  }

  // Build web unit section (reusable) - FIXED: Removed Positioned from Column
  Widget _buildWebUnitSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required List<Unit> units,
    required bool isLoading,
    required String emptyMessage,
    ScrollController? scrollController,
    VoidCallback? onScrollLeft,
    VoidCallback? onScrollRight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 12),
            CustomText20(
              title,
              bold: true,
              color: AppColors.black,
            ),
            Spacer(),
            // Navigation arrows
            if (units.isNotEmpty && onScrollLeft != null && onScrollRight != null) ...[
              Row(
                children: [
                  // Left arrow
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onScrollLeft,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: iconColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Right arrow
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onScrollRight,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: iconColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),
            ],
            if (units.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${units.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),

        isLoading
            ? Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CustomLoadingDots(size: 80),
          ),
        )
            : units.isEmpty
            ? Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 64, color: AppColors.grey),
                SizedBox(height: 12),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        )
            : Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 380,
            child: ListView.builder(
              clipBehavior: Clip.none,
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 20), // Add padding for shadow
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < units.length - 1 ? 10 : 0,
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        context.push('/unit/${unit.id}', extra: unit.toJson());
                      },
                      child: SizedBox(
                        width: 250,
                        child: WebUnitCard(unit: unit),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // FIXED: Removed Positioned widget from here - it was causing issues
      ],
    );
  }
}
