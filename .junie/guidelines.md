# Holiday Planner Application Architecture Guidelines

## Overview

Cross-platform mobile app using Flutter frontend + Rust backend, connected via Flutter Rust Bridge (FRB).

## Architecture

Flutter handles UI with Material3 design, while Rust manages all business logic, database operations, and external integrations. Communication flows through generated bridge code.
The rust backend stores data in a sqlite database.

### Key Architectural Patterns

#### Command Pattern
- Commands are simple data structures that represent operations
- Located in `commands/` directory
- Provides type safety and clear API contracts

#### Repository Pattern
- Database access is abstracted through repositories
- Each entity has its own repository (e.g., `TripsRepository`)
- Enables easy testing and database abstraction

#### Handler Pattern
- Business logic is encapsulated in handlers
- Handlers coordinate between repositories and external services
- Handlers are created through the `HandlerCreator` trait

#### API Layer
- Public API functions are exposed to Flutter through FRB
- API functions are thin wrappers around handlers
- Database connections are managed through a global `RwLock`

## Database Design

### Entity Relationships
- **Trip**: Central entity containing trip details, dates, and metadata
- **Location**: Geographic locations associated with trips
- **Accommodation**: Hotels, rentals, and other lodging options
- **Attachment**: Files (images, documents) attached to trips
- **PackingListEntry**: Items in packing lists with conditions
- **WeatherForecast**: Weather data for trip planning

## Development Workflow

### Adding New Features

#### API Endpoint Flow
1. Define command structure in `commands/`
2. Add repository method for data operations
3. Create handler to coordinate business logic
4. Expose API function in appropriate `api/` module
5. Run `flutter_rust_bridge_codegen` to regenerate bridge
6. Use generated API in Flutter views

#### Key Points
- Database uses SQLite with automatic migrations
- All business logic stays in Rust backend
- Flutter views connect via generated bridge code

## Background Jobs

The application supports background job processing for:
- Weather data fetching
- Data synchronization
- Cleanup operations

Jobs are managed through the `BackgroundJobHandler` and can be triggered via the `run_background_jobs()` API function.

## External Integrations

The application integrates with external services through the `third_party` module:
- Weather APIs for forecast data
- Map services for location data
- Cloud storage for file attachments

---

This architecture provides a solid foundation for building and maintaining the Holiday Planner application. The separation of concerns, use of established patterns, and clear module boundaries make it easy to add new features and maintain existing code.

## Localization & Translations

The app uses Flutter's gen-l10n with ARB files located in `lib/l10n/`.
- Source (base) locale file: `app_en.arb`
- Additional locales follow the same key set, e.g., `app_de.arb`
- Configuration: `l10n.yaml` (template-arb-file, output-localization-file)

Guidelines:
- All user-facing strings must be defined in ARB files. Do not hardcode strings in Dart.
- Every key should have an optional metadata entry using the `@key` object to provide `description` and, when needed, `placeholders`.
- Placeholders must include `type` and an `example` value for clarity and better tooling support.
- `example` values must be a string
- Avoid the legacy `key@placeholders` format; always use the `@key` object form.
- Use `AppLocalizations.of(context)!` to read strings in the UI.

Correct ARB format example with placeholders and description:

```
"itemsCount": "{count} items",
"@itemsCount": {
  "description": "Label indicating how many items in a category",
  "placeholders": {
    "count": {
      "type": "int",
      "example": 5
    }
  }
},
```

Coding usage examples:
- Simple string: `Text(AppLocalizations.of(context)!.settingsTitle)`
- With placeholder: `Text(AppLocalizations.of(context)!.itemsCount(7))`

Workflow for adding new strings:
1. Add the English key to `lib/l10n/app_en.arb` with an accompanying `@key` metadata object (description and placeholders if needed).
2. Add the translation to other locale files (e.g., `app_de.arb`) using the same key and placeholder names.
4. Run the Flutter build or `flutter gen-l10n` if needed; do NOT edit generated files manually.
5. Use the newly generated getters in code via `AppLocalizations`.

Supported locales:
- Declare supported locales in `MaterialApp.supportedLocales` and keep ARB files in sync.

Review checklist:
- [ ] No remaining hardcoded user-facing strings in Dart files
- [ ] All plural/variable values use placeholders
- [ ] Each key has an appropriate description in `@key`
- [ ] Locales are kept in sync across ARB files
