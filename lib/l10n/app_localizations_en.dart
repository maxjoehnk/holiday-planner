// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Holiday Planner';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get useSystemTheme => 'Use system theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSection => 'Language';

  @override
  String get useSystemLanguage => 'Use system language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get aboutSection => 'About';

  @override
  String aboutAppWithVersion(String version) {
    return 'Holiday Planner App $version';
  }

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get navTrips => 'Trips';

  @override
  String get navPackingLists => 'Packing Lists';

  @override
  String get tripFilterUpcoming => 'Upcoming';

  @override
  String get tripFilterPast => 'Past';

  @override
  String get newTrip => 'New Trip';

  @override
  String get addItem => 'Add Item';

  @override
  String get noPackingItemsTitle => 'No packing items';

  @override
  String get noPackingItemsSubtitle =>
      'Add items to your packing list to get started!';

  @override
  String itemsCount(num count) {
    return '$count items';
  }

  @override
  String get deleteItemTooltip => 'Delete item';

  @override
  String quantityFixed(num count) {
    return '$count fixed';
  }

  @override
  String quantityPerDay(num count) {
    return '$count per day';
  }

  @override
  String quantityPerNight(num count) {
    return '$count per night';
  }

  @override
  String get noQuantityConfigured => 'No quantity configured';

  @override
  String get createTripTitle => 'Create Trip';

  @override
  String get create => 'Create';

  @override
  String get addHeaderImage => 'Add Header Image';

  @override
  String get tripDetails => 'Trip Details';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get tripName => 'Trip Name';

  @override
  String get travelDates => 'Travel Dates';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get destination => 'Destination';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get deviceGallery => 'Device Gallery';

  @override
  String get webSearch => 'Web Search';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get noDataFound => 'No data found';

  @override
  String get confirmTrainInformation => 'Confirm Train Information';

  @override
  String get confirmAndSelectTrip => 'Confirm & Select Trip';

  @override
  String get noTripsAvailable => 'No Trips Available';

  @override
  String get addTrainInformationTitle => 'Add Train Information';

  @override
  String get selectTripToAddTrainInfo =>
      'Select a trip to add the train information to:';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get noAttachmentsTitle => 'No attachments';

  @override
  String get noAttachmentsSubtitle =>
      'Add files to keep important documents with your trip';

  @override
  String get noAttachmentsAddedYet => 'No attachments added yet';

  @override
  String failedToDeleteTripWithError(String error) {
    return 'Failed to delete trip: $error';
  }

  @override
  String get weatherLabel => 'Weather';

  @override
  String get weatherSunny => 'Sunny';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherConditionTitle => 'Weather Condition';

  @override
  String get weatherConditionDescription =>
      'Set the weather condition and minimum probability for this item to be included in your packing list.';

  @override
  String get minimumProbabilityLabel => 'Minimum Probability (%)';

  @override
  String get minimumProbabilityHint => 'Enter probability (0-100)';

  @override
  String get enterProbabilityValidation => 'Please enter a probability';

  @override
  String get enterValidNumberValidation => 'Please enter a valid number';

  @override
  String get probabilityRangeValidation =>
      'Probability must be between 0 and 100';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get weatherForecastTitle => 'Weather Forecast';

  @override
  String chanceOfRainPercent(num percent) {
    return '$percent% chance of rain';
  }

  @override
  String get addConditionTitle => 'Add Condition';

  @override
  String get conditionSelectorIntro =>
      'Choose when this item should be included in your packing list:';

  @override
  String get conditionMinTripDurationTitle => 'Min Trip Duration';

  @override
  String get conditionMinTripDurationSubtitle =>
      'Include for trips longer than X days';

  @override
  String get conditionMaxTripDurationTitle => 'Max Trip Duration';

  @override
  String get conditionMaxTripDurationSubtitle =>
      'Include for trips shorter than X days';

  @override
  String get conditionMinTemperatureTitle => 'Min Temperature';

  @override
  String get conditionMinTemperatureSubtitle =>
      'Include when temperature is above X°C';

  @override
  String get conditionMaxTemperatureTitle => 'Max Temperature';

  @override
  String get conditionMaxTemperatureSubtitle =>
      'Include when temperature is below X°C';

  @override
  String get conditionWeatherTitle => 'Weather Condition';

  @override
  String get conditionWeatherSubtitle => 'Include based on weather forecast';

  @override
  String get conditionTripTagTitle => 'Trip Tag';

  @override
  String get conditionTripTagSubtitle => 'Include when trip has a specific tag';

  @override
  String get conditionPollenTitle => 'Pollen';

  @override
  String get conditionPollenSubtitle =>
      'Include when pollen forecast exceeds a threshold';

  @override
  String get pollenSelectorTitle => 'Pollen Forecast';

  @override
  String get pollenSelectorDescription =>
      'Pack this item when the forecast for the trip period reaches the chosen pollen index.';

  @override
  String get pollenTypeLabel => 'Pollen type';

  @override
  String get pollenTypeGrass => 'Grass';

  @override
  String get pollenTypeTree => 'Tree';

  @override
  String get pollenTypeWeed => 'Weed';

  @override
  String pollenIndexLabel(int value) {
    return 'Minimum pollen index: $value';
  }

  @override
  String get pollenDailyTitle => 'Daily Pollen';

  @override
  String get pollenNoData => 'No pollen data available';

  @override
  String get temperatureSelectorMinTitle => 'Min Temperature';

  @override
  String get temperatureSelectorMaxTitle => 'Max Temperature';

  @override
  String get temperatureSelectorMinDescription =>
      'Set the minimum temperature for this item to be included in your packing list.';

  @override
  String get temperatureSelectorMaxDescription =>
      'Set the maximum temperature for this item to be included in your packing list.';

  @override
  String get temperatureFieldLabel => 'Temperature (°C)';

  @override
  String get temperatureFieldHint => 'Enter temperature';

  @override
  String get temperatureValidationEmpty => 'Please enter a temperature';

  @override
  String get temperatureValidationNaN => 'Please enter a valid number';

  @override
  String get tripDurationSelectorMinTitle => 'Min Trip Duration';

  @override
  String get tripDurationSelectorMaxTitle => 'Max Trip Duration';

  @override
  String get tripDurationSelectorMinDescription =>
      'Set the minimum trip duration for this item to be included in your packing list.';

  @override
  String get tripDurationSelectorMaxDescription =>
      'Set the maximum trip duration for this item to be included in your packing list.';

  @override
  String get tripDurationFieldLabel => 'Duration (days)';

  @override
  String get tripDurationFieldHint => 'Enter number of days';

  @override
  String get tripDurationValidationEmpty => 'Please enter a duration';

  @override
  String get tripDurationValidationNaN => 'Please enter a valid number';

  @override
  String get tripDurationValidationGtZero => 'Duration must be greater than 0';

  @override
  String get tagSelectorEditTitle => 'Edit Tag';

  @override
  String get tagSelectorSelectTitle => 'Select Tag';

  @override
  String get tagSelectorEditPrompt =>
      'Choose a different tag for this condition:';

  @override
  String get tagSelectorSelectPrompt =>
      'Choose a tag that must be associated with the trip:';

  @override
  String get newTag => 'New Tag';

  @override
  String get failedToLoadTags => 'Failed to load tags';

  @override
  String get noTagsAvailable => 'No tags available';

  @override
  String get createFirstTagHint =>
      'Create your first tag to use it as a condition';

  @override
  String get createNewTagTitle => 'Create New Tag';

  @override
  String get tagNameLabel => 'Tag Name';

  @override
  String get tagNameHint => 'e.g., Beach, City, Adventure';

  @override
  String get tagNameValidationEmpty => 'Please enter a tag name';

  @override
  String get bookingsTitle => 'Bookings';

  @override
  String get noBookingsTitle => 'No bookings';

  @override
  String get noBookingsSubtitle =>
      'Add reservations and car rental bookings for your trip';

  @override
  String get addBookingTitle => 'Add Booking';

  @override
  String get addReservationOptionTitle => 'Add Reservation';

  @override
  String get addReservationOptionSubtitle =>
      'Restaurant, hotel, or other booking';

  @override
  String get addCarRentalOptionTitle => 'Add Car Rental';

  @override
  String get addCarRentalOptionSubtitle => 'Car rental booking';

  @override
  String get openLink => 'Open Link';

  @override
  String get deleteReservationTitle => 'Delete Reservation';

  @override
  String deleteReservationConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String errorDeletingReservation(String message) {
    return 'Error deleting reservation: $message';
  }

  @override
  String get deleteCarRentalTitle => 'Delete Car Rental';

  @override
  String deleteCarRentalConfirm(String provider) {
    return 'Are you sure you want to delete the $provider rental?';
  }

  @override
  String errorDeletingCarRental(String message) {
    return 'Error deleting car rental: $message';
  }

  @override
  String get locationsTitle => 'Locations';

  @override
  String locationAddedSuccessfully(String name) {
    return 'Location \"$name\" added successfully';
  }

  @override
  String failedToAddLocation(String message) {
    return 'Failed to add location: $message';
  }

  @override
  String get deleteLocationTitle => 'Delete Location';

  @override
  String deleteLocationConfirm(String city) {
    return 'Are you sure you want to delete \"$city\"? This action cannot be undone.';
  }

  @override
  String locationDeleted(String city) {
    return 'Location \"$city\" deleted successfully';
  }

  @override
  String failedToDeleteLocation(String message) {
    return 'Failed to delete location: $message';
  }

  @override
  String get coastal => 'coastal';

  @override
  String get inland => 'inland';

  @override
  String coastalStatusUpdated(String status) {
    return 'Coastal status updated to $status';
  }

  @override
  String failedToUpdateCoastal(String message) {
    return 'Failed to update coastal status: $message';
  }

  @override
  String get locationNotFound => 'Location not found';

  @override
  String get accommodationsTitle => 'Accommodations';

  @override
  String get addAccommodation => 'Add Accommodation';

  @override
  String get editAccommodationTitle => 'Edit Accommodation';

  @override
  String get deleteAccommodationTitle => 'Delete Accommodation';

  @override
  String deleteAccommodationConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get chooseDifferentFile => 'Choose Different File';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get editTripTitle => 'Edit Trip';

  @override
  String get deleteTripTitle => 'Delete Trip';

  @override
  String get editLabel => 'Edit';

  @override
  String get pointsOfInterestTitle => 'Points of Interest';

  @override
  String get addPointOfInterest => 'Add Point of Interest';

  @override
  String get editPointOfInterestTitle => 'Edit Point of Interest';

  @override
  String get deletePointOfInterestTitle => 'Delete Point of Interest';

  @override
  String deletePointOfInterestConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String errorDeletingPointOfInterest(String message) {
    return 'Error deleting point of interest: $message';
  }

  @override
  String get pointOfInterestLabel => 'Point of Interest';

  @override
  String get accommodationLabel => 'Accommodation';

  @override
  String get checkInLabel => 'Check-in';

  @override
  String get checkOutLabel => 'Check-out';

  @override
  String get notesLabel => 'Notes';

  @override
  String get noWeatherData => 'No weather data';

  @override
  String get highTide => 'High';

  @override
  String get lowTide => 'Low';

  @override
  String tideAtTime(String tide, String time) {
    return '$tide tide at $time';
  }

  @override
  String get summaryTab => 'Summary';

  @override
  String get mapTab => 'Map';

  @override
  String get attachmentsTab => 'Attachments';

  @override
  String get plannerTab => 'Planner';

  @override
  String dayPlannerDayLabel(int n) {
    return 'Day $n';
  }

  @override
  String get dayPlannerTitleHint => 'Untitled day';

  @override
  String get dayPlannerUnassigned => 'Unassigned';

  @override
  String get dayPlannerAddLocation => 'Add a location';

  @override
  String get dayPlannerLocationsSheetTitle => 'Day locations';

  @override
  String get dayPlannerPrimaryBadge => 'Primary';

  @override
  String get dayPlannerRemoveFromDay => 'Move to unassigned';

  @override
  String get dayPlannerEmptyDayHint => 'Nothing scheduled for this day yet.';

  @override
  String get dayPlannerAddToDay => 'Add to day';

  @override
  String dayPlannerAddSheetTitle(String label) {
    return 'Add to $label';
  }

  @override
  String get dayPlannerAddSheetEmpty => 'No items available to schedule.';

  @override
  String get dayPlannerFromUnassigned => 'Unassigned';

  @override
  String get dayPlannerFromOtherDays => 'From other days';

  @override
  String get dayPlannerMoveToDay => 'Move to a different day';

  @override
  String dayPlannerUnassignedSectionTitle(int count) {
    return 'Unassigned ($count)';
  }

  @override
  String get noTripsFoundTitle => 'No trips found';

  @override
  String get noTripsFoundSubtitle => 'Start planning your next adventure!';

  @override
  String get oneDay => '1 day';

  @override
  String daysCount(num count) {
    return '$count days';
  }

  @override
  String get changeHeaderImage => 'Change Header Image';

  @override
  String get addCarRentalPageTitle => 'Add Car Rental';

  @override
  String get pleaseFillRequiredFields => 'Please fill in all required fields';

  @override
  String get carRentalAddedSuccessfully => 'Car rental added successfully';

  @override
  String failedToAddCarRental(String message) {
    return 'Failed to add car rental: $message';
  }

  @override
  String get trainInfoAddedSuccessfully =>
      'Train information added successfully!';

  @override
  String get needCreateTripFirstToAddTrainInfo =>
      'You need to create a trip first before adding train information.';

  @override
  String get errorTitle => 'Error';

  @override
  String get addTrains => 'Add Trains';

  @override
  String foundTrainSegments(int count) {
    return 'Found $count train segments:';
  }

  @override
  String fromLabel(String station) {
    return 'From: $station';
  }

  @override
  String toLabel(String station) {
    return 'To: $station';
  }

  @override
  String platformLabel(String platform) {
    return 'Platform $platform';
  }

  @override
  String get searchWebImagesTitle => 'Search Web Images';

  @override
  String get select => 'Select';

  @override
  String get search => 'Search';

  @override
  String get searchImagesHint => 'Search for images...';

  @override
  String errorSearchingImages(String message) {
    return 'Error searching for images: $message';
  }

  @override
  String errorDownloadingImage(String message) {
    return 'Error downloading image: $message';
  }

  @override
  String get pleaseEnterSearchTerm => 'Please enter a search term';

  @override
  String get noImagesFoundTrySearching =>
      'No images found. Try searching for something.';

  @override
  String get downloadingImage => 'Downloading image...';

  @override
  String get backToResults => 'Back to results';

  @override
  String get useThisImage => 'Use this image';

  @override
  String imageByAuthor(String author) {
    return 'By $author';
  }

  @override
  String get reservationAddedSuccessfully => 'Reservation added successfully';

  @override
  String failedToAddReservation(String message) {
    return 'Failed to add reservation: $message';
  }
}
