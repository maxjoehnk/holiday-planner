#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
typedef struct _Dart_Handle* Dart_Handle;

typedef struct DartCObject DartCObject;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_CreateTrip {
  struct wire_uint_8_list *name;
  int64_t start_date;
  int64_t end_date;
  struct wire_uint_8_list *header_image;
} wire_CreateTrip;

typedef struct wire_PackingListEntryCondition_MinTripDuration {
  uintptr_t length;
} wire_PackingListEntryCondition_MinTripDuration;

typedef struct wire_PackingListEntryCondition_MaxTripDuration {
  uintptr_t length;
} wire_PackingListEntryCondition_MaxTripDuration;

typedef struct wire_PackingListEntryCondition_MinTemperature {
  double temperature;
} wire_PackingListEntryCondition_MinTemperature;

typedef struct wire_PackingListEntryCondition_MaxTemperature {
  double temperature;
} wire_PackingListEntryCondition_MaxTemperature;

typedef struct wire_PackingListEntryCondition_Weather {
  int32_t condition;
  double min_probability;
} wire_PackingListEntryCondition_Weather;

typedef union PackingListEntryConditionKind {
  struct wire_PackingListEntryCondition_MinTripDuration *MinTripDuration;
  struct wire_PackingListEntryCondition_MaxTripDuration *MaxTripDuration;
  struct wire_PackingListEntryCondition_MinTemperature *MinTemperature;
  struct wire_PackingListEntryCondition_MaxTemperature *MaxTemperature;
  struct wire_PackingListEntryCondition_Weather *Weather;
} PackingListEntryConditionKind;

typedef struct wire_PackingListEntryCondition {
  int32_t tag;
  union PackingListEntryConditionKind *kind;
} wire_PackingListEntryCondition;

typedef struct wire_list_packing_list_entry_condition {
  struct wire_PackingListEntryCondition *ptr;
  int32_t len;
} wire_list_packing_list_entry_condition;

typedef struct wire_Quantity {
  uintptr_t *per_day;
  uintptr_t *per_night;
  uintptr_t *fixed;
} wire_Quantity;

typedef struct wire_AddPackingListEntry {
  struct wire_uint_8_list *name;
  struct wire_list_packing_list_entry_condition *conditions;
  struct wire_Quantity quantity;
} wire_AddPackingListEntry;

typedef struct wire_DeletePackingListEntry {
  struct wire_uint_8_list *id;
} wire_DeletePackingListEntry;

typedef struct wire_Coordinates {
  double latitude;
  double longitude;
} wire_Coordinates;

typedef struct wire_LocationEntry {
  struct wire_uint_8_list *name;
  struct wire_Coordinates coordinates;
  struct wire_uint_8_list *country;
} wire_LocationEntry;

typedef struct wire_AddTripLocation {
  struct wire_uint_8_list *trip_id;
  struct wire_LocationEntry location;
} wire_AddTripLocation;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_init(int64_t port_);

void wire_get_trips(int64_t port_);

void wire_create_trip(int64_t port_, struct wire_CreateTrip *command);

void wire_get_packing_list(int64_t port_);

void wire_add_packing_list_entry(int64_t port_, struct wire_AddPackingListEntry *command);

void wire_delete_packing_list_entry(int64_t port_, struct wire_DeletePackingListEntry *command);

void wire_get_trip_packing_list(int64_t port_, struct wire_uint_8_list *trip_id);

void wire_mark_as_packed(int64_t port_,
                         struct wire_uint_8_list *trip_id,
                         struct wire_uint_8_list *entry_id);

void wire_mark_as_unpacked(int64_t port_,
                           struct wire_uint_8_list *trip_id,
                           struct wire_uint_8_list *entry_id);

void wire_search_locations(int64_t port_, struct wire_uint_8_list *query);

void wire_add_trip_location(int64_t port_, struct wire_AddTripLocation *command);

void wire_run_background_jobs(int64_t port_);

struct wire_AddPackingListEntry *new_box_autoadd_add_packing_list_entry_0(void);

struct wire_AddTripLocation *new_box_autoadd_add_trip_location_0(void);

struct wire_CreateTrip *new_box_autoadd_create_trip_0(void);

struct wire_DeletePackingListEntry *new_box_autoadd_delete_packing_list_entry_0(void);

uintptr_t *new_box_autoadd_usize_0(uintptr_t value);

struct wire_list_packing_list_entry_condition *new_list_packing_list_entry_condition_0(int32_t len);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

union PackingListEntryConditionKind *inflate_PackingListEntryCondition_MinTripDuration(void);

union PackingListEntryConditionKind *inflate_PackingListEntryCondition_MaxTripDuration(void);

union PackingListEntryConditionKind *inflate_PackingListEntryCondition_MinTemperature(void);

union PackingListEntryConditionKind *inflate_PackingListEntryCondition_MaxTemperature(void);

union PackingListEntryConditionKind *inflate_PackingListEntryCondition_Weather(void);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_init);
    dummy_var ^= ((int64_t) (void*) wire_get_trips);
    dummy_var ^= ((int64_t) (void*) wire_create_trip);
    dummy_var ^= ((int64_t) (void*) wire_get_packing_list);
    dummy_var ^= ((int64_t) (void*) wire_add_packing_list_entry);
    dummy_var ^= ((int64_t) (void*) wire_delete_packing_list_entry);
    dummy_var ^= ((int64_t) (void*) wire_get_trip_packing_list);
    dummy_var ^= ((int64_t) (void*) wire_mark_as_packed);
    dummy_var ^= ((int64_t) (void*) wire_mark_as_unpacked);
    dummy_var ^= ((int64_t) (void*) wire_search_locations);
    dummy_var ^= ((int64_t) (void*) wire_add_trip_location);
    dummy_var ^= ((int64_t) (void*) wire_run_background_jobs);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_add_packing_list_entry_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_add_trip_location_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_create_trip_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_delete_packing_list_entry_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_usize_0);
    dummy_var ^= ((int64_t) (void*) new_list_packing_list_entry_condition_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) inflate_PackingListEntryCondition_MinTripDuration);
    dummy_var ^= ((int64_t) (void*) inflate_PackingListEntryCondition_MaxTripDuration);
    dummy_var ^= ((int64_t) (void*) inflate_PackingListEntryCondition_MinTemperature);
    dummy_var ^= ((int64_t) (void*) inflate_PackingListEntryCondition_MaxTemperature);
    dummy_var ^= ((int64_t) (void*) inflate_PackingListEntryCondition_Weather);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}
