use std::ops::Deref;
use crate::database::Database;
pub use attachment_handler::*;
pub use trip_handler::*;
pub use packing_list_handler::*;
pub use trip_packing_list_handler::*;
pub use location_handler::*;

pub mod trip_handler;
pub mod packing_list_handler;
pub mod attachment_handler;
pub mod trip_packing_list_handler;
pub mod location_handler;

pub(crate) trait HandlerCreator {
    type Guard<'a, T: Handler>: Deref<Target = T> where Self: 'a;

    fn try_get<'a, T: Handler>(&'a self) -> anyhow::Result<Self::Guard<'a, T>>;
}

pub trait Handler {
    fn create(db: Database) -> Self;
}
