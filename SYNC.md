# Trip Synchronization

Optional, opt-in cross-device sync and collaboration for Holiday Planner, on
top of Supabase (Postgres + Auth + Storage + Realtime). Local-first stays the
default — every feature works fully offline as an anonymous user.

---

## What the user sees

### Anonymous (default)

Nothing changes. The app boots into local-only mode. Every feature works.
There's a "Sign in" button on the home screen; you can ignore it forever.

### Signing in

Tap "Sign in" → enter email → magic link → tap the link in the mail client.
On desktop the redirect is captured by a one-shot loopback HTTP server; on
mobile a deep link handles it. The home screen now shows your account chip.

### Backfilling anonymous trips

If you created trips before signing in, the home screen offers
"Upload _N_ trips to your account". One tap claims them all for your account
and pushes the whole subtree (locations, accommodations, bookings, transits,
attachments, header images, …) to the server. You can also upload a single
trip at a time via the cloud icon on its card.

### Working across devices

Once signed in, every edit on Device A appears on Device B within seconds
(realtime), and reconciles on the next 30 s pull tick as a backstop. The
trip list, trip overview, and every nested view (members, activity,
accommodations, …) re-render automatically via `DataChangeBus`.

### Sharing a trip

Open a trip → the sync chip in the app bar opens a sheet listing members.
"Invite by email" sends an invite. If the invitee already has an account
the trip lands on their list on their next sign-in (or immediately if
online); if not, the invite waits in `trip_invites` until they sign up.
The invite RPC always returns the same shape — the caller can't tell from
the response whether the email is already registered (closes the
account-existence oracle).

### Members

Every member of a trip can edit every part of the trip, invite others,
remove others, and revoke pending invites. The owner is shown with an
"Owner" badge. Only the owner can hard-delete the trip from the cloud;
members can only "leave" it (soft-deletes their `trip_members` row).

### Activity log

A timeline icon in the app bar opens an activity log: every insert /
update / delete across the trip, with the actor's display name + relative
timestamp.

### Tags

Tags are a **global, append-only library** with content-addressed ids
(uuid v5 over the lowercased name). Two users typing "Beach" end up with
the same row. You only see tags you've used yourself (your `user_tags`
library) plus tags linked to trips you can access — the full library
isn't browsable.

"Rename" and "Delete" actions on each tag chip are scoped to your
library: rename swaps the tag on every trip you own, delete removes it
from your library + your owned trips. The global tag row stays put;
other people's libraries and trips are untouched.

### Detached trips

If the trip owner deletes a shared trip, the other members keep their
last-pulled snapshot as a read-only "detached" trip (sync chip shows
"cloud_off" amber). They can re-claim it under their own account, which
re-uploads the entire subtree as if it were a fresh anonymous trip
they're now backfilling.

### Account screen

From the home menu: shows your email, lets you edit your display name,
sign out, or delete the account. Delete-account scrubs all server-side
data (trips, members, profiles, invites) and every Storage object you
uploaded (matched by `storage.objects.owner = me`).

### Sign-out

Outbox is drained best-effort against the still-valid token (5 s
timeout), then cleared. Trips and local data stay on the device. Signing
back in as the same user picks them up unchanged; signing in as a
different user starts from their server state without dead-lettering the
previous user's pending writes.

---

## Architecture

### Layout

| Layer | Where |
|---|---|
| Auth (magic link) | `lib/services/auth_service.dart` — owns the Supabase Flutter client |
| Sync API surface | `rust/src/api/{sync,sharing,activity,events}.rs` |
| Sync engine | `rust/src/sync/{coordinator,pull,push,realtime,apply,backfill,session,http,wire,status}.rs` |
| Handlers | `rust/src/handlers/{tag,trip,sharing,activity,attachment,…}_handler.rs` — they enqueue mutations |
| Local persistence | SQLite via SeaORM, extended with `pending_mutations`, `sync_cursors`, `profiles`, `trip_members`, `trip_activity`, `user_tags` and the sync metadata columns on every existing table (incl. `trip_days`, `trip_day_locations`, `routes`) |
| Server schema | `supabase/migrations/20260612000000_sync.sql` (single squashed file) |
| Local migration | `rust/migration/src/sync_up.sql` + `sync_down.sql` |

### High-level data flow

```
Flutter UI
   │  (write)                       (read)
   ▼                                  ▲
Handler ──► local SQLite ──► UI events (DataChangeBus)
   │              ▲
   │              │ apply
   ▼              │
pending_mutations │
   │              │
   │     ┌────────┴───────┐
   ▼     ▼                │
push.rs  realtime.rs ─── apply.rs
   │     ▲                │
   ▼     │                │
Supabase Postgres ◄── pull.rs (periodic + on-wake)
```

Every local edit goes through a handler, which writes to SQLite **and**
enqueues a `pending_mutations` row. A background push worker drains the
queue against PostgREST. In parallel, the realtime WebSocket and a
periodic pull bring server-side changes back. Apply uses LWW
(updated_at, with delete tombstones always winning) to merge into local.

### Conflict resolution

- LWW on `updated_at`. Tombstones (`deleted_at IS NOT NULL`) always win
  over later non-delete writes, so a delete is terminal.
- Conditional PATCH on push: `id=eq.<id>&deleted_at=is.null` filter so a
  late-arriving non-delete can't resurrect a server tombstone. If the
  PATCH matches 0 rows we fall back to INSERT; 409 conflict = "row
  exists and is tombstoned, drop this mutation".
- Tags + user_tags follow a simpler path: INSERT-only, treat 409 as
  success (they're append-only).

### Detached-trip preservation

When the server-side trip row is gone (owner hard-deleted) but the
member still has a local copy, the apply layer sets
`trips.detached_at = now()` and `owner_id = null` instead of
hard-deleting locally. The UI gates editing/sharing on
`is_detached`; "Sync to my account" hits the normal `upload_trip`
backfill path.

### Header images

Per-trip header image bytes live in `attachments` Storage at
`trips/<trip_id>/header_<random>` (the `attachments` bucket is reused).
Trips carry `header_image_path`, `header_image_sha256`,
`header_image_uploaded_at`. Push uploads bytes before patching the row.
Apply downloads when remote sha differs from local.

### Day planner

`trip_days` (one row per calendar day inside a trip's range) and the
`trip_day_locations` composite-PK join sync the same way trip_tags does:
trip_day_locations soft-deletes via patch_by_query, trip_days uses the
standard conditional-PATCH-with-INSERT-fallback path.

`points_of_interest` and `routes` carry `trip_day_id` + `day_order` +
`scheduled_at` for planner assignment. The assignment columns ride
along with the regular sub-table sync — when the user re-orders items
or assigns them to a day, the host row's `updated_at` bumps and the
push worker patches the new values.

`routes` is a fully synced trip-scoped entity (Komoot tour metadata +
polyline). The first push of a tour creates the global row; subsequent
edits go through the same LWW path as other trip-scoped tables.

`accommodation.coordinates_latitude/longitude` is also synced so the
map view sees the same accommodation pin on every device. The weather
+ pollen `*_last_updated` columns stay per-device (background-job
caches).

### Tags

Two tables:

- `public.tags(id, name, updated_at)` — global, append-only. Id is
  `uuid_v5(TAG_NAMESPACE, lowercase(name))` so any client deriving the
  id arrives at the same value. The unique index on `lower(name)` is
  belt-and-braces.
- `public.user_tags(user_id, tag_id, added_at, updated_at, deleted_at)`
  — per-user library + sync key. RLS lets you read tags via your
  `user_tags` rows OR via `trip_tags` linked to a trip you can access.
  Writes restricted to your own row (insert + update; no delete — the
  `deleted_at` flag carries the "forget" intent).

### Sign-out

`session::clear_auth_session`:
1. Best-effort `drain_now` with a 5 s timeout (uses the still-valid JWT).
2. `clear_queue` wipes any remaining `pending_mutations` so the next
   sign-in (possibly as a different user) doesn't dead-letter prior
   writes under a foreign RLS context.
3. `coordinator::stop` + token clear + `SignedOut` broadcast.

### Coordinator wake

When a `trip_members` row for "self" arrives (you got added to a new
trip), `apply_trip_member` calls `coordinator::request_pull()`. The
alive loop selects on the wake signal so the trip's subtree pulls
within ~milliseconds instead of waiting for the next 30 s tick.

### Realtime

Hand-rolled Phoenix v2 client over `tokio-tungstenite`. JWT goes in the
`phx_join` payload's `access_token` field. `subscribe → pull →
go_live` pattern with an in-memory buffer to bridge the catch-up
pull. Heartbeat every 25 s.

REPLICA IDENTITY FULL is set on every published table so DELETE events
carry the row id (default identity emits an empty old-record on DELETE
and the client can't reconcile).

### Anon role lockdown

The anon role gets `REVOKE ALL` on the `public` schema; everything
flows through the `authenticated` role with explicit grants.
`SECURITY DEFINER` helpers (`user_owns_trip`, `user_is_trip_member`,
`user_can_access_trip`) break the trips ↔ trip_members RLS recursion
without leaking writeable access.

### Push worker hardening

- Single worker via `WORKER_STARTED` AtomicBool; re-invocation is a
  no-op.
- Per-mutation try/catch: writes `attempts` + `last_error` to the
  failed row, dead-letters after 10 attempts, stops the drain after 3
  consecutive failures (treats as a systemic issue and lets the next
  tick retry).
- Conditional PATCH path skips when `is_join_table(table)` for the
  Delete branch (soft-delete via `patch_by_query`).

---

## What's still missing

These are the items from the most recent review rounds that didn't get
fixed in this branch. They don't block enabling sync internally but
should be addressed before public release.

### Correctness / data integrity

- **Old header-image Storage objects orphan on every byte change.**
  `trip_handler::update_trip` mints a new `header_image_path` when the
  bytes change; the previous path is overwritten in the local row and
  never scrubbed from the bucket. Fix: track previous paths and
  include them in the delete scrub payload, or scrub the old path at
  update time.
- **`resolve_header_image` wipes local bytes when remote ships a path
  without a sha.** Partial server-side row triggers permanent local
  data loss. Treat `path.is_some() && sha.is_none()` as a warning-skip.
- **TOCTOU between `upload_trip_header_if_needed` and
  `refresh_payload`.** Two separate DB reads during push can see
  different state if `update_trip` runs in between. Read once into a
  snapshot.
- **`apply_trip` clobbers the uploading device's local
  `header_image_uploaded_at`.** A pull arriving between local enqueue
  and push downgrades `uploaded_at` to null and the worker re-uploads.
  Don't overwrite a non-null local value with a null incoming one.
- **Push worker race with sign-out drain.** No mutex between the
  background drain and `drain_now`. Both can fetch the same batch.
  Idempotent on the server but bumps `attempts` spuriously. Add a
  `tokio::sync::Mutex<()>` around the drain body.
- **`WORKER_STARTED` is never reset on sign-out.** Latent — only one
  call site sets `DB_HANDLE` today — but the guard contract is broken.
- **5 s drain timeout is shorter than a single PostgREST request
  timeout (30 s).** Most pending edits get wiped on sign-out under
  normal mobile network conditions. Either raise the timeout with a UI
  indicator or filter the wipe to mutations created in the current
  session.
- **Resurrection vector via PATCH-then-INSERT in apply.** Closed for
  every non-tag table via the conditional PATCH (`deleted_at=is.null`
  filter). Confirm there's no other entry point that re-inserts a
  tombstoned row.

### Server-side

- **`last_modified_by` columns lack FK to `auth.users`.** Becomes a
  dangling uuid after account deletion. Add `references auth.users(id)
  on delete set null` across the sub-tables.
- **`trip_invites` is in the realtime publication.** Clients never
  pull or apply it; remove it from `supabase_realtime` to avoid
  leaking invite emails over the websocket to other trip members.
- **`trip_invites.invited_by` has no cascade.** `delete_my_account`
  cleans them manually, but any other deletion path (Supabase
  dashboard, future RPC) blocks on the FK. Add
  `on delete cascade` or `set null`.
- **`profiles_update_self` policy permits any column overwrite.** A
  caller can PATCH their own `email` field with any string. Lock the
  WITH CHECK to the immutable columns, or move display-name updates
  behind a SECURITY DEFINER RPC.
- **Storage scrub by `owner = me`.** Matches files the caller
  uploaded into trips they don't own — but Supabase's `storage.objects.owner`
  is nullable, so files uploaded before Supabase started stamping it
  (or via service-role) survive. Document in the runbook.
- **Activity log triggers don't cover `attachments`, `trip_members`,
  `trip_invites`, `tags`.** Decide intentional vs gap and either add
  the triggers or document the omission inline.
- **Missing index on `lower(trip_invites.email)`** for the
  `handle_new_user` + `claim_pending_invites_for` lookups on every
  signup / sign-in.
- **Anonymous tag's `user_tags` aren't claimed at sign-in / backfill.**
  Backfill only stamps user_tags for tags linked to claimed trips; a
  local anonymous tag that's never been put on a trip stays with no
  user_tags row, so other devices won't see it. Add a "claim every
  local tag" pass to backfill.

### UX

- **Sign-out doesn't unlink local trips.** Multi-user device shares
  data across accounts. Decide: hide non-owned trips in the list
  query, unlink on sign-out, or document as single-user-per-device.
- **Push errors emit `SyncStatus::Error` on every retry.** A JWT
  refresh window or brief network blip produces a toast storm. Only
  emit `Error` at dead-letter; emit `Offline` for transient retries.
- **Detached trip share view doesn't disable sharing actions.** RPCs
  fail with cryptic errors instead of being grayed out.
- **No "outbound invites" empty state.** The pending-invites section
  shows nothing if no invites exist — fine, but the `created_at`
  field is parsed and dropped. "Invited X days ago" is a small UX
  win.
- **Activity log on detached trips silently freezes.** Show a banner:
  "Activity stopped when the original owner deleted this trip".
- **No retry / dead-letter inspection UI.** Mutations dead-lettered
  after 10 attempts sit invisibly in `pending_mutations` with
  `last_error` set. Need an admin / developer view.

### Realtime

- **Heartbeat ack isn't validated.** Phoenix `phx_reply` to a
  heartbeat is dropped. A half-dead socket can sit delivering nothing
  until the next reconnect cycle. Track the pending heartbeat ref and
  fail the session if N intervals pass with no ack.
- **JWT refresh not wired into the live channel.** Token is read once
  per `run_session`. When Dart refreshes mid-session the channel keeps
  using the old JWT until reconnect; RLS-gated events silently drop.
  Watch for token-refresh broadcasts and push a fresh `access_token`
  message per topic.
- **`phx_join` ack errors aren't surfaced.** A `phx_reply` with
  `status: "error"` (e.g. `invalid_claim`) is treated as a no-op and
  the channel sits delivering nothing.
- **Buffer is unbounded.** If `pull_all` keeps failing during the
  catch-up phase the in-memory event buffer grows without limit. Cap
  at ~2 000 events with overflow → trigger a fresh pull.

### Schema / data model

- **Trip ↔ packing-list tag-condition matching is per-uuid only.** A
  tag condition bound to your "Beach" doesn't match a shared trip
  tagged by the owner's "Beach" — same name, same uuid (deterministic
  ids fixed this), so OK in the new model. But anonymous-mode users
  who imported packing list templates from before deterministic ids
  may still have stale tag_ids that won't match. Document or migrate.

### Tooling / process

- **No integration tests for sync flows.** The Overpass live-API
  tests in `rust/src/third_party/overpass.rs` are pre-existing and
  flaky. The sync paths have unit coverage in the apply / push
  modules but no end-to-end. Add a fixture that boots a local
  Supabase, signs in, performs a trip edit on one client, and asserts
  it lands on another.
- **No `supabase db reset` automation.** Schema changes today require
  manual `supabase db reset` before testing. Wire into the build
  scripts or document.
- **Migration file is squashed.** Once production is enabled this
  needs to become a series of incremental migrations.
