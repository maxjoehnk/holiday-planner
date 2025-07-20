use std::ops::Deref;
use crate::database::Database;
pub use accommodation_handler::*;
pub use attachment_handler::*;
pub use trip_handler::*;
pub use packing_list_handler::*;
pub use trip_packing_list_handler::*;
pub use location_handler::*;
pub use point_of_interest_handler::*;

pub mod accommodation_handler;
pub mod attachment_handler;
pub mod trip_handler;
pub mod packing_list_handler;
pub mod trip_packing_list_handler;
pub mod location_handler;
pub mod point_of_interest_handler;

pub(crate) trait HandlerCreator: Send {
    type Guard<'a, T: Handler>: Deref<Target = T> + Send where Self: 'a;

    async fn try_get<'a, T: Handler>(&'a self) -> anyhow::Result<Self::Guard<'a, T>>;
}

pub trait Handler: Send {
    fn create(db: Database) -> Self;
}
