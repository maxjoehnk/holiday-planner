// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Holiday Planner';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get appearanceSection => 'Darstellung';

  @override
  String get useSystemTheme => 'Systemdesign verwenden';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageSection => 'Sprache';

  @override
  String get useSystemLanguage => 'Systemsprache verwenden';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get aboutSection => 'Über';

  @override
  String aboutAppWithVersion(String version) {
    return 'Urlaubsplaner App $version';
  }

  @override
  String get homeSettingsTooltip => 'Einstellungen';

  @override
  String get navTrips => 'Reisen';

  @override
  String get navPackingLists => 'Packlisten';

  @override
  String get tripFilterUpcoming => 'Bevorstehend';

  @override
  String get tripFilterPast => 'Vergangen';

  @override
  String get newTrip => 'Neue Reise';

  @override
  String get addItem => 'Element hinzufügen';

  @override
  String get noPackingItemsTitle => 'Keine Packlisten-Einträge';

  @override
  String get noPackingItemsSubtitle =>
      'Füge Elemente zu deiner Packliste hinzu, um zu starten!';

  @override
  String itemsCount(num count) {
    return '$count Elemente';
  }

  @override
  String get deleteItemTooltip => 'Element löschen';

  @override
  String quantityFixed(num count) {
    return '$count gesamt';
  }

  @override
  String quantityPerDay(num count) {
    return '$count pro Tag';
  }

  @override
  String quantityPerNight(num count) {
    return '$count pro Nacht';
  }

  @override
  String get noQuantityConfigured => 'Keine Menge konfiguriert';

  @override
  String get createTripTitle => 'Reise erstellen';

  @override
  String get create => 'Erstellen';

  @override
  String get addHeaderImage => 'Kopfzeilenbild hinzufügen';

  @override
  String get tripDetails => 'Reisedetails';

  @override
  String get pleaseEnterName => 'Bitte einen Namen eingeben';

  @override
  String get tripName => 'Reisename';

  @override
  String get travelDates => 'Reisedaten';

  @override
  String get startDate => 'Startdatum';

  @override
  String get endDate => 'Enddatum';

  @override
  String get selectDateRange => 'Datumsbereich auswählen';

  @override
  String get destination => 'Ziel';

  @override
  String get selectImageSource => 'Bildquelle auswählen';

  @override
  String get deviceGallery => 'Gerätegalerie';

  @override
  String get webSearch => 'Websuche';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get retry => 'Wiederholen';

  @override
  String get noDataFound => 'Keine Daten gefunden';

  @override
  String get confirmTrainInformation => 'Zuginformationen bestätigen';

  @override
  String get confirmAndSelectTrip => 'Bestätigen & Reise auswählen';

  @override
  String get noTripsAvailable => 'Keine Reisen verfügbar';

  @override
  String get addTrainInformationTitle => 'Zuginformationen hinzufügen';

  @override
  String get selectTripToAddTrainInfo =>
      'Wähle eine Reise aus, um die Zuginformationen hinzuzufügen:';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get noAttachmentsTitle => 'Keine Anhänge';

  @override
  String get noAttachmentsSubtitle =>
      'Füge Dateien hinzu, um wichtige Dokumente bei deiner Reise zu behalten';

  @override
  String get noAttachmentsAddedYet => 'Noch keine Anhänge hinzugefügt';

  @override
  String failedToDeleteTripWithError(String error) {
    return 'Reise konnte nicht gelöscht werden: $error';
  }

  @override
  String get weatherLabel => 'Wetter';

  @override
  String get weatherSunny => 'Sonnig';

  @override
  String get weatherCloudy => 'Bewölkt';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherSnow => 'Schnee';

  @override
  String get weatherThunderstorm => 'Gewitter';

  @override
  String get weatherConditionTitle => 'Wetterbedingung';

  @override
  String get weatherConditionDescription =>
      'Lege die Wetterbedingung und die minimale Wahrscheinlichkeit fest, damit dieses Element in die Packliste aufgenommen wird.';

  @override
  String get minimumProbabilityLabel => 'Minimale Wahrscheinlichkeit (%)';

  @override
  String get minimumProbabilityHint => 'Wahrscheinlichkeit eingeben (0-100)';

  @override
  String get enterProbabilityValidation =>
      'Bitte eine Wahrscheinlichkeit eingeben';

  @override
  String get enterValidNumberValidation => 'Bitte eine gültige Zahl eingeben';

  @override
  String get probabilityRangeValidation =>
      'Wahrscheinlichkeit muss zwischen 0 und 100 liegen';

  @override
  String get save => 'Speichern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get weatherForecastTitle => 'Wettervorhersage';

  @override
  String chanceOfRainPercent(num percent) {
    return '$percent% Regenwahrscheinlichkeit';
  }

  @override
  String get addConditionTitle => 'Bedingung hinzufügen';

  @override
  String get conditionSelectorIntro =>
      'Wähle, wann dieses Element in deine Packliste aufgenommen werden soll:';

  @override
  String get conditionMinTripDurationTitle => 'Min. Reisedauer';

  @override
  String get conditionMinTripDurationSubtitle =>
      'Für Reisen länger als X Tage einschließen';

  @override
  String get conditionMaxTripDurationTitle => 'Max. Reisedauer';

  @override
  String get conditionMaxTripDurationSubtitle =>
      'Für Reisen kürzer als X Tage einschließen';

  @override
  String get conditionMinTemperatureTitle => 'Min. Temperatur';

  @override
  String get conditionMinTemperatureSubtitle =>
      'Einbeziehen, wenn die Temperatur über X°C liegt';

  @override
  String get conditionMaxTemperatureTitle => 'Max. Temperatur';

  @override
  String get conditionMaxTemperatureSubtitle =>
      'Einbeziehen, wenn die Temperatur unter X°C liegt';

  @override
  String get conditionWeatherTitle => 'Wetterbedingung';

  @override
  String get conditionWeatherSubtitle =>
      'Basierend auf der Wettervorhersage einbeziehen';

  @override
  String get conditionTripTagTitle => 'Reise-Schlagwort';

  @override
  String get conditionTripTagSubtitle =>
      'Einbeziehen, wenn die Reise ein bestimmtes Schlagwort hat';

  @override
  String get temperatureSelectorMinTitle => 'Min. Temperatur';

  @override
  String get temperatureSelectorMaxTitle => 'Max. Temperatur';

  @override
  String get temperatureSelectorMinDescription =>
      'Lege die minimale Temperatur fest, damit dieses Element in deine Packliste aufgenommen wird.';

  @override
  String get temperatureSelectorMaxDescription =>
      'Lege die maximale Temperatur fest, damit dieses Element in deine Packliste aufgenommen wird.';

  @override
  String get temperatureFieldLabel => 'Temperatur (°C)';

  @override
  String get temperatureFieldHint => 'Temperatur eingeben';

  @override
  String get temperatureValidationEmpty => 'Bitte eine Temperatur eingeben';

  @override
  String get temperatureValidationNaN => 'Bitte eine gültige Zahl eingeben';

  @override
  String get tripDurationSelectorMinTitle => 'Min. Reisedauer';

  @override
  String get tripDurationSelectorMaxTitle => 'Max. Reisedauer';

  @override
  String get tripDurationSelectorMinDescription =>
      'Lege die minimale Reisedauer fest, damit dieses Element in deine Packliste aufgenommen wird.';

  @override
  String get tripDurationSelectorMaxDescription =>
      'Lege die maximale Reisedauer fest, damit dieses Element in deine Packliste aufgenommen wird.';

  @override
  String get tripDurationFieldLabel => 'Dauer (Tage)';

  @override
  String get tripDurationFieldHint => 'Anzahl der Tage eingeben';

  @override
  String get tripDurationValidationEmpty => 'Bitte eine Dauer eingeben';

  @override
  String get tripDurationValidationNaN => 'Bitte eine gültige Zahl eingeben';

  @override
  String get tripDurationValidationGtZero => 'Dauer muss größer als 0 sein';

  @override
  String get tagSelectorEditTitle => 'Schlagwort bearbeiten';

  @override
  String get tagSelectorSelectTitle => 'Schlagwort auswählen';

  @override
  String get tagSelectorEditPrompt =>
      'Wähle ein anderes Schlagwort für diese Bedingung:';

  @override
  String get tagSelectorSelectPrompt =>
      'Wähle ein Schlagwort, das mit der Reise verknüpft sein muss:';

  @override
  String get newTag => 'Neues Schlagwort';

  @override
  String get failedToLoadTags => 'Schlagwörter konnten nicht geladen werden';

  @override
  String get noTagsAvailable => 'Keine Schlagwörter verfügbar';

  @override
  String get createFirstTagHint =>
      'Erstelle dein erstes Schlagwort, um es als Bedingung zu verwenden';

  @override
  String get createNewTagTitle => 'Neues Schlagwort erstellen';

  @override
  String get tagNameLabel => 'Schlagwort-Name';

  @override
  String get tagNameHint => 'z. B. Strand, Stadt, Abenteuer';

  @override
  String get tagNameValidationEmpty => 'Bitte einen Schlagwort-Namen eingeben';

  @override
  String get bookingsTitle => 'Buchungen';

  @override
  String get noBookingsTitle => 'Keine Buchungen';

  @override
  String get noBookingsSubtitle =>
      'Füge Reservierungen und Mietwagenbuchungen für deine Reise hinzu';

  @override
  String get addBookingTitle => 'Buchung hinzufügen';

  @override
  String get addReservationOptionTitle => 'Reservierung hinzufügen';

  @override
  String get addReservationOptionSubtitle =>
      'Restaurant-, Hotel- oder andere Buchung';

  @override
  String get addCarRentalOptionTitle => 'Mietwagen hinzufügen';

  @override
  String get addCarRentalOptionSubtitle => 'Mietwagenbuchung';

  @override
  String get openLink => 'Link öffnen';

  @override
  String get deleteReservationTitle => 'Reservierung löschen';

  @override
  String deleteReservationConfirm(String title) {
    return 'Möchtest du \"$title\" wirklich löschen?';
  }

  @override
  String errorDeletingReservation(String message) {
    return 'Fehler beim Löschen der Reservierung: $message';
  }

  @override
  String get deleteCarRentalTitle => 'Mietwagen löschen';

  @override
  String deleteCarRentalConfirm(String provider) {
    return 'Möchtest du die $provider-Buchung wirklich löschen?';
  }

  @override
  String errorDeletingCarRental(String message) {
    return 'Fehler beim Löschen der Mietwagenbuchung: $message';
  }

  @override
  String get locationsTitle => 'Orte';

  @override
  String locationAddedSuccessfully(String name) {
    return 'Ort \"$name\" erfolgreich hinzugefügt';
  }

  @override
  String failedToAddLocation(String message) {
    return 'Ort konnte nicht hinzugefügt werden: $message';
  }

  @override
  String get deleteLocationTitle => 'Ort löschen';

  @override
  String deleteLocationConfirm(String city) {
    return 'Möchtest du \"$city\" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String locationDeleted(String city) {
    return 'Ort \"$city\" erfolgreich gelöscht';
  }

  @override
  String failedToDeleteLocation(String message) {
    return 'Fehler beim Löschen des Ortes: $message';
  }

  @override
  String get coastal => 'küstennah';

  @override
  String get inland => 'landeinwärts';

  @override
  String coastalStatusUpdated(String status) {
    return 'Küstenstatus aktualisiert auf $status';
  }

  @override
  String failedToUpdateCoastal(String message) {
    return 'Fehler beim Aktualisieren des Küstenstatus: $message';
  }

  @override
  String get locationNotFound => 'Ort nicht gefunden';

  @override
  String get accommodationsTitle => 'Unterkünfte';

  @override
  String get addAccommodation => 'Unterkunft hinzufügen';

  @override
  String get editAccommodationTitle => 'Unterkunft bearbeiten';

  @override
  String get deleteAccommodationTitle => 'Unterkunft löschen';

  @override
  String deleteAccommodationConfirm(String name) {
    return 'Möchtest du \"$name\" wirklich löschen?';
  }

  @override
  String get chooseDifferentFile => 'Andere Datei auswählen';

  @override
  String get chooseFile => 'Datei auswählen';

  @override
  String get editTripTitle => 'Reise bearbeiten';

  @override
  String get deleteTripTitle => 'Reise löschen';

  @override
  String get pointsOfInterestTitle => 'Sehenswürdigkeiten';

  @override
  String get addPointOfInterest => 'Sehenswürdigkeit hinzufügen';

  @override
  String get editPointOfInterestTitle => 'Sehenswürdigkeit bearbeiten';

  @override
  String get deletePointOfInterestTitle => 'Sehenswürdigkeit löschen';

  @override
  String deletePointOfInterestConfirm(String name) {
    return 'Möchtest du \"$name\" wirklich löschen?';
  }

  @override
  String errorDeletingPointOfInterest(String message) {
    return 'Fehler beim Löschen der Sehenswürdigkeit: $message';
  }

  @override
  String get pointOfInterestLabel => 'Sehenswürdigkeit';

  @override
  String get accommodationLabel => 'Unterkunft';

  @override
  String get checkInLabel => 'Check-in';

  @override
  String get checkOutLabel => 'Check-out';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get noWeatherData => 'Keine Wetterdaten';

  @override
  String get highTide => 'Hoch';

  @override
  String get lowTide => 'Niedrig';

  @override
  String tideAtTime(String tide, String time) {
    return '${tide}tide um $time';
  }

  @override
  String get summaryTab => 'Übersicht';

  @override
  String get timelineTab => 'Zeitstrahl';

  @override
  String get mapTab => 'Karte';

  @override
  String get attachmentsTab => 'Anhänge';

  @override
  String get plannerTab => 'Planer';

  @override
  String dayPlannerDayLabel(int n) {
    return 'Tag $n';
  }

  @override
  String get dayPlannerTitleHint => 'Tag ohne Titel';

  @override
  String get dayPlannerUnassigned => 'Nicht zugeordnet';

  @override
  String get dayPlannerAddLocation => 'Ort hinzufügen';

  @override
  String get dayPlannerLocationsSheetTitle => 'Orte des Tages';

  @override
  String get dayPlannerPrimaryBadge => 'Primär';

  @override
  String get dayPlannerRemoveFromDay => 'Aus Tag entfernen';

  @override
  String get dayPlannerEmptyDayHint => 'Noch nichts für diesen Tag geplant.';

  @override
  String get dayPlannerAddToDay => 'Zum Tag hinzufügen';

  @override
  String dayPlannerAddSheetTitle(String label) {
    return 'Zu $label hinzufügen';
  }

  @override
  String get dayPlannerAddSheetEmpty => 'Keine Einträge zum Planen verfügbar.';

  @override
  String get dayPlannerFromUnassigned => 'Nicht zugeordnet';

  @override
  String get dayPlannerFromOtherDays => 'Von anderen Tagen';

  @override
  String get dayPlannerMoveToDay => 'An einen anderen Tag verschieben';

  @override
  String dayPlannerUnassignedSectionTitle(int count) {
    return 'Nicht zugeordnet ($count)';
  }

  @override
  String get noTripsFoundTitle => 'Keine Reisen gefunden';

  @override
  String get noTripsFoundSubtitle => 'Plane dein nächstes Abenteuer!';

  @override
  String get oneDay => '1 Tag';

  @override
  String daysCount(num count) {
    return '$count Tage';
  }

  @override
  String get changeHeaderImage => 'Kopfzeilenbild ändern';

  @override
  String get addCarRentalPageTitle => 'Mietwagen hinzufügen';

  @override
  String get pleaseFillRequiredFields => 'Bitte alle Pflichtfelder ausfüllen';

  @override
  String get carRentalAddedSuccessfully => 'Mietwagen erfolgreich hinzugefügt';

  @override
  String failedToAddCarRental(String message) {
    return 'Mietwagen konnte nicht hinzugefügt werden: $message';
  }

  @override
  String get trainInfoAddedSuccessfully =>
      'Zuginformationen erfolgreich hinzugefügt!';

  @override
  String get needCreateTripFirstToAddTrainInfo =>
      'Du musst zuerst eine Reise erstellen, bevor du Zuginformationen hinzufügen kannst.';

  @override
  String get errorTitle => 'Fehler';

  @override
  String get addTrains => 'Züge hinzufügen';

  @override
  String foundTrainSegments(int count) {
    return '$count Zugverbindungen gefunden:';
  }

  @override
  String fromLabel(String station) {
    return 'Von: $station';
  }

  @override
  String toLabel(String station) {
    return 'Nach: $station';
  }

  @override
  String platformLabel(String platform) {
    return 'Gleis $platform';
  }

  @override
  String get searchWebImagesTitle => 'Webbilder suchen';

  @override
  String get select => 'Auswählen';

  @override
  String get search => 'Suchen';

  @override
  String get searchImagesHint => 'Nach Bildern suchen...';

  @override
  String errorSearchingImages(String message) {
    return 'Fehler bei der Bildsuche: $message';
  }

  @override
  String errorDownloadingImage(String message) {
    return 'Fehler beim Herunterladen des Bildes: $message';
  }

  @override
  String get pleaseEnterSearchTerm => 'Bitte einen Suchbegriff eingeben';

  @override
  String get noImagesFoundTrySearching =>
      'Keine Bilder gefunden. Versuche, nach etwas zu suchen.';

  @override
  String get downloadingImage => 'Bild wird heruntergeladen...';

  @override
  String get backToResults => 'Zurück zu den Ergebnissen';

  @override
  String get useThisImage => 'Dieses Bild verwenden';

  @override
  String imageByAuthor(String author) {
    return 'Von $author';
  }

  @override
  String get reservationAddedSuccessfully =>
      'Reservierung erfolgreich hinzugefügt';

  @override
  String failedToAddReservation(String message) {
    return 'Reservierung konnte nicht hinzugefügt werden: $message';
  }
}
