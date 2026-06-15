import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
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
    Locale('de'),
    Locale('en')
  ];

  /// Application title shown in app bars and system title
  ///
  /// In en, this message translates to:
  /// **'Holiday Planner'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @useSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use system theme'**
  String get useSystemTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings section header for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// Radio option to follow the system language
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get useSystemLanguage;

  /// Radio option label for English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Radio option label for German (shown in German)
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// About section line showing app name and version
  ///
  /// In en, this message translates to:
  /// **'Holiday Planner App {version}'**
  String aboutAppWithVersion(String version);

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// No description provided for @navTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// No description provided for @navPackingLists.
  ///
  /// In en, this message translates to:
  /// **'Packing Lists'**
  String get navPackingLists;

  /// No description provided for @tripFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripFilterUpcoming;

  /// No description provided for @tripFilterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tripFilterPast;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get newTrip;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @noPackingItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No packing items'**
  String get noPackingItemsTitle;

  /// No description provided for @noPackingItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add items to your packing list to get started!'**
  String get noPackingItemsSubtitle;

  /// Label indicating how many items in a category
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(num count);

  /// No description provided for @deleteItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItemTooltip;

  /// Quantity indicating a fixed total amount
  ///
  /// In en, this message translates to:
  /// **'{count} fixed'**
  String quantityFixed(num count);

  /// Quantity indicating how many per day
  ///
  /// In en, this message translates to:
  /// **'{count} per day'**
  String quantityPerDay(num count);

  /// Quantity indicating how many per night
  ///
  /// In en, this message translates to:
  /// **'{count} per night'**
  String quantityPerNight(num count);

  /// No description provided for @noQuantityConfigured.
  ///
  /// In en, this message translates to:
  /// **'No quantity configured'**
  String get noQuantityConfigured;

  /// No description provided for @createTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get createTripTitle;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @addHeaderImage.
  ///
  /// In en, this message translates to:
  /// **'Add Header Image'**
  String get addHeaderImage;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetails;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @tripName.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripName;

  /// No description provided for @travelDates.
  ///
  /// In en, this message translates to:
  /// **'Travel Dates'**
  String get travelDates;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @deviceGallery.
  ///
  /// In en, this message translates to:
  /// **'Device Gallery'**
  String get deviceGallery;

  /// No description provided for @webSearch.
  ///
  /// In en, this message translates to:
  /// **'Web Search'**
  String get webSearch;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @confirmTrainInformation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Train Information'**
  String get confirmTrainInformation;

  /// No description provided for @confirmAndSelectTrip.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Select Trip'**
  String get confirmAndSelectTrip;

  /// No description provided for @noTripsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Trips Available'**
  String get noTripsAvailable;

  /// No description provided for @addTrainInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Train Information'**
  String get addTrainInformationTitle;

  /// No description provided for @selectTripToAddTrainInfo.
  ///
  /// In en, this message translates to:
  /// **'Select a trip to add the train information to:'**
  String get selectTripToAddTrainInfo;

  /// Generic error text prefix combined with a message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// Title shown when no attachments are available
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get noAttachmentsTitle;

  /// Subtitle encouraging users to add attachments
  ///
  /// In en, this message translates to:
  /// **'Add files to keep important documents with your trip'**
  String get noAttachmentsSubtitle;

  /// Info text in edit accommodation when there are no attachments yet
  ///
  /// In en, this message translates to:
  /// **'No attachments added yet'**
  String get noAttachmentsAddedYet;

  /// Error message shown when deleting a trip fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete trip: {error}'**
  String failedToDeleteTripWithError(String error);

  /// Label for weather section or card
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherLabel;

  /// Weather condition label: sunny
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get weatherSunny;

  /// Weather condition label: cloudy
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// Weather condition label: rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// Weather condition label: snow
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// Weather condition label: thunderstorm
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// Title for the weather condition selector dialog
  ///
  /// In en, this message translates to:
  /// **'Weather Condition'**
  String get weatherConditionTitle;

  /// Description text in weather selector dialog
  ///
  /// In en, this message translates to:
  /// **'Set the weather condition and minimum probability for this item to be included in your packing list.'**
  String get weatherConditionDescription;

  /// Label for probability input
  ///
  /// In en, this message translates to:
  /// **'Minimum Probability (%)'**
  String get minimumProbabilityLabel;

  /// Hint for probability input
  ///
  /// In en, this message translates to:
  /// **'Enter probability (0-100)'**
  String get minimumProbabilityHint;

  /// Validation message: empty probability
  ///
  /// In en, this message translates to:
  /// **'Please enter a probability'**
  String get enterProbabilityValidation;

  /// Validation message: not a number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumberValidation;

  /// Validation message: range
  ///
  /// In en, this message translates to:
  /// **'Probability must be between 0 and 100'**
  String get probabilityRangeValidation;

  /// Generic save action label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic add action label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Title for the weather forecast section
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast'**
  String get weatherForecastTitle;

  /// Label showing chance of rain as a percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}% chance of rain'**
  String chanceOfRainPercent(num percent);

  /// Title of the dialog to add a packing list condition
  ///
  /// In en, this message translates to:
  /// **'Add Condition'**
  String get addConditionTitle;

  /// Intro text in the condition selector dialog
  ///
  /// In en, this message translates to:
  /// **'Choose when this item should be included in your packing list:'**
  String get conditionSelectorIntro;

  /// Option title: minimum trip duration
  ///
  /// In en, this message translates to:
  /// **'Min Trip Duration'**
  String get conditionMinTripDurationTitle;

  /// Option subtitle for min trip duration
  ///
  /// In en, this message translates to:
  /// **'Include for trips longer than X days'**
  String get conditionMinTripDurationSubtitle;

  /// Option title: maximum trip duration
  ///
  /// In en, this message translates to:
  /// **'Max Trip Duration'**
  String get conditionMaxTripDurationTitle;

  /// Option subtitle for max trip duration
  ///
  /// In en, this message translates to:
  /// **'Include for trips shorter than X days'**
  String get conditionMaxTripDurationSubtitle;

  /// Option title: minimum temperature
  ///
  /// In en, this message translates to:
  /// **'Min Temperature'**
  String get conditionMinTemperatureTitle;

  /// Option subtitle for min temperature
  ///
  /// In en, this message translates to:
  /// **'Include when temperature is above X°C'**
  String get conditionMinTemperatureSubtitle;

  /// Option title: maximum temperature
  ///
  /// In en, this message translates to:
  /// **'Max Temperature'**
  String get conditionMaxTemperatureTitle;

  /// Option subtitle for max temperature
  ///
  /// In en, this message translates to:
  /// **'Include when temperature is below X°C'**
  String get conditionMaxTemperatureSubtitle;

  /// Option title: weather condition
  ///
  /// In en, this message translates to:
  /// **'Weather Condition'**
  String get conditionWeatherTitle;

  /// Option subtitle: based on forecast
  ///
  /// In en, this message translates to:
  /// **'Include based on weather forecast'**
  String get conditionWeatherSubtitle;

  /// Option title: trip tag
  ///
  /// In en, this message translates to:
  /// **'Trip Tag'**
  String get conditionTripTagTitle;

  /// Option subtitle for trip tag condition
  ///
  /// In en, this message translates to:
  /// **'Include when trip has a specific tag'**
  String get conditionTripTagSubtitle;

  /// Temperature selector title for min
  ///
  /// In en, this message translates to:
  /// **'Min Temperature'**
  String get temperatureSelectorMinTitle;

  /// Temperature selector title for max
  ///
  /// In en, this message translates to:
  /// **'Max Temperature'**
  String get temperatureSelectorMaxTitle;

  /// Description text in temperature selector (min)
  ///
  /// In en, this message translates to:
  /// **'Set the minimum temperature for this item to be included in your packing list.'**
  String get temperatureSelectorMinDescription;

  /// Description text in temperature selector (max)
  ///
  /// In en, this message translates to:
  /// **'Set the maximum temperature for this item to be included in your packing list.'**
  String get temperatureSelectorMaxDescription;

  /// Label for temperature input field
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperatureFieldLabel;

  /// Hint for temperature input field
  ///
  /// In en, this message translates to:
  /// **'Enter temperature'**
  String get temperatureFieldHint;

  /// Validation message when temperature is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a temperature'**
  String get temperatureValidationEmpty;

  /// Validation message when temperature is not a number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get temperatureValidationNaN;

  /// Trip duration selector title for min
  ///
  /// In en, this message translates to:
  /// **'Min Trip Duration'**
  String get tripDurationSelectorMinTitle;

  /// Trip duration selector title for max
  ///
  /// In en, this message translates to:
  /// **'Max Trip Duration'**
  String get tripDurationSelectorMaxTitle;

  /// Description in trip duration selector (min)
  ///
  /// In en, this message translates to:
  /// **'Set the minimum trip duration for this item to be included in your packing list.'**
  String get tripDurationSelectorMinDescription;

  /// Description in trip duration selector (max)
  ///
  /// In en, this message translates to:
  /// **'Set the maximum trip duration for this item to be included in your packing list.'**
  String get tripDurationSelectorMaxDescription;

  /// Label for duration input (days)
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get tripDurationFieldLabel;

  /// Hint for duration input
  ///
  /// In en, this message translates to:
  /// **'Enter number of days'**
  String get tripDurationFieldHint;

  /// Validation: duration empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a duration'**
  String get tripDurationValidationEmpty;

  /// Validation: duration not a number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get tripDurationValidationNaN;

  /// Validation: duration > 0
  ///
  /// In en, this message translates to:
  /// **'Duration must be greater than 0'**
  String get tripDurationValidationGtZero;

  /// Title when editing tag condition
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get tagSelectorEditTitle;

  /// Title when selecting a tag
  ///
  /// In en, this message translates to:
  /// **'Select Tag'**
  String get tagSelectorSelectTitle;

  /// Prompt when editing tag condition
  ///
  /// In en, this message translates to:
  /// **'Choose a different tag for this condition:'**
  String get tagSelectorEditPrompt;

  /// Prompt when selecting a tag
  ///
  /// In en, this message translates to:
  /// **'Choose a tag that must be associated with the trip:'**
  String get tagSelectorSelectPrompt;

  /// Button label to create a new tag
  ///
  /// In en, this message translates to:
  /// **'New Tag'**
  String get newTag;

  /// Title shown when tags failed to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load tags'**
  String get failedToLoadTags;

  /// Title shown when there are no tags
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get noTagsAvailable;

  /// Hint text encouraging the user to create a tag
  ///
  /// In en, this message translates to:
  /// **'Create your first tag to use it as a condition'**
  String get createFirstTagHint;

  /// Dialog title to create a new tag
  ///
  /// In en, this message translates to:
  /// **'Create New Tag'**
  String get createNewTagTitle;

  /// Label for tag name input
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get tagNameLabel;

  /// Hint for tag name input
  ///
  /// In en, this message translates to:
  /// **'e.g., Beach, City, Adventure'**
  String get tagNameHint;

  /// Validation for empty tag name
  ///
  /// In en, this message translates to:
  /// **'Please enter a tag name'**
  String get tagNameValidationEmpty;

  /// No description provided for @bookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsTitle;

  /// No description provided for @noBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get noBookingsTitle;

  /// No description provided for @noBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add reservations and car rental bookings for your trip'**
  String get noBookingsSubtitle;

  /// No description provided for @addBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Booking'**
  String get addBookingTitle;

  /// No description provided for @addReservationOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Reservation'**
  String get addReservationOptionTitle;

  /// No description provided for @addReservationOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurant, hotel, or other booking'**
  String get addReservationOptionSubtitle;

  /// No description provided for @addCarRentalOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Car Rental'**
  String get addCarRentalOptionTitle;

  /// No description provided for @addCarRentalOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Car rental booking'**
  String get addCarRentalOptionSubtitle;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @deleteReservationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reservation'**
  String get deleteReservationTitle;

  /// Confirmation text to delete a reservation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteReservationConfirm(String title);

  /// Snackbar error when deleting reservation fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting reservation: {message}'**
  String errorDeletingReservation(String message);

  /// No description provided for @deleteCarRentalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Car Rental'**
  String get deleteCarRentalTitle;

  /// Confirmation text for deleting car rental
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the {provider} rental?'**
  String deleteCarRentalConfirm(String provider);

  /// Snackbar error when deleting car rental fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting car rental: {message}'**
  String errorDeletingCarRental(String message);

  /// No description provided for @locationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationsTitle;

  /// Snackbar when a location was added
  ///
  /// In en, this message translates to:
  /// **'Location \"{name}\" added successfully'**
  String locationAddedSuccessfully(String name);

  /// Snackbar when adding location failed
  ///
  /// In en, this message translates to:
  /// **'Failed to add location: {message}'**
  String failedToAddLocation(String message);

  /// No description provided for @deleteLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Location'**
  String get deleteLocationTitle;

  /// Location deletion confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{city}\"? This action cannot be undone.'**
  String deleteLocationConfirm(String city);

  /// Snackbar when a location was deleted
  ///
  /// In en, this message translates to:
  /// **'Location \"{city}\" deleted successfully'**
  String locationDeleted(String city);

  /// Error deleting location
  ///
  /// In en, this message translates to:
  /// **'Failed to delete location: {message}'**
  String failedToDeleteLocation(String message);

  /// No description provided for @coastal.
  ///
  /// In en, this message translates to:
  /// **'coastal'**
  String get coastal;

  /// No description provided for @inland.
  ///
  /// In en, this message translates to:
  /// **'inland'**
  String get inland;

  /// Snackbar after toggling coastal flag
  ///
  /// In en, this message translates to:
  /// **'Coastal status updated to {status}'**
  String coastalStatusUpdated(String status);

  /// Snackbar when coastal update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update coastal status: {message}'**
  String failedToUpdateCoastal(String message);

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get locationNotFound;

  /// No description provided for @accommodationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accommodations'**
  String get accommodationsTitle;

  /// No description provided for @addAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Add Accommodation'**
  String get addAccommodation;

  /// No description provided for @editAccommodationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Accommodation'**
  String get editAccommodationTitle;

  /// No description provided for @deleteAccommodationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Accommodation'**
  String get deleteAccommodationTitle;

  /// Confirm delete accommodation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteAccommodationConfirm(String name);

  /// No description provided for @chooseDifferentFile.
  ///
  /// In en, this message translates to:
  /// **'Choose Different File'**
  String get chooseDifferentFile;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @editTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip'**
  String get editTripTitle;

  /// No description provided for @deleteTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Trip'**
  String get deleteTripTitle;

  /// Generic edit action label, e.g. on icon buttons
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @pointsOfInterestTitle.
  ///
  /// In en, this message translates to:
  /// **'Points of Interest'**
  String get pointsOfInterestTitle;

  /// No description provided for @addPointOfInterest.
  ///
  /// In en, this message translates to:
  /// **'Add Point of Interest'**
  String get addPointOfInterest;

  /// No description provided for @editPointOfInterestTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Point of Interest'**
  String get editPointOfInterestTitle;

  /// No description provided for @deletePointOfInterestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Point of Interest'**
  String get deletePointOfInterestTitle;

  /// Confirm delete POI
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deletePointOfInterestConfirm(String name);

  /// Error when deleting POI
  ///
  /// In en, this message translates to:
  /// **'Error deleting point of interest: {message}'**
  String errorDeletingPointOfInterest(String message);

  /// Singular label for a point of interest chip/header
  ///
  /// In en, this message translates to:
  /// **'Point of Interest'**
  String get pointOfInterestLabel;

  /// Singular label for an accommodation chip/header
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get accommodationLabel;

  /// Label for accommodation check-in datetime
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkInLabel;

  /// Label for accommodation check-out datetime
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOutLabel;

  /// Label for notes section
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Shown when no weather forecast is available
  ///
  /// In en, this message translates to:
  /// **'No weather data'**
  String get noWeatherData;

  /// Label for high tide
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highTide;

  /// Label for low tide
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowTide;

  /// Format for tide with time
  ///
  /// In en, this message translates to:
  /// **'{tide} tide at {time}'**
  String tideAtTime(String tide, String time);

  /// Bottom navigation tab label: Summary
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTab;

  /// Bottom navigation tab label: Timeline
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTab;

  /// Bottom navigation tab label: Map
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// Bottom navigation tab label: Attachments
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsTab;

  /// Bottom navigation tab label: Planner
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get plannerTab;

  /// Header label for a trip day with index
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String dayPlannerDayLabel(int n);

  /// Placeholder for an untitled day
  ///
  /// In en, this message translates to:
  /// **'Untitled day'**
  String get dayPlannerTitleHint;

  /// Label for the unassigned items rail
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get dayPlannerUnassigned;

  /// Affordance to attach a location to a day
  ///
  /// In en, this message translates to:
  /// **'Add a location'**
  String get dayPlannerAddLocation;

  /// Title of the sheet that edits a day's locations
  ///
  /// In en, this message translates to:
  /// **'Day locations'**
  String get dayPlannerLocationsSheetTitle;

  /// Badge shown on the primary location of a day
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get dayPlannerPrimaryBadge;

  /// Action that removes a schedulable item from its day
  ///
  /// In en, this message translates to:
  /// **'Move to unassigned'**
  String get dayPlannerRemoveFromDay;

  /// Hint shown on a day card with no scheduled items
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for this day yet.'**
  String get dayPlannerEmptyDayHint;

  /// Affordance to add an item to a day
  ///
  /// In en, this message translates to:
  /// **'Add to day'**
  String get dayPlannerAddToDay;

  /// Title shown in the picker sheet when assigning items to a day
  ///
  /// In en, this message translates to:
  /// **'Add to {label}'**
  String dayPlannerAddSheetTitle(String label);

  /// Empty state inside the add-to-day picker
  ///
  /// In en, this message translates to:
  /// **'No items available to schedule.'**
  String get dayPlannerAddSheetEmpty;

  /// Section header inside the add picker
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get dayPlannerFromUnassigned;

  /// Section header inside the add picker
  ///
  /// In en, this message translates to:
  /// **'From other days'**
  String get dayPlannerFromOtherDays;

  /// Menu item to relocate an item to another day
  ///
  /// In en, this message translates to:
  /// **'Move to a different day'**
  String get dayPlannerMoveToDay;

  /// Header of the top-of-planner unassigned items panel
  ///
  /// In en, this message translates to:
  /// **'Unassigned ({count})'**
  String dayPlannerUnassignedSectionTitle(int count);

  /// Title shown when there are no trips in the list
  ///
  /// In en, this message translates to:
  /// **'No trips found'**
  String get noTripsFoundTitle;

  /// Subtitle shown when there are no trips
  ///
  /// In en, this message translates to:
  /// **'Start planning your next adventure!'**
  String get noTripsFoundSubtitle;

  /// Duration label for exactly one day
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// Duration label for N days
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(num count);

  /// Label on the header image placeholder to change the image
  ///
  /// In en, this message translates to:
  /// **'Change Header Image'**
  String get changeHeaderImage;

  /// Title for the add car rental page
  ///
  /// In en, this message translates to:
  /// **'Add Car Rental'**
  String get addCarRentalPageTitle;

  /// Validation error shown when required fields are missing
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get pleaseFillRequiredFields;

  /// Snackbar shown when a car rental has been added
  ///
  /// In en, this message translates to:
  /// **'Car rental added successfully'**
  String get carRentalAddedSuccessfully;

  /// Error when adding car rental fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add car rental: {message}'**
  String failedToAddCarRental(String message);

  /// Snackbar when train information import succeeded
  ///
  /// In en, this message translates to:
  /// **'Train information added successfully!'**
  String get trainInfoAddedSuccessfully;

  /// Dialog content explaining that a trip is required
  ///
  /// In en, this message translates to:
  /// **'You need to create a trip first before adding train information.'**
  String get needCreateTripFirstToAddTrainInfo;

  /// Generic error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Button label to add trains
  ///
  /// In en, this message translates to:
  /// **'Add Trains'**
  String get addTrains;

  /// Header indicating how many train segments were found
  ///
  /// In en, this message translates to:
  /// **'Found {count} train segments:'**
  String foundTrainSegments(int count);

  /// Label for departure station
  ///
  /// In en, this message translates to:
  /// **'From: {station}'**
  String fromLabel(String station);

  /// Label for arrival station
  ///
  /// In en, this message translates to:
  /// **'To: {station}'**
  String toLabel(String station);

  /// Label for platform number
  ///
  /// In en, this message translates to:
  /// **'Platform {platform}'**
  String platformLabel(String platform);

  /// Title for the web image search view
  ///
  /// In en, this message translates to:
  /// **'Search Web Images'**
  String get searchWebImagesTitle;

  /// Generic select action label
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Generic search action label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Hint text in the web image search field
  ///
  /// In en, this message translates to:
  /// **'Search for images...'**
  String get searchImagesHint;

  /// Error message when image search fails
  ///
  /// In en, this message translates to:
  /// **'Error searching for images: {message}'**
  String errorSearchingImages(String message);

  /// Error message when image download fails
  ///
  /// In en, this message translates to:
  /// **'Error downloading image: {message}'**
  String errorDownloadingImage(String message);

  /// Validation when search term is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a search term'**
  String get pleaseEnterSearchTerm;

  /// Info text when no images are found
  ///
  /// In en, this message translates to:
  /// **'No images found. Try searching for something.'**
  String get noImagesFoundTrySearching;

  /// Status text shown while downloading an image
  ///
  /// In en, this message translates to:
  /// **'Downloading image...'**
  String get downloadingImage;

  /// Button label to go back to search results
  ///
  /// In en, this message translates to:
  /// **'Back to results'**
  String get backToResults;

  /// Button label to confirm selected image
  ///
  /// In en, this message translates to:
  /// **'Use this image'**
  String get useThisImage;

  /// Overlay showing image author
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String imageByAuthor(String author);

  /// Snackbar shown when a reservation has been added
  ///
  /// In en, this message translates to:
  /// **'Reservation added successfully'**
  String get reservationAddedSuccessfully;

  /// Error when adding reservation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add reservation: {message}'**
  String failedToAddReservation(String message);
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
