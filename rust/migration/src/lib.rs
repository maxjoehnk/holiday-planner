pub use sea_orm_migration::prelude::*;

mod m20220101_000001_create_table;
mod m20240918_191313_rename_tables;
mod m20240918_221908_weather_forecast;
mod m20240920_163139_packing_list_quantity;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20220101_000001_create_table::Migration),
            Box::new(m20240918_191313_rename_tables::Migration),
            Box::new(m20240918_221908_weather_forecast::Migration),
            Box::new(m20240920_163139_packing_list_quantity::Migration),
        ]
    }
}
