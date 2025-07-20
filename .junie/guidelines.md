# Holiday Planner Application Architecture Guidelines

## Overview

Cross-platform mobile app using Flutter frontend + Rust backend, connected via Flutter Rust Bridge (FRB).

## Architecture

Flutter handles UI with Material3 design, while Rust manages all business logic, database operations, and external integrations. Communication flows through generated bridge code.

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
