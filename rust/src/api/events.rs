use std::sync::OnceLock;
use flutter_rust_bridge::frb;
use tokio::sync::broadcast;
use uuid::Uuid;
use crate::frb_generated::StreamSink;

const CHANNEL_CAPACITY: usize = 64;

#[derive(Clone, Debug)]
pub enum DataChangeEvent {
    TripsChanged,
    TripChanged { trip_id: Uuid },
    LocationsChanged { trip_id: Uuid },
    WeatherUpdated { trip_id: Uuid, location_id: Uuid },
    PollenUpdated { trip_id: Uuid, location_id: Uuid },
    TidesUpdated { trip_id: Uuid, location_id: Uuid },
    PackingListChanged { trip_id: Option<Uuid> },
    AccommodationsChanged { trip_id: Option<Uuid> },
    BookingsChanged { trip_id: Option<Uuid> },
    TransitsChanged { trip_id: Option<Uuid> },
    PoisChanged { trip_id: Option<Uuid> },
    RoutesChanged { trip_id: Option<Uuid> },
    AttachmentsChanged { trip_id: Option<Uuid>, accommodation_id: Option<Uuid> },
    TagsChanged,
    TripDaysChanged { trip_id: Uuid },
}

#[frb(ignore)]
static EVENT_BUS: OnceLock<broadcast::Sender<DataChangeEvent>> = OnceLock::new();

#[frb(ignore)]
fn bus() -> &'static broadcast::Sender<DataChangeEvent> {
    EVENT_BUS.get_or_init(|| broadcast::channel(CHANNEL_CAPACITY).0)
}

#[frb(ignore)]
pub(crate) fn emit(event: DataChangeEvent) {
    let _ = bus().send(event);
}

pub async fn subscribe_data_changes(sink: StreamSink<DataChangeEvent>) -> anyhow::Result<()> {
    let mut receiver = bus().subscribe();
    tokio::spawn(async move {
        loop {
            match receiver.recv().await {
                Ok(event) => {
                    if sink.add(event).is_err() {
                        break;
                    }
                }
                Err(broadcast::error::RecvError::Lagged(skipped)) => {
                    tracing::warn!("Data change event subscriber lagged, skipped {} events", skipped);
                    continue;
                }
                Err(broadcast::error::RecvError::Closed) => break,
            }
        }
    });
    Ok(())
}
