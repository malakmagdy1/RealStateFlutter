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

  /// No description provided for @compoundNumber.
  ///
  /// In en, this message translates to:
  /// **'Compound Number'**
  String get compoundNumber;

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

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorReadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error reading image. Please try again.'**
  String get errorReadingImage;

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

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateDescription.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available with important improvements and bug fixes. Please logout and login again to get the latest updates.'**
  String get updateDescription;

  /// No description provided for @updateNote.
  ///
  /// In en, this message translates to:
  /// **'Your session will be refreshed to apply the new changes. You will need to login again.'**
  String get updateNote;

  /// No description provided for @logoutAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'Logout and Update'**
  String get logoutAndUpdate;

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

  /// No description provided for @compoundName.
  ///
  /// In en, this message translates to:
  /// **'Compound Name'**
  String get compoundName;

  /// No description provided for @compoundLocation.
  ///
  /// In en, this message translates to:
  /// **'Compound Location'**
  String get compoundLocation;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

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
  /// **'Min'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max'**
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

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

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
  /// **'Clear All'**
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

  /// No description provided for @openLocationInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Location in Maps'**
  String get openLocationInMaps;

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

  /// No description provided for @verifiedAccount.
  ///
  /// In en, this message translates to:
  /// **'Verified Account'**
  String get verifiedAccount;

  /// No description provided for @updateYourDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Update your display name'**
  String get updateYourDisplayName;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone Number'**
  String get editPhoneNumber;

  /// No description provided for @updateYourContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Update your contact number'**
  String get updateYourContactNumber;

  /// No description provided for @viewYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'View your email address'**
  String get viewYourEmailAddress;

  /// No description provided for @updateYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updateYourPassword;

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// No description provided for @addExtraSecurity.
  ///
  /// In en, this message translates to:
  /// **'Add extra security'**
  String get addExtraSecurity;

  /// No description provided for @manageNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage notification settings'**
  String get manageNotificationSettings;

  /// No description provided for @subscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plan'**
  String get subscriptionPlan;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @searchQuota.
  ///
  /// In en, this message translates to:
  /// **'Search Quota'**
  String get searchQuota;

  /// No description provided for @unlimitedSearches.
  ///
  /// In en, this message translates to:
  /// **'Unlimited searches'**
  String get unlimitedSearches;

  /// Shows how many searches have been used out of the limit
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} searches'**
  String searchesUsed(int used, int limit);

  /// Shows how many searches are remaining
  ///
  /// In en, this message translates to:
  /// **'{count} searches remaining'**
  String searchesRemaining(int count);

  /// No description provided for @noSearchesRemaining.
  ///
  /// In en, this message translates to:
  /// **'No searches remaining'**
  String get noSearchesRemaining;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires On'**
  String get expiresOn;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @viewOurPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View our privacy policy'**
  String get viewOurPrivacyPolicy;

  /// No description provided for @readOurTerms.
  ///
  /// In en, this message translates to:
  /// **'Read our terms'**
  String get readOurTerms;

  /// No description provided for @getHelpWithYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Get help with your account'**
  String get getHelpWithYourAccount;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version 1.0.0'**
  String get appVersion;

  /// No description provided for @developerTools.
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get developerTools;

  /// No description provided for @dev.
  ///
  /// In en, this message translates to:
  /// **'DEV'**
  String get dev;

  /// No description provided for @apiTokenDescription.
  ///
  /// In en, this message translates to:
  /// **'Use this token to test API endpoints in Postman or other API clients.'**
  String get apiTokenDescription;

  /// No description provided for @authenticationToken.
  ///
  /// In en, this message translates to:
  /// **'Authentication Token:'**
  String get authenticationToken;

  /// No description provided for @copyToken.
  ///
  /// In en, this message translates to:
  /// **'Copy Token'**
  String get copyToken;

  /// No description provided for @noTokenFound.
  ///
  /// In en, this message translates to:
  /// **'No token found. Please log in first.'**
  String get noTokenFound;

  /// No description provided for @tokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Token copied to clipboard!'**
  String get tokenCopied;

  /// No description provided for @bearerTokenInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add this token as a Bearer token in your API requests:\nAuthorization: Bearer <token>'**
  String get bearerTokenInstructions;

  /// No description provided for @uploadingProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading profile image...'**
  String get uploadingProfileImage;

  /// No description provided for @profileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated successfully!'**
  String get profileImageUpdated;

  /// Error message when image upload fails
  ///
  /// In en, this message translates to:
  /// **'Error uploading image: {error}'**
  String errorUploadingImage(String error);

  /// No description provided for @noLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'No token found. Please log in first.'**
  String get noLoginMessage;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @foundResults.
  ///
  /// In en, this message translates to:
  /// **'Found {count} results'**
  String foundResults(int count);

  /// No description provided for @showingResults.
  ///
  /// In en, this message translates to:
  /// **'Showing {current} of {total}'**
  String showingResults(int current, int total);

  /// No description provided for @noMoreCompounds.
  ///
  /// In en, this message translates to:
  /// **'No more compounds to load'**
  String get noMoreCompounds;

  /// No description provided for @browseAllCompounds.
  ///
  /// In en, this message translates to:
  /// **'Browse all available compounds'**
  String get browseAllCompounds;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @hasClubFilter.
  ///
  /// In en, this message translates to:
  /// **'Has Club'**
  String get hasClubFilter;

  /// No description provided for @hasRoofFilter.
  ///
  /// In en, this message translates to:
  /// **'Has Roof'**
  String get hasRoofFilter;

  /// No description provided for @hasGardenFilter.
  ///
  /// In en, this message translates to:
  /// **'Has Garden'**
  String get hasGardenFilter;

  /// No description provided for @compoundsCount.
  ///
  /// In en, this message translates to:
  /// **'Compounds ({count})'**
  String compoundsCount(int count);

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get selectLocation;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @yourSavedCompoundsAndProperties.
  ///
  /// In en, this message translates to:
  /// **'Your saved compounds and properties'**
  String get yourSavedCompoundsAndProperties;

  /// No description provided for @favoriteProperties.
  ///
  /// In en, this message translates to:
  /// **'Favorite Properties'**
  String get favoriteProperties;

  /// No description provided for @favoriteCompounds.
  ///
  /// In en, this message translates to:
  /// **'Favorite Compounds'**
  String get favoriteCompounds;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @viewingHistory.
  ///
  /// In en, this message translates to:
  /// **'Viewing History'**
  String get viewingHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all viewing history?'**
  String get clearHistoryConfirm;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @yourCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Current Plan'**
  String get yourCurrentPlan;

  /// No description provided for @unlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium Features'**
  String get unlockPremiumFeatures;

  /// No description provided for @searchAccess.
  ///
  /// In en, this message translates to:
  /// **'Search Access'**
  String get searchAccess;

  /// No description provided for @unlimitedSearchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited searches and access to exclusive property listings'**
  String get unlimitedSearchesDescription;

  /// No description provided for @advancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters & sorting'**
  String get advancedFilters;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority customer support'**
  String get prioritySupport;

  /// No description provided for @exclusiveListings.
  ///
  /// In en, this message translates to:
  /// **'Exclusive premium listings'**
  String get exclusiveListings;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @updatedInLast24Hours.
  ///
  /// In en, this message translates to:
  /// **'Updated in Last 24 Hours'**
  String get updatedInLast24Hours;

  /// No description provided for @noUnitsUpdatedLast24Hours.
  ///
  /// In en, this message translates to:
  /// **'No units updated in the last 24 hours'**
  String get noUnitsUpdatedLast24Hours;

  /// No description provided for @newArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get newArrivals;

  /// No description provided for @noNewArrivals.
  ///
  /// In en, this message translates to:
  /// **'No new arrivals at the moment'**
  String get noNewArrivals;

  /// No description provided for @searchForCompounds.
  ///
  /// In en, this message translates to:
  /// **'Search for compounds...'**
  String get searchForCompounds;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyType;

  /// No description provided for @selectDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Select delivery date'**
  String get selectDeliveryDate;

  /// No description provided for @hasClubAmenity.
  ///
  /// In en, this message translates to:
  /// **'Has Club'**
  String get hasClubAmenity;

  /// No description provided for @hasRoofAmenity.
  ///
  /// In en, this message translates to:
  /// **'Has Roof'**
  String get hasRoofAmenity;

  /// No description provided for @hasGardenAmenity.
  ///
  /// In en, this message translates to:
  /// **'Has Garden'**
  String get hasGardenAmenity;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @yourRecentlyViewedPropertiesAndCompounds.
  ///
  /// In en, this message translates to:
  /// **'Your recently viewed properties and compounds'**
  String get yourRecentlyViewedPropertiesAndCompounds;

  /// No description provided for @searchInHistory.
  ///
  /// In en, this message translates to:
  /// **'Search in history...'**
  String get searchInHistory;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String weeksAgo(int weeks);

  /// No description provided for @noResultsFoundInHistory.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFoundInHistory;

  /// No description provided for @noViewingHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No viewing history yet'**
  String get noViewingHistoryYet;

  /// No description provided for @noCompoundViewsYet.
  ///
  /// In en, this message translates to:
  /// **'No compound views yet'**
  String get noCompoundViewsYet;

  /// No description provided for @noUnitViewsYet.
  ///
  /// In en, this message translates to:
  /// **'No unit views yet'**
  String get noUnitViewsYet;

  /// No description provided for @tryAdjustingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingSearchTerms;

  /// No description provided for @propertiesYouViewWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Properties you view will appear here'**
  String get propertiesYouViewWillAppearHere;

  /// No description provided for @totalNotificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total notifications'**
  String totalNotificationsCount(int count);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @noUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get noUnreadNotifications;

  /// No description provided for @loadingMoreResults.
  ///
  /// In en, this message translates to:
  /// **'Loading more results...'**
  String get loadingMoreResults;

  /// No description provided for @moreResultsAvailableScrollToLoad.
  ///
  /// In en, this message translates to:
  /// **'{count} more results available - Scroll to load'**
  String moreResultsAvailableScrollToLoad(int count);

  /// No description provided for @companiesCount.
  ///
  /// In en, this message translates to:
  /// **'Companies ({count})'**
  String companiesCount(int count);

  /// No description provided for @propertiesCount.
  ///
  /// In en, this message translates to:
  /// **'Properties ({count})'**
  String propertiesCount(int count);

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current}/{total}'**
  String pageOf(int current, int total);

  /// No description provided for @compoundsWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} compounds'**
  String compoundsWithCount(String count);

  /// No description provided for @unitCode.
  ///
  /// In en, this message translates to:
  /// **'Unit Code'**
  String get unitCode;

  /// No description provided for @usageType.
  ///
  /// In en, this message translates to:
  /// **'Usage Type'**
  String get usageType;

  /// No description provided for @recentUpdate.
  ///
  /// In en, this message translates to:
  /// **'Recent Update'**
  String get recentUpdate;

  /// No description provided for @recentChanges.
  ///
  /// In en, this message translates to:
  /// **'Recent Changes'**
  String get recentChanges;

  /// No description provided for @whatChanged.
  ///
  /// In en, this message translates to:
  /// **'What Changed'**
  String get whatChanged;

  /// No description provided for @changedFields.
  ///
  /// In en, this message translates to:
  /// **'Changed Fields'**
  String get changedFields;

  /// No description provided for @lastChangedAt.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastChangedAt;

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original Price'**
  String get originalPrice;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get salePrice;

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'You Save'**
  String get youSave;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get daysRemaining;

  /// No description provided for @noImagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable;

  /// No description provided for @contactForPrice.
  ///
  /// In en, this message translates to:
  /// **'Contact for Price'**
  String get contactForPrice;

  /// No description provided for @salesAgent.
  ///
  /// In en, this message translates to:
  /// **'Sales Agent'**
  String get salesAgent;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @addYourPersonalNotes.
  ///
  /// In en, this message translates to:
  /// **'Add your personal notes about this unit. Your notes are private and only visible to you.'**
  String get addYourPersonalNotes;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @oldValue.
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get oldValue;

  /// No description provided for @newValue.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newValue;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @areYouSureDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get areYouSureDeleteNote;

  /// No description provided for @noteDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Note deleted successfully'**
  String get noteDeletedSuccessfully;

  /// No description provided for @noteSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Note saved successfully'**
  String get noteSavedSuccessfully;

  /// No description provided for @failedToDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete note'**
  String get failedToDeleteNote;

  /// No description provided for @failedToSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to save note'**
  String get failedToSaveNote;

  /// No description provided for @addingNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addingNote;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @addYourFirstNote.
  ///
  /// In en, this message translates to:
  /// **'Add your first note above'**
  String get addYourFirstNote;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @mapLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Map location not available'**
  String get mapLocationNotAvailable;

  /// No description provided for @masterPlanComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Master plan details coming soon'**
  String get masterPlanComingSoon;

  /// No description provided for @contactSalesTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact Sales Team'**
  String get contactSalesTeam;

  /// No description provided for @getInTouchWithSales.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with our professional sales team for more information'**
  String get getInTouchWithSales;

  /// No description provided for @addYourPersonalNotesCompound.
  ///
  /// In en, this message translates to:
  /// **'Add your personal notes about this compound. Your notes are private and only visible to you.'**
  String get addYourPersonalNotesCompound;

  /// No description provided for @compoundNote.
  ///
  /// In en, this message translates to:
  /// **'Compound Note'**
  String get compoundNote;

  /// No description provided for @newUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Updates Available!'**
  String get newUpdatesAvailable;

  /// No description provided for @couldNotLaunchPhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone call'**
  String get couldNotLaunchPhoneCall;

  /// No description provided for @couldNotLaunchWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not launch WhatsApp'**
  String get couldNotLaunchWhatsApp;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @resale.
  ///
  /// In en, this message translates to:
  /// **'Resale'**
  String get resale;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @aiCompare.
  ///
  /// In en, this message translates to:
  /// **'AI Compare'**
  String get aiCompare;

  /// No description provided for @compareWith.
  ///
  /// In en, this message translates to:
  /// **'Compare with'**
  String get compareWith;

  /// No description provided for @selectedForComparison.
  ///
  /// In en, this message translates to:
  /// **'Selected for Comparison'**
  String get selectedForComparison;

  /// No description provided for @selectForComparison.
  ///
  /// In en, this message translates to:
  /// **'Select for Comparison'**
  String get selectForComparison;

  /// No description provided for @compareWithAI.
  ///
  /// In en, this message translates to:
  /// **'Compare with AI'**
  String get compareWithAI;

  /// No description provided for @selectAtLeast2Items.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 2 items to compare'**
  String get selectAtLeast2Items;

  /// No description provided for @compareInstructions.
  ///
  /// In en, this message translates to:
  /// **'Select 2-4 items to compare. You can compare units, compounds, or companies.'**
  String get compareInstructions;

  /// No description provided for @toAddItemsForComparison.
  ///
  /// In en, this message translates to:
  /// **'To add items for comparison, go to:'**
  String get toAddItemsForComparison;

  /// No description provided for @searchUnitsAndCompare.
  ///
  /// In en, this message translates to:
  /// **'• Search for units and tap \"Compare\" button'**
  String get searchUnitsAndCompare;

  /// No description provided for @viewCompoundAndCompare.
  ///
  /// In en, this message translates to:
  /// **'• View compound details and tap \"Compare\"'**
  String get viewCompoundAndCompare;

  /// No description provided for @browseCompaniesAndCompare.
  ///
  /// In en, this message translates to:
  /// **'• Browse companies and select \"Compare\"'**
  String get browseCompaniesAndCompare;

  /// No description provided for @comparisonStarted.
  ///
  /// In en, this message translates to:
  /// **'Comparison started'**
  String get comparisonStarted;

  /// Message shown when comparison is in progress
  ///
  /// In en, this message translates to:
  /// **'Comparing {count} items...'**
  String comparingItems(int count);

  /// No description provided for @propertyUnit.
  ///
  /// In en, this message translates to:
  /// **'Property Unit'**
  String get propertyUnit;

  /// No description provided for @developmentCompany.
  ///
  /// In en, this message translates to:
  /// **'Development Company'**
  String get developmentCompany;

  /// No description provided for @addedToComparison.
  ///
  /// In en, this message translates to:
  /// **'Added to comparison list'**
  String get addedToComparison;

  /// No description provided for @comparisonListFull.
  ///
  /// In en, this message translates to:
  /// **'Comparison list is full (max 4 items)'**
  String get comparisonListFull;

  /// No description provided for @alreadyInComparison.
  ///
  /// In en, this message translates to:
  /// **'Already in comparison list'**
  String get alreadyInComparison;

  /// No description provided for @removedFromComparison.
  ///
  /// In en, this message translates to:
  /// **'Removed from comparison list'**
  String get removedFromComparison;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @goToAI.
  ///
  /// In en, this message translates to:
  /// **'Go to AI'**
  String get goToAI;

  /// No description provided for @noResultsMatchingCriteria.
  ///
  /// In en, this message translates to:
  /// **'No results matching your criteria'**
  String get noResultsMatchingCriteria;

  /// No description provided for @comparisonList.
  ///
  /// In en, this message translates to:
  /// **'Comparison List'**
  String get comparisonList;

  /// No description provided for @startAIComparisonChat.
  ///
  /// In en, this message translates to:
  /// **'Start AI Comparison Chat'**
  String get startAIComparisonChat;

  /// No description provided for @paymentPlan.
  ///
  /// In en, this message translates to:
  /// **'Payment Plan'**
  String get paymentPlan;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down Payment'**
  String get downPayment;

  /// No description provided for @downPaymentPercentage.
  ///
  /// In en, this message translates to:
  /// **'Down Payment %'**
  String get downPaymentPercentage;

  /// No description provided for @monthlyInstallment.
  ///
  /// In en, this message translates to:
  /// **'Monthly Installment'**
  String get monthlyInstallment;

  /// No description provided for @quarterlyInstallment.
  ///
  /// In en, this message translates to:
  /// **'Quarterly Installment'**
  String get quarterlyInstallment;

  /// No description provided for @finishingType.
  ///
  /// In en, this message translates to:
  /// **'Finishing Type'**
  String get finishingType;

  /// No description provided for @maintenanceDeposit.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Deposit'**
  String get maintenanceDeposit;

  /// No description provided for @clubMembership.
  ///
  /// In en, this message translates to:
  /// **'Club Membership'**
  String get clubMembership;

  /// No description provided for @garagePrice.
  ///
  /// In en, this message translates to:
  /// **'Garage Price'**
  String get garagePrice;

  /// No description provided for @additionalFees.
  ///
  /// In en, this message translates to:
  /// **'Additional Fees'**
  String get additionalFees;

  /// No description provided for @paymentPlanFilters.
  ///
  /// In en, this message translates to:
  /// **'Payment Plan Filters'**
  String get paymentPlanFilters;

  /// No description provided for @paymentDuration.
  ///
  /// In en, this message translates to:
  /// **'Payment Duration'**
  String get paymentDuration;

  /// No description provided for @selectDuration.
  ///
  /// In en, this message translates to:
  /// **'Select Duration'**
  String get selectDuration;

  /// No description provided for @cashOnly.
  ///
  /// In en, this message translates to:
  /// **'Cash Only'**
  String get cashOnly;

  /// No description provided for @yearsInstallment.
  ///
  /// In en, this message translates to:
  /// **'{count} Years'**
  String yearsInstallment(Object count);

  /// No description provided for @monthlyPaymentRange.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment Range'**
  String get monthlyPaymentRange;

  /// No description provided for @minMonthly.
  ///
  /// In en, this message translates to:
  /// **'Min Monthly'**
  String get minMonthly;

  /// No description provided for @maxMonthly.
  ///
  /// In en, this message translates to:
  /// **'Max Monthly'**
  String get maxMonthly;

  /// No description provided for @thousandEgp.
  ///
  /// In en, this message translates to:
  /// **'K EGP'**
  String get thousandEgp;

  /// No description provided for @allDurations.
  ///
  /// In en, this message translates to:
  /// **'All Durations'**
  String get allDurations;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @manageDevices.
  ///
  /// In en, this message translates to:
  /// **'Manage Devices'**
  String get manageDevices;

  /// No description provided for @viewAndRemoveDevices.
  ///
  /// In en, this message translates to:
  /// **'View and remove devices'**
  String get viewAndRemoveDevices;

  /// No description provided for @receivePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get receivePushNotifications;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @chooseProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Profile Photo'**
  String get chooseProfilePhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noConnection;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get checkInternetConnection;

  /// No description provided for @checkWifi.
  ///
  /// In en, this message translates to:
  /// **'Check your Wi-Fi connection'**
  String get checkWifi;

  /// No description provided for @checkMobileData.
  ///
  /// In en, this message translates to:
  /// **'Check your mobile data'**
  String get checkMobileData;

  /// No description provided for @checkAirplaneMode.
  ///
  /// In en, this message translates to:
  /// **'Turn off airplane mode'**
  String get checkAirplaneMode;

  /// No description provided for @waitingForConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection...'**
  String get waitingForConnection;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred'**
  String get errorOccurred;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Exp.'**
  String get yearsOfExperience;

  /// No description provided for @unitsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Units Delivered'**
  String get unitsDelivered;

  /// No description provided for @cairoEgypt.
  ///
  /// In en, this message translates to:
  /// **'Cairo, Egypt'**
  String get cairoEgypt;

  /// About description for company
  ///
  /// In en, this message translates to:
  /// **'{companyName} is a leading developer of premium lifestyle destinations in Egypt. Since its inception in {year}, it has been a key contributor to the country\'s real estate market, renowned for its large-scale, integrated communities.'**
  String companyAboutDescription(String companyName, String year);

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Image Available'**
  String get noImageAvailable;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @searchesLeft.
  ///
  /// In en, this message translates to:
  /// **'{remaining} / {limit} searches left'**
  String searchesLeft(int remaining, int limit);

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @headOffice.
  ///
  /// In en, this message translates to:
  /// **'Head Office'**
  String get headOffice;

  /// No description provided for @ourProjects.
  ///
  /// In en, this message translates to:
  /// **'Our Projects'**
  String get ourProjects;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @recentlyViewedProperties.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed properties'**
  String get recentlyViewedProperties;

  /// No description provided for @confirmClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all viewing history?'**
  String get confirmClearHistory;

  /// No description provided for @tryAdjustingYourSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search'**
  String get tryAdjustingYourSearch;

  /// No description provided for @loadingCompanies.
  ///
  /// In en, this message translates to:
  /// **'Loading companies...'**
  String get loadingCompanies;

  /// No description provided for @loadingLocations.
  ///
  /// In en, this message translates to:
  /// **'Loading locations...'**
  String get loadingLocations;

  /// No description provided for @allCompanies.
  ///
  /// In en, this message translates to:
  /// **'All Companies'**
  String get allCompanies;

  /// No description provided for @priceRangeMillionEGP.
  ///
  /// In en, this message translates to:
  /// **'Price Range (Million EGP)'**
  String get priceRangeMillionEGP;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @villa.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// No description provided for @apartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// No description provided for @duplex.
  ///
  /// In en, this message translates to:
  /// **'Duplex'**
  String get duplex;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @penthouse.
  ///
  /// In en, this message translates to:
  /// **'Penthouse'**
  String get penthouse;

  /// No description provided for @townhouse.
  ///
  /// In en, this message translates to:
  /// **'Townhouse'**
  String get townhouse;

  /// No description provided for @chalet.
  ///
  /// In en, this message translates to:
  /// **'Chalet'**
  String get chalet;

  /// No description provided for @twinHouse.
  ///
  /// In en, this message translates to:
  /// **'Twin House'**
  String get twinHouse;

  /// No description provided for @bed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get bed;

  /// No description provided for @bedsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Beds'**
  String bedsCount(int count);

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @semiFinished.
  ///
  /// In en, this message translates to:
  /// **'Semi Finished'**
  String get semiFinished;

  /// No description provided for @notFinished.
  ///
  /// In en, this message translates to:
  /// **'Not Finished'**
  String get notFinished;

  /// No description provided for @coreShell.
  ///
  /// In en, this message translates to:
  /// **'Core & Shell'**
  String get coreShell;

  /// No description provided for @yearsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Years'**
  String yearsCount(int count);

  /// No description provided for @monthlyPaymentEGP.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment (EGP)'**
  String get monthlyPaymentEGP;

  /// No description provided for @deliveredFromDate.
  ///
  /// In en, this message translates to:
  /// **'Delivered From Date'**
  String get deliveredFromDate;

  /// No description provided for @deliveredToDate.
  ///
  /// In en, this message translates to:
  /// **'Delivered To Date'**
  String get deliveredToDate;

  /// No description provided for @selectDeliveredFromDate.
  ///
  /// In en, this message translates to:
  /// **'Select delivered from date'**
  String get selectDeliveredFromDate;

  /// No description provided for @selectDeliveredToDate.
  ///
  /// In en, this message translates to:
  /// **'Select delivered to date'**
  String get selectDeliveredToDate;

  /// No description provided for @deliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get deliveryStatus;

  /// No description provided for @selectDeliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Select delivery status'**
  String get selectDeliveryStatus;

  /// No description provided for @onlyDelivered.
  ///
  /// In en, this message translates to:
  /// **'Only Delivered'**
  String get onlyDelivered;

  /// No description provided for @notDelivered.
  ///
  /// In en, this message translates to:
  /// **'Not Delivered'**
  String get notDelivered;

  /// No description provided for @hasClubAmenityFilter.
  ///
  /// In en, this message translates to:
  /// **'Has Club'**
  String get hasClubAmenityFilter;

  /// No description provided for @hasRoofAmenityFilter.
  ///
  /// In en, this message translates to:
  /// **'Has Roof'**
  String get hasRoofAmenityFilter;

  /// No description provided for @hasGardenAmenityFilter.
  ///
  /// In en, this message translates to:
  /// **'Has Garden'**
  String get hasGardenAmenityFilter;

  /// No description provided for @deviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get deviceManagement;

  /// No description provided for @devicesUsed.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} devices used'**
  String devicesUsed(int current, int max);

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @minPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minPriceHint;

  /// No description provided for @maxPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxPriceHint;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for deletion (optional)'**
  String get deleteAccountReason;

  /// No description provided for @deleteAccountReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us why you want to delete your account'**
  String get deleteAccountReasonHint;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account deletion request has been submitted. You will receive a confirmation email within 48 hours.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit account deletion request. Please try again or contact support.'**
  String get deleteAccountError;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @deleteConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please type DELETE to confirm'**
  String get deleteConfirmationRequired;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @totalInstallments.
  ///
  /// In en, this message translates to:
  /// **'Total Installments'**
  String get totalInstallments;

  /// No description provided for @balanceAfterDown.
  ///
  /// In en, this message translates to:
  /// **'Balance After Down'**
  String get balanceAfterDown;

  /// No description provided for @pricePerSqm.
  ///
  /// In en, this message translates to:
  /// **'Price/m²'**
  String get pricePerSqm;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @sortByCompounds.
  ///
  /// In en, this message translates to:
  /// **'Sort by Compounds'**
  String get sortByCompounds;

  /// No description provided for @sortByUnits.
  ///
  /// In en, this message translates to:
  /// **'Sort by Units'**
  String get sortByUnits;
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
