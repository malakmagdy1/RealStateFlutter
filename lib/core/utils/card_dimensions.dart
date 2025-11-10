/// Constants for card dimensions used across the app
/// This ensures consistent card sizes in home, compounds, favorites, and history screens
class CardDimensions {
  // Compound Card Dimensions - optimized for more image, less text
  static const double compoundCardWidth = 220.0;
  static const double compoundCardHeight = 280.0; // Reduced height for less white space
  static const double compoundCardImageHeight = 190.0; // Increased from 176 (86% of 220)
  static const double compoundCardBorderRadius = 12.0;

  // Unit Card Dimensions
  static const double unitCardWidth = 200.0;
  static const double unitCardHeight = 280.0;

  // Spacing
  static const double horizontalCardSpacing = 10.0;
  static const double verticalCardSpacing = 12.0;

  // Company Logo - increased for better visibility
  static const double companyLogoRadius = 45.0; // Increased from 35.0
  static const double companyLogoContainerHeight = 120.0; // Increased from 100.0
}
