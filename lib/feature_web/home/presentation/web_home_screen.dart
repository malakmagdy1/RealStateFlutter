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
import 'package:real/core/services/tutorial_service.dart';
import 'package:real/core/widgets/tutorial_dialog.dart';
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

class WebHomeScreen extends StatefulWidget {
  static String routeName = '/web-home';

  const WebHomeScreen({Key? key}) : super(key: key);

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  bool _showAllAvailableCompounds = false;
  bool _showAllRecommendedCompounds = false;

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

  // Track if initial load is done
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _refreshData();

    // Load favorites and show tutorial after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
      context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
      _showTutorialIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen (after initial load)
    if (_hasInitialized) {
      _refreshData();
    } else {
      _hasInitialized = true;
    }
  }

  /// Refresh all data on the home screen
  void _refreshData() {
    // Fetch companies and compounds
    context.read<CompanyBloc>().add(FetchCompaniesEvent());
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));

    // Fetch unit sections
    _fetchNewArrivals();
    _fetchUpdated24Hours();
  }

  Future<void> _showTutorialIfNeeded() async {
    final tutorialService = TutorialService();
    final hasSeen = await tutorialService.hasSeenWebTutorial();

    if (!hasSeen && mounted) {
      await TutorialDialog.showMultiStep(
        context: context,
        title: 'Welcome to Real Estate Web',
        steps: [
          TutorialStep(
            icon: Icons.desktop_windows,
            title: 'Web Experience',
            description: 'Enjoy a full-featured real estate browsing experience optimized for desktop and tablets.',
          ),
          TutorialStep(
            icon: Icons.business,
            title: 'Browse Companies',
            description: 'Explore trusted real estate developers and their featured projects.',
          ),
          TutorialStep(
            icon: Icons.apartment,
            title: 'View Compounds',
            description: 'Browse available compounds with detailed information, images, and pricing.',
          ),
          TutorialStep(
            icon: Icons.filter_list,
            title: 'Advanced Filtering',
            description: 'Use the navigation menu to access search, favorites, notifications, and your profile.',
          ),
        ],
        onFinish: () async {
          await tutorialService.markWebTutorialAsSeen();
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
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
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.all(24.0),
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
                            fontSize: 40,
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
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),

                // Regular home content
                  // Companies section
                CustomText20(l10n.companiesName),
                SizedBox(height: 8),

                BlocBuilder<CompanyBloc, CompanyState>(
                  builder: (context, state) {
                    if (state is CompanyLoading) {
                      return SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    else if (state is CompanySuccess) {
                      return SizedBox(
                        height: 100,
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.linear, // prevent opening delay
                          child: ListView.builder(
                            key: ValueKey(state.response.companies.length), // ✅ triggers animation only on data change
                            scrollDirection: Axis.horizontal,
                            itemCount: state.response.companies.length,
                            itemBuilder: (context, index) {
                              final company = state.response.companies[index];

                              return WebCompanyLogo(
                                company: company,
                                onTap: () {
                                  // Navigate using go_router with company data
                                  context.push(
                                    '/company/${company.id}',
                                    extra: company.toJson(),
                                  ).then((_) {
                                    context.read<CompoundBloc>().add(
                                        FetchCompoundsEvent(page: 1, limit: 100)
                                    );
                                  });
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
                )
,
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
                            child: CircularProgressIndicator(),
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
                  title: 'Updated in Last 24 Hours',
                  icon: Icons.history_toggle_off,
                  iconColor: Colors.teal,
                  gradientColors: [Colors.teal, Colors.tealAccent],
                  units: _updated24Hours,
                  isLoading: _isLoadingUpdated24Hours,
                  emptyMessage: 'No units updated in the last 24 hours',
                ),
                SizedBox(height: 16),

                // 🆕 New Arrivals Section

                _buildWebUnitSection(
                  title: 'New Arrivals',
                  icon: Icons.fiber_new,
                  iconColor: Colors.teal,
                  gradientColors: [Colors.teal, Colors.tealAccent],
                  units: _newArrivals,
                  isLoading: _isLoadingNewArrivals,
                  emptyMessage: 'No new arrivals at the moment',
                ),
                SizedBox(height: 16),
                // Recommended Compounds Section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundSuccess) {
                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      final hasMultipleRecommended = recommendedCompounds.length > 6;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: CustomText20(l10n.recommendedCompounds),
                              ),
                              if (hasMultipleRecommended)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showAllRecommendedCompounds = !_showAllRecommendedCompounds;
                                    });
                                  },
                                  label: Text(
                                    _showAllRecommendedCompounds ? l10n.showLess : l10n.showAll,
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
                          SizedBox(height: 8),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText20(l10n.recommendedCompounds),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
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

                      final displayCount = _showAllRecommendedCompounds
                          ? recommendedCompounds.length
                          : (recommendedCompounds.length > 9 ? 9 : recommendedCompounds.length);

                      // Horizontal scroll view
                      return SizedBox(
                        height: 400, // Increased to accommodate card height + shadow padding
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 20), // Add padding for shadow
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = recommendedCompounds[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < displayCount - 1 ? 16 : 0,
                              ),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    print('[WEB HOME] Compound tapped: ${compound.project}');
                                    context.push('/compound/${compound.id}');
                                  },
                                  child: SizedBox(
                                    width: 280,
                                    child: WebCompoundCard(compound: compound),
                                  ),
                                ),
                              ),
                            );
                          },
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
                                    FetchCompoundsEvent(),
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
                // Mark as new for badge display
                unitJson['change_type'] = 'new';
                unitJson['is_updated'] = true;
                return Unit.fromJson(unitJson);
              })
              .toList();
        } else if (data is List) {
          // Fallback: if data is directly a list
          units = data
              .map((unit) {
                final unitJson = Map<String, dynamic>.from(unit as Map<String, dynamic>);
                // Mark as new for badge display
                unitJson['change_type'] = 'new';
                unitJson['is_updated'] = true;
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

  // Fetch recently updated
  Future<void> _fetchRecentlyUpdated() async {
    if (_isLoadingRecentlyUpdated) return;

    setState(() {
      _isLoadingRecentlyUpdated = true;
    });

    try {
      final response = await _webServices.getRecentlyUpdated(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<Unit> units = [];

        // Check if data has nested 'data' property (pagination structure)
        if (data is Map && data['data'] != null) {
          units = (data['data'] as List)
              .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          // Fallback: if data is directly a list
          units = data
              .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
              .toList();
        }

        if (mounted) {
          setState(() {
            _recentlyUpdated = units;
            _isLoadingRecentlyUpdated = false;
          });
        }
      }
    } catch (e) {
      print('[WebHomeScreen] Error fetching recently updated: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentlyUpdated = false;
        });
      }
    }
  }

  // Fetch recommended units (last 24 hours)
  Future<void> _fetchRecommendedUnits() async {
    if (_isLoadingRecommendedUnits) return;

    setState(() {
      _isLoadingRecommendedUnits = true;
    });

    try {
      final response = await _webServices.getNewUnitsLast24Hours(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        final units = (response['data'] as List)
            .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _recommendedUnits = units;
            _isLoadingRecommendedUnits = false;
          });
        }
      }
    } catch (e) {
      print('[WebHomeScreen] Error fetching recommended units: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendedUnits = false;
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
          if (activities is Map && activities['data'] != null) {
            units = (activities['data'] as List)
                .map((activity) {
                  // Extract unit from activity
                  if (activity['unit'] != null) {
                    final unitJson = Map<String, dynamic>.from(activity['unit'] as Map<String, dynamic>);
                    // Add the change_type from activity to unit
                    if (activity['action'] == 'updated') {
                      unitJson['change_type'] = 'updated';
                      unitJson['is_updated'] = true;
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

  // Build web unit section (reusable)
  Widget _buildWebUnitSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required List<Unit> units,
    required bool isLoading,
    required String emptyMessage,
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
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: iconColor),
          ),
        )
            : units.isEmpty
            ? Container(
          padding: EdgeInsets.all(48),
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
            : SizedBox(
          height: 400,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 20), // Add padding for shadow
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];

              return Padding(
                padding: EdgeInsets.only(
                  right: index < units.length - 1 ? 16 : 0,
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                        context.push('/unit/${unit.id}', extra: unit.toJson());
                    },
                    child: SizedBox(
                      width: 300,
                      child: WebUnitCard(unit: unit),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
