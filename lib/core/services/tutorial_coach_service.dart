import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/services/tutorial_service.dart';

/// Service to create and manage tutorial coach marks across the app
class TutorialCoachService {
  final TutorialService _tutorialService = TutorialService();

  /// Create a tutorial coach mark with custom styling
  TutorialCoachMark createTutorial({
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
    VoidCallback? onSkip,
  }) {
    return TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.mainColor,
      paddingFocus: 10,
      opacityShadow: 0.8,
      textSkip: "SKIP",
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      onFinish: onFinish,
      onSkip: () {
        if (onSkip != null) {
          onSkip();
        } else {
          onFinish();
        }
        return true;
      },
      hideSkip: false,
      alignSkip: Alignment.topRight,
    );
  }

  /// Create a target focus for a UI element
  TargetFocus createTarget({
    required GlobalKey key,
    required String identify,
    required String title,
    required String description,
    ContentAlign? align,
    ShapeLightFocus? shape,
    IconData? icon,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      alignSkip: Alignment.topRight,
      shape: shape ?? ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: align ?? ContentAlign.bottom,
          builder: (context, controller) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon at the top (if provided)
                  if (icon != null) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: AppColors.mainColor,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Skip button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => controller.skip(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'SKIP',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Next button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => controller.next(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            elevation: 4,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'NEXT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Show tutorial for home screen
  Future<void> showHomeTutorial({
    required BuildContext context,
    required GlobalKey searchKey,
    required GlobalKey filterKey,
    required GlobalKey companyKey,
    required GlobalKey compoundKey,
  }) async {
    final hasSeen = await _tutorialService.hasSeenHomeTutorial();
    if (hasSeen) return;

    final targets = [
      createTarget(
        key: searchKey,
        identify: "search",
        title: "Search Properties",
        description: "Use the search bar to find properties, compounds, or companies. Start typing to see instant results!",
        align: ContentAlign.bottom,
        icon: Icons.search,
      ),
      createTarget(
        key: filterKey,
        identify: "filter",
        title: "Advanced Filters",
        description: "Tap the filter icon to narrow your search by price, location, bedrooms, and more. Active filters show here!",
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
        icon: Icons.filter_list,
      ),
      createTarget(
        key: companyKey,
        identify: "companies",
        title: "Browse Companies",
        description: "Scroll through real estate companies. Tap any company to view their compounds and available units.",
        align: ContentAlign.bottom,
        icon: Icons.business,
      ),
      createTarget(
        key: compoundKey,
        identify: "compounds",
        title: "Available Compounds",
        description: "View all available compounds here. Each card shows key details. Tap to explore units and amenities!",
        align: ContentAlign.top,
        icon: Icons.apartment,
      ),
    ];

    final tutorial = createTutorial(
      targets: targets,
      onFinish: () async {
        await _tutorialService.markHomeTutorialAsSeen();
      },
    );

    tutorial.show(context: context);
  }

  /// Show tutorial for compound detail screen
  Future<void> showCompoundTutorial({
    required BuildContext context,
    required GlobalKey galleryKey,
    required GlobalKey tabsKey,
    required GlobalKey unitsKey,
    required GlobalKey contactKey,
  }) async {
    final hasSeen = await _tutorialService.hasSeenCompoundsTutorial();
    if (hasSeen) return;

    final targets = [
      createTarget(
        key: galleryKey,
        identify: "gallery",
        title: "Photo Gallery",
        description: "Swipe through property images. Tap any image to view it in fullscreen mode with zoom capability!",
        align: ContentAlign.bottom,
        icon: Icons.photo_library,
      ),
      createTarget(
        key: tabsKey,
        identify: "tabs",
        title: "Information Tabs",
        description: "Switch between Overview, Units, Floor Plans, and Location tabs to explore all compound details.",
        align: ContentAlign.bottom,
        icon: Icons.tab,
      ),
      createTarget(
        key: unitsKey,
        identify: "units",
        title: "Available Units",
        description: "Browse all available units in this compound. Each card shows price, area, bedrooms, and status. Tap to view details!",
        align: ContentAlign.bottom,
        icon: Icons.home,
      ),
      createTarget(
        key: contactKey,
        identify: "contact",
        title: "Contact Sales",
        description: "Tap here to contact sales representatives. You can call, WhatsApp, or schedule a visit directly!",
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
        icon: Icons.phone,
      ),
    ];

    final tutorial = createTutorial(
      targets: targets,
      onFinish: () async {
        await _tutorialService.markCompoundsTutorialAsSeen();
      },
    );

    tutorial.show(context: context);
  }

  /// Show tutorial for unit detail screen
  Future<void> showUnitTutorial({
    required BuildContext context,
    required GlobalKey imageKey,
    required GlobalKey favoriteKey,
    required GlobalKey shareKey,
    required GlobalKey contactKey,
    GlobalKey? planKey,
  }) async {
    // Create a unique key for unit tutorial
    const String unitTutorialKey = 'tutorial_unit_seen';
    final hasSeen = await _tutorialService.hasSeen(unitTutorialKey);
    if (hasSeen) return;

    final targets = <TargetFocus>[
      createTarget(
        key: imageKey,
        identify: "image",
        title: "Unit Photos",
        description: "Swipe to view all unit photos. Tap for fullscreen view with pinch-to-zoom!",
        align: ContentAlign.bottom,
        icon: Icons.photo_camera,
      ),
      createTarget(
        key: favoriteKey,
        identify: "favorite",
        title: "Add to Favorites",
        description: "Tap the heart icon to save this unit to your favorites for quick access later!",
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
        icon: Icons.favorite,
      ),
      createTarget(
        key: shareKey,
        identify: "share",
        title: "Share Unit",
        description: "Share this unit via WhatsApp, social media, or copy the link to share with friends and family!",
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
        icon: Icons.share,
      ),
    ];

    if (planKey != null) {
      targets.add(createTarget(
        key: planKey,
        identify: "plan",
        title: "Floor Plan",
        description: "View the unit's floor plan here. Zoom in to see room layouts and dimensions!",
        align: ContentAlign.top,
        icon: Icons.map,
      ));
    }

    targets.add(createTarget(
      key: contactKey,
      identify: "contact",
      title: "Contact Sales",
      description: "Tap to contact the sales team via phone, WhatsApp, or request a property visit!",
      align: ContentAlign.top,
      shape: ShapeLightFocus.Circle,
      icon: Icons.phone_in_talk,
    ));

    final tutorial = createTutorial(
      targets: targets,
      onFinish: () async {
        await _tutorialService.markAsSeen(unitTutorialKey);
      },
    );

    tutorial.show(context: context);
  }

  /// Show tutorial for favorites screen
  Future<void> showFavoritesTutorial({
    required BuildContext context,
    required GlobalKey tabsKey,
    required GlobalKey? itemKey,
    required GlobalKey? removeKey,
  }) async {
    const String favoriteTutorialKey = 'tutorial_favorites_seen';
    final hasSeen = await _tutorialService.hasSeen(favoriteTutorialKey);
    if (hasSeen) return;

    final targets = <TargetFocus>[
      createTarget(
        key: tabsKey,
        identify: "tabs",
        title: "Favorites Tabs",
        description: "Switch between Compounds and Units tabs to view your saved favorites separately!",
        align: ContentAlign.bottom,
        icon: Icons.tab,
      ),
    ];

    if (itemKey != null) {
      targets.add(createTarget(
        key: itemKey,
        identify: "item",
        title: "Favorite Item",
        description: "Tap any favorite item to view its full details. Swipe or long-press to remove from favorites!",
        align: ContentAlign.bottom,
        icon: Icons.favorite_border,
      ));
    }

    if (removeKey != null) {
      targets.add(createTarget(
        key: removeKey,
        identify: "remove",
        title: "Remove Favorite",
        description: "Tap the heart icon to remove this item from your favorites list!",
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
        icon: Icons.delete,
      ));
    }

    final tutorial = createTutorial(
      targets: targets,
      onFinish: () async {
        await _tutorialService.markAsSeen(favoriteTutorialKey);
      },
    );

    tutorial.show(context: context);
  }

  /// Show tutorial for history screen
  Future<void> showHistoryTutorial({
    required BuildContext context,
    required GlobalKey searchKey,
    required GlobalKey filterKey,
    required GlobalKey clearKey,
    GlobalKey? itemKey,
  }) async {
    const String historyTutorialKey = 'tutorial_history_seen';
    final hasSeen = await _tutorialService.hasSeen(historyTutorialKey);
    if (hasSeen) return;

    final targets = <TargetFocus>[
      createTarget(
        key: searchKey,
        identify: "search",
        title: "Search History",
        description: "Search through your viewing history to quickly find properties you've looked at before!",
        align: ContentAlign.bottom,
        icon: Icons.search,
      ),
      createTarget(
        key: filterKey,
        identify: "filter",
        title: "Filter by Type",
        description: "Filter your history to show only compounds, only units, or view all items together!",
        align: ContentAlign.bottom,
        icon: Icons.filter_alt,
      ),
      createTarget(
        key: clearKey,
        identify: "clear",
        title: "Clear History",
        description: "Tap here to clear all your viewing history. This action cannot be undone!",
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
        icon: Icons.delete_sweep,
      ),
    ];

    if (itemKey != null) {
      targets.add(createTarget(
        key: itemKey,
        identify: "item",
        title: "History Item",
        description: "Tap any item to view its details again. Swipe to remove individual items from history!",
        align: ContentAlign.bottom,
        icon: Icons.history,
      ));
    }

    final tutorial = createTutorial(
      targets: targets,
      onFinish: () async {
        await _tutorialService.markAsSeen(historyTutorialKey);
      },
    );

    tutorial.show(context: context);
  }
}
