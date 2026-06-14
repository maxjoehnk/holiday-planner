# Supabase

Cloud schema and configuration for Trippy's cross-device sync.

## Layout

- `migrations/` — SQL migrations applied via the Supabase CLI (`supabase db push`).

## Local-only tables (not synced)

By design, these stay on-device and are intentionally absent from the cloud schema:

- `packing_list_entries`, `packing_list_groups`, `packing_list_conditions` — personal library
- `trip_packing_list_entry` — regenerated per device from the local library
- `weather_forecast`, `weather_daily_forecast`, `weather_hourly_forecast` — fetched per device
- `tidal_information` — fetched per device

## Build order

See top-level project plan. This directory ships incrementally:

1. ✅ Initial schema with sync metadata (`20260612120000_initial_schema.sql`)
2. RLS policies based on `trip_members` (step 7)
3. Storage bucket + policies for attachments (step 6)
