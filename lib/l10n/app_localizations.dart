import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @companies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// No description provided for @compounds.
  ///
  /// In en, this message translates to:
  /// **'Compounds'**
  String get compounds;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @searchFor.
  ///
  /// In en, this message translates to:
  /// **'Search for properties...'**
  String get searchFor;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @finishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing'**
  String get finishing;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @unitDetails.
  ///
  /// In en, this message translates to:
  /// **'Unit Details'**
  String get unitDetails;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Info'**
  String get companyInfo;

  /// No description provided for @contactSales.
  ///
  /// In en, this message translates to:
  /// **'Contact Sales'**
  String get contactSales;

  /// No description provided for @shareUnit.
  ///
  /// In en, this message translates to:
  /// **'Share Unit'**
  String get shareUnit;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @priceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceAsc;

  /// No description provided for @priceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceDesc;

  /// No description provided for @dateAsc.
  ///
  /// In en, this message translates to:
  /// **'Date: Oldest First'**
  String get dateAsc;

  /// No description provided for @dateDesc.
  ///
  /// In en, this message translates to:
  /// **'Date: Newest First'**
  String get dateDesc;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @savedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved Searches'**
  String get savedSearches;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @totalUnits.
  ///
  /// In en, this message translates to:
  /// **'Total Units'**
  String get totalUnits;

  /// No description provided for @availableUnits.
  ///
  /// In en, this message translates to:
  /// **'Available Units'**
  String get availableUnits;

  /// No description provided for @unitNumber.
  ///
  /// In en, this message translates to:
  /// **'Unit Number'**
  String get unitNumber;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// No description provided for @unitId.
  ///
  /// In en, this message translates to:
  /// **'Unit ID'**
  String get unitId;

  /// No description provided for @compoundId.
  ///
  /// In en, this message translates to:
  /// **'Compound ID'**
  String get compoundId;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @gardenArea.
  ///
  /// In en, this message translates to:
  /// **'Garden Area'**
  String get gardenArea;

  /// No description provided for @roofArea.
  ///
  /// In en, this message translates to:
  /// **'Roof Area'**
  String get roofArea;

  /// No description provided for @totalArea.
  ///
  /// In en, this message translates to:
  /// **'Total Area'**
  String get totalArea;

  /// No description provided for @listedOn.
  ///
  /// In en, this message translates to:
  /// **'Listed On'**
  String get listedOn;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @egp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egp;

  /// No description provided for @sqm.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get sqm;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @minArea.
  ///
  /// In en, this message translates to:
  /// **'Min Area'**
  String get minArea;

  /// No description provided for @maxArea.
  ///
  /// In en, this message translates to:
  /// **'Max Area'**
  String get maxArea;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChangedTo(Object language);

  /// No description provided for @noCompanies.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get noCompanies;

  /// No description provided for @noCompounds.
  ///
  /// In en, this message translates to:
  /// **'No compounds found'**
  String get noCompounds;

  /// No description provided for @noUnits.
  ///
  /// In en, this message translates to:
  /// **'No units found'**
  String get noUnits;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @editPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone'**
  String get editPhone;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @compound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get compound;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @salesContact.
  ///
  /// In en, this message translates to:
  /// **'Sales Contact'**
  String get salesContact;

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling {number}...'**
  String calling(Object number);

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @showAllUnits.
  ///
  /// In en, this message translates to:
  /// **'Show All Units'**
  String get showAllUnits;

  /// No description provided for @noActiveSales.
  ///
  /// In en, this message translates to:
  /// **'No active sales at the moment'**
  String get noActiveSales;

  /// No description provided for @saleDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sale data unavailable'**
  String get saleDataUnavailable;

  /// No description provided for @availableCompounds.
  ///
  /// In en, this message translates to:
  /// **'Available Compounds'**
  String get availableCompounds;

  /// No description provided for @recommendedCompounds.
  ///
  /// In en, this message translates to:
  /// **'Recommended Compounds'**
  String get recommendedCompounds;

  /// No description provided for @companiesName.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companiesName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @beds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get beds;

  /// No description provided for @baths.
  ///
  /// In en, this message translates to:
  /// **'Baths'**
  String get baths;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @rateThisCompound.
  ///
  /// In en, this message translates to:
  /// **'Rate this compound'**
  String get rateThisCompound;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellent;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good!'**
  String get veryGood;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @needsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get needsImprovement;

  /// No description provided for @userReviews.
  ///
  /// In en, this message translates to:
  /// **'User Reviews'**
  String get userReviews;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @hideReviews.
  ///
  /// In en, this message translates to:
  /// **'Hide Reviews'**
  String get hideReviews;

  /// No description provided for @showReviews.
  ///
  /// In en, this message translates to:
  /// **'Show Reviews'**
  String get showReviews;

  /// No description provided for @searchUnits.
  ///
  /// In en, this message translates to:
  /// **'Search units by number, type, or area...'**
  String get searchUnits;

  /// No description provided for @noUnitsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No units available'**
  String get noUnitsAvailable;

  /// No description provided for @noUnitsMatch.
  ///
  /// In en, this message translates to:
  /// **'No units match your search'**
  String get noUnitsMatch;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'About Company'**
  String get aboutCompany;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @allCompounds.
  ///
  /// In en, this message translates to:
  /// **'All Compounds'**
  String get allCompounds;

  /// No description provided for @noCompoundsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No compounds available'**
  String get noCompoundsAvailable;

  /// No description provided for @customerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// No description provided for @searchForUnits.
  ///
  /// In en, this message translates to:
  /// **'Search for Units'**
  String get searchForUnits;

  /// No description provided for @useSearchBar.
  ///
  /// In en, this message translates to:
  /// **'Use the search bar above to find companies, compounds, or units'**
  String get useSearchBar;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @getStartedNow.
  ///
  /// In en, this message translates to:
  /// **'Get Started Now'**
  String get getStartedNow;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your Full name'**
  String get enterFullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @registering.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get registering;

  /// No description provided for @unitsInformation.
  ///
  /// In en, this message translates to:
  /// **'Units Information'**
  String get unitsInformation;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @deliveryInformation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Information'**
  String get deliveryInformation;

  /// No description provided for @salesTeam.
  ///
  /// In en, this message translates to:
  /// **'Sales Team'**
  String get salesTeam;

  /// No description provided for @ratingsReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsReviews;

  /// No description provided for @builtUpArea.
  ///
  /// In en, this message translates to:
  /// **'Built Up Area'**
  String get builtUpArea;

  /// No description provided for @builtArea.
  ///
  /// In en, this message translates to:
  /// **'Built Area'**
  String get builtArea;

  /// No description provided for @landArea.
  ///
  /// In en, this message translates to:
  /// **'Land Area'**
  String get landArea;

  /// No description provided for @numberOfFloors.
  ///
  /// In en, this message translates to:
  /// **'Number of Floors'**
  String get numberOfFloors;

  /// No description provided for @finishSpecs.
  ///
  /// In en, this message translates to:
  /// **'Finish Specs'**
  String get finishSpecs;

  /// No description provided for @hasClub.
  ///
  /// In en, this message translates to:
  /// **'Has Club'**
  String get hasClub;

  /// No description provided for @plannedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Planned Delivery'**
  String get plannedDelivery;

  /// No description provided for @actualDelivery.
  ///
  /// In en, this message translates to:
  /// **'Actual Delivery'**
  String get actualDelivery;

  /// No description provided for @completionProgress.
  ///
  /// In en, this message translates to:
  /// **'Completion Progress'**
  String get completionProgress;

  /// No description provided for @calling2.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}...'**
  String calling2(Object name);

  /// No description provided for @noFavoriteCompounds.
  ///
  /// In en, this message translates to:
  /// **'No favorite compounds'**
  String get noFavoriteCompounds;

  /// No description provided for @noFavoriteUnits.
  ///
  /// In en, this message translates to:
  /// **'No favorite units'**
  String get noFavoriteUnits;

  /// No description provided for @startAddingCompounds.
  ///
  /// In en, this message translates to:
  /// **'Start adding compounds to your favorites!'**
  String get startAddingCompounds;

  /// No description provided for @startAddingUnits.
  ///
  /// In en, this message translates to:
  /// **'Start adding units to your favorites from search!'**
  String get startAddingUnits;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @allUnits.
  ///
  /// In en, this message translates to:
  /// **'All Units'**
  String get allUnits;

  /// Message shown when user rates a compound
  ///
  /// In en, this message translates to:
  /// **'You rated {rating} stars!'**
  String youRatedStars(int rating);

  /// No description provided for @activeSales.
  ///
  /// In en, this message translates to:
  /// **'Active Sales'**
  String get activeSales;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @oldPrice.
  ///
  /// In en, this message translates to:
  /// **'Old Price'**
  String get oldPrice;

  /// No description provided for @newPrice.
  ///
  /// In en, this message translates to:
  /// **'New Price'**
  String get newPrice;

  /// No description provided for @endsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in'**
  String get endsIn;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @contactSalesPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Sales Person'**
  String get contactSalesPerson;

  /// No description provided for @selectSalesPerson.
  ///
  /// In en, this message translates to:
  /// **'Select Sales Person'**
  String get selectSalesPerson;

  /// No description provided for @noSalesPersonAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sales person available'**
  String get noSalesPersonAvailable;

  /// No description provided for @callSalesPerson.
  ///
  /// In en, this message translates to:
  /// **'Call Sales Person'**
  String get callSalesPerson;

  /// No description provided for @noActiveSalesForThisItem.
  ///
  /// In en, this message translates to:
  /// **'No active sales for this item'**
  String get noActiveSalesForThisItem;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @markedAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get markedAllAsRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @allNotificationsCleared.
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get allNotificationsCleared;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotifications;

  /// No description provided for @clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This action cannot be undone.'**
  String get clearAllConfirm;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUp;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unread'**
  String get markAsUnread;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No details available for this notification'**
  String get noDetailsAvailable;

  /// No description provided for @perSqm.
  ///
  /// In en, this message translates to:
  /// **'per m²'**
  String get perSqm;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @floorPlan.
  ///
  /// In en, this message translates to:
  /// **'Floor Plan'**
  String get floorPlan;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @saleType.
  ///
  /// In en, this message translates to:
  /// **'Sale Type'**
  String get saleType;

  /// No description provided for @numberOfBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Number of Bedrooms'**
  String get numberOfBedrooms;

  /// No description provided for @numberOfBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Number of Bathrooms'**
  String get numberOfBathrooms;

  /// No description provided for @mapViewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Map view not available'**
  String get mapViewNotAvailable;

  /// No description provided for @floorPlanNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Floor plan not available'**
  String get floorPlanNotAvailable;

  /// No description provided for @paymentPlans.
  ///
  /// In en, this message translates to:
  /// **'Payment Plans'**
  String get paymentPlans;

  /// No description provided for @noMortgageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Mortgage Available'**
  String get noMortgageAvailable;

  /// No description provided for @fillForm.
  ///
  /// In en, this message translates to:
  /// **'Fill Form'**
  String get fillForm;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhone;

  /// No description provided for @requestInfo.
  ///
  /// In en, this message translates to:
  /// **'Request Info'**
  String get requestInfo;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @developerInformation.
  ///
  /// In en, this message translates to:
  /// **'Developer Information'**
  String get developerInformation;

  /// No description provided for @trustedDeveloperDescription.
  ///
  /// In en, this message translates to:
  /// **'Trusted developer with multiple successful projects in Egypt'**
  String get trustedDeveloperDescription;

  /// No description provided for @pricingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Payment'**
  String get pricingPayment;

  /// No description provided for @startingPrice.
  ///
  /// In en, this message translates to:
  /// **'Starting Price'**
  String get startingPrice;

  /// No description provided for @contactForDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact for details'**
  String get contactForDetails;

  /// No description provided for @tba.
  ///
  /// In en, this message translates to:
  /// **'TBA'**
  String get tba;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @finishSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Finish Specifications'**
  String get finishSpecifications;

  /// No description provided for @masterPlan.
  ///
  /// In en, this message translates to:
  /// **'Master Plan'**
  String get masterPlan;

  /// No description provided for @featuresAmenities.
  ///
  /// In en, this message translates to:
  /// **'Features & Amenities'**
  String get featuresAmenities;

  /// No description provided for @swimmingPool.
  ///
  /// In en, this message translates to:
  /// **'Swimming Pool'**
  String get swimmingPool;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// No description provided for @sportsClub.
  ///
  /// In en, this message translates to:
  /// **'Sports Club'**
  String get sportsClub;

  /// No description provided for @security247.
  ///
  /// In en, this message translates to:
  /// **'24/7 Security'**
  String get security247;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @greenAreas.
  ///
  /// In en, this message translates to:
  /// **'Green Areas'**
  String get greenAreas;

  /// No description provided for @commercialArea.
  ///
  /// In en, this message translates to:
  /// **'Commercial Area'**
  String get commercialArea;

  /// No description provided for @kidsArea.
  ///
  /// In en, this message translates to:
  /// **'Kids Area'**
  String get kidsArea;

  /// No description provided for @requestMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'Request More Information'**
  String get requestMoreInformation;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @messageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (Optional)'**
  String get messageOptional;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @requestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully!'**
  String get requestSubmittedSuccessfully;

  /// No description provided for @aboutTheDeveloper.
  ///
  /// In en, this message translates to:
  /// **'About the Developer'**
  String get aboutTheDeveloper;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @floors.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get floors;

  /// No description provided for @club.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get club;

  /// Company description
  ///
  /// In en, this message translates to:
  /// **'{companyName} is a leading real estate developer in Egypt, known for creating exceptional residential and commercial properties.'**
  String leadingDeveloper(String companyName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
