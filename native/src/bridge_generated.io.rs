use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_init(port_: i64) {
    wire_init_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_trips(port_: i64) {
    wire_get_trips_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_create_trip(port_: i64, command: *mut wire_CreateTrip) {
    wire_create_trip_impl(port_, command)
}

#[no_mangle]
pub extern "C" fn wire_get_packing_list(port_: i64) {
    wire_get_packing_list_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_add_packing_list_entry(port_: i64, command: *mut wire_AddPackingListEntry) {
    wire_add_packing_list_entry_impl(port_, command)
}

#[no_mangle]
pub extern "C" fn wire_delete_packing_list_entry(
    port_: i64,
    command: *mut wire_DeletePackingListEntry,
) {
    wire_delete_packing_list_entry_impl(port_, command)
}

#[no_mangle]
pub extern "C" fn wire_get_trip_packing_list(port_: i64, trip_id: *mut wire_uint_8_list) {
    wire_get_trip_packing_list_impl(port_, trip_id)
}

#[no_mangle]
pub extern "C" fn wire_mark_as_packed(
    port_: i64,
    trip_id: *mut wire_uint_8_list,
    entry_id: *mut wire_uint_8_list,
) {
    wire_mark_as_packed_impl(port_, trip_id, entry_id)
}

#[no_mangle]
pub extern "C" fn wire_mark_as_unpacked(
    port_: i64,
    trip_id: *mut wire_uint_8_list,
    entry_id: *mut wire_uint_8_list,
) {
    wire_mark_as_unpacked_impl(port_, trip_id, entry_id)
}

#[no_mangle]
pub extern "C" fn wire_search_locations(port_: i64, query: *mut wire_uint_8_list) {
    wire_search_locations_impl(port_, query)
}

#[no_mangle]
pub extern "C" fn wire_add_trip_location(port_: i64, command: *mut wire_AddTripLocation) {
    wire_add_trip_location_impl(port_, command)
}

#[no_mangle]
pub extern "C" fn wire_run_background_jobs(port_: i64) {
    wire_run_background_jobs_impl(port_)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_add_packing_list_entry_0() -> *mut wire_AddPackingListEntry {
    support::new_leak_box_ptr(wire_AddPackingListEntry::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_add_trip_location_0() -> *mut wire_AddTripLocation {
    support::new_leak_box_ptr(wire_AddTripLocation::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_create_trip_0() -> *mut wire_CreateTrip {
    support::new_leak_box_ptr(wire_CreateTrip::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_delete_packing_list_entry_0() -> *mut wire_DeletePackingListEntry
{
    support::new_leak_box_ptr(wire_DeletePackingListEntry::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_usize_0(value: usize) -> *mut usize {
    support::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn new_list_packing_list_entry_condition_0(
    len: i32,
) -> *mut wire_list_packing_list_entry_condition {
    let wrap = wire_list_packing_list_entry_condition {
        ptr: support::new_leak_vec_ptr(<wire_PackingListEntryCondition>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}
impl Wire2Api<uuid::Uuid> for *mut wire_uint_8_list {
    fn wire2api(self) -> uuid::Uuid {
        let single: Vec<u8> = self.wire2api();
        wire2api_uuid_ref(single.as_slice())
    }
}
impl Wire2Api<AddPackingListEntry> for wire_AddPackingListEntry {
    fn wire2api(self) -> AddPackingListEntry {
        AddPackingListEntry {
            name: self.name.wire2api(),
            conditions: self.conditions.wire2api(),
            quantity: self.quantity.wire2api(),
        }
    }
}
impl Wire2Api<AddTripLocation> for wire_AddTripLocation {
    fn wire2api(self) -> AddTripLocation {
        AddTripLocation {
            trip_id: self.trip_id.wire2api(),
            location: self.location.wire2api(),
        }
    }
}
impl Wire2Api<AddPackingListEntry> for *mut wire_AddPackingListEntry {
    fn wire2api(self) -> AddPackingListEntry {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<AddPackingListEntry>::wire2api(*wrap).into()
    }
}
impl Wire2Api<AddTripLocation> for *mut wire_AddTripLocation {
    fn wire2api(self) -> AddTripLocation {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<AddTripLocation>::wire2api(*wrap).into()
    }
}
impl Wire2Api<CreateTrip> for *mut wire_CreateTrip {
    fn wire2api(self) -> CreateTrip {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<CreateTrip>::wire2api(*wrap).into()
    }
}
impl Wire2Api<DeletePackingListEntry> for *mut wire_DeletePackingListEntry {
    fn wire2api(self) -> DeletePackingListEntry {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<DeletePackingListEntry>::wire2api(*wrap).into()
    }
}
impl Wire2Api<usize> for *mut usize {
    fn wire2api(self) -> usize {
        unsafe { *support::box_from_leak_ptr(self) }
    }
}
impl Wire2Api<Coordinates> for wire_Coordinates {
    fn wire2api(self) -> Coordinates {
        Coordinates {
            latitude: self.latitude.wire2api(),
            longitude: self.longitude.wire2api(),
        }
    }
}
impl Wire2Api<CreateTrip> for wire_CreateTrip {
    fn wire2api(self) -> CreateTrip {
        CreateTrip {
            name: self.name.wire2api(),
            start_date: self.start_date.wire2api(),
            end_date: self.end_date.wire2api(),
            header_image: self.header_image.wire2api(),
        }
    }
}
impl Wire2Api<DeletePackingListEntry> for wire_DeletePackingListEntry {
    fn wire2api(self) -> DeletePackingListEntry {
        DeletePackingListEntry {
            id: self.id.wire2api(),
        }
    }
}

impl Wire2Api<Vec<PackingListEntryCondition>> for *mut wire_list_packing_list_entry_condition {
    fn wire2api(self) -> Vec<PackingListEntryCondition> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}
impl Wire2Api<LocationEntry> for wire_LocationEntry {
    fn wire2api(self) -> LocationEntry {
        LocationEntry {
            name: self.name.wire2api(),
            coordinates: self.coordinates.wire2api(),
            country: self.country.wire2api(),
        }
    }
}

impl Wire2Api<PackingListEntryCondition> for wire_PackingListEntryCondition {
    fn wire2api(self) -> PackingListEntryCondition {
        match self.tag {
            0 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.MinTripDuration);
                PackingListEntryCondition::MinTripDuration {
                    length: ans.length.wire2api(),
                }
            },
            1 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.MaxTripDuration);
                PackingListEntryCondition::MaxTripDuration {
                    length: ans.length.wire2api(),
                }
            },
            2 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.MinTemperature);
                PackingListEntryCondition::MinTemperature {
                    temperature: ans.temperature.wire2api(),
                }
            },
            3 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.MaxTemperature);
                PackingListEntryCondition::MaxTemperature {
                    temperature: ans.temperature.wire2api(),
                }
            },
            4 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Weather);
                PackingListEntryCondition::Weather {
                    condition: ans.condition.wire2api(),
                    min_probability: ans.min_probability.wire2api(),
                }
            },
            _ => unreachable!(),
        }
    }
}
impl Wire2Api<Quantity> for wire_Quantity {
    fn wire2api(self) -> Quantity {
        Quantity {
            per_day: self.per_day.wire2api(),
            per_night: self.per_night.wire2api(),
            fixed: self.fixed.wire2api(),
        }
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_AddPackingListEntry {
    name: *mut wire_uint_8_list,
    conditions: *mut wire_list_packing_list_entry_condition,
    quantity: wire_Quantity,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_AddTripLocation {
    trip_id: *mut wire_uint_8_list,
    location: wire_LocationEntry,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_Coordinates {
    latitude: f64,
    longitude: f64,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_CreateTrip {
    name: *mut wire_uint_8_list,
    start_date: i64,
    end_date: i64,
    header_image: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_DeletePackingListEntry {
    id: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_packing_list_entry_condition {
    ptr: *mut wire_PackingListEntryCondition,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_LocationEntry {
    name: *mut wire_uint_8_list,
    coordinates: wire_Coordinates,
    country: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_Quantity {
    per_day: *mut usize,
    per_night: *mut usize,
    fixed: *mut usize,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_PackingListEntryCondition {
    tag: i32,
    kind: *mut PackingListEntryConditionKind,
}

#[repr(C)]
pub union PackingListEntryConditionKind {
    MinTripDuration: *mut wire_PackingListEntryCondition_MinTripDuration,
    MaxTripDuration: *mut wire_PackingListEntryCondition_MaxTripDuration,
    MinTemperature: *mut wire_PackingListEntryCondition_MinTemperature,
    MaxTemperature: *mut wire_PackingListEntryCondition_MaxTemperature,
    Weather: *mut wire_PackingListEntryCondition_Weather,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_PackingListEntryCondition_MinTripDuration {
    length: usize,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_PackingListEntryCondition_MaxTripDuration {
    length: usize,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_PackingListEntryCondition_MinTemperature {
    temperature: f64,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_PackingListEntryCondition_MaxTemperature {
    temperature: f64,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_PackingListEntryCondition_Weather {
    condition: i32,
    min_probability: f64,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire_AddPackingListEntry {
    fn new_with_null_ptr() -> Self {
        Self {
            name: core::ptr::null_mut(),
            conditions: core::ptr::null_mut(),
            quantity: Default::default(),
        }
    }
}

impl Default for wire_AddPackingListEntry {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_AddTripLocation {
    fn new_with_null_ptr() -> Self {
        Self {
            trip_id: core::ptr::null_mut(),
            location: Default::default(),
        }
    }
}

impl Default for wire_AddTripLocation {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_Coordinates {
    fn new_with_null_ptr() -> Self {
        Self {
            latitude: Default::default(),
            longitude: Default::default(),
        }
    }
}

impl Default for wire_Coordinates {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_CreateTrip {
    fn new_with_null_ptr() -> Self {
        Self {
            name: core::ptr::null_mut(),
            start_date: Default::default(),
            end_date: Default::default(),
            header_image: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_CreateTrip {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_DeletePackingListEntry {
    fn new_with_null_ptr() -> Self {
        Self {
            id: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_DeletePackingListEntry {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_LocationEntry {
    fn new_with_null_ptr() -> Self {
        Self {
            name: core::ptr::null_mut(),
            coordinates: Default::default(),
            country: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_LocationEntry {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl Default for wire_PackingListEntryCondition {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_PackingListEntryCondition {
    fn new_with_null_ptr() -> Self {
        Self {
            tag: -1,
            kind: core::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn inflate_PackingListEntryCondition_MinTripDuration(
) -> *mut PackingListEntryConditionKind {
    support::new_leak_box_ptr(PackingListEntryConditionKind {
        MinTripDuration: support::new_leak_box_ptr(
            wire_PackingListEntryCondition_MinTripDuration {
                length: Default::default(),
            },
        ),
    })
}

#[no_mangle]
pub extern "C" fn inflate_PackingListEntryCondition_MaxTripDuration(
) -> *mut PackingListEntryConditionKind {
    support::new_leak_box_ptr(PackingListEntryConditionKind {
        MaxTripDuration: support::new_leak_box_ptr(
            wire_PackingListEntryCondition_MaxTripDuration {
                length: Default::default(),
            },
        ),
    })
}

#[no_mangle]
pub extern "C" fn inflate_PackingListEntryCondition_MinTemperature(
) -> *mut PackingListEntryConditionKind {
    support::new_leak_box_ptr(PackingListEntryConditionKind {
        MinTemperature: support::new_leak_box_ptr(wire_PackingListEntryCondition_MinTemperature {
            temperature: Default::default(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_PackingListEntryCondition_MaxTemperature(
) -> *mut PackingListEntryConditionKind {
    support::new_leak_box_ptr(PackingListEntryConditionKind {
        MaxTemperature: support::new_leak_box_ptr(wire_PackingListEntryCondition_MaxTemperature {
            temperature: Default::default(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_PackingListEntryCondition_Weather() -> *mut PackingListEntryConditionKind
{
    support::new_leak_box_ptr(PackingListEntryConditionKind {
        Weather: support::new_leak_box_ptr(wire_PackingListEntryCondition_Weather {
            condition: Default::default(),
            min_probability: Default::default(),
        }),
    })
}

impl NewWithNullPtr for wire_Quantity {
    fn new_with_null_ptr() -> Self {
        Self {
            per_day: core::ptr::null_mut(),
            per_night: core::ptr::null_mut(),
            fixed: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_Quantity {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
