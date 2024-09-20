use sea_orm::{DeriveActiveEnum, EnumIter};

#[derive(Debug, Clone, Copy, PartialEq, Eq, EnumIter, DeriveActiveEnum)]
#[sea_orm(rs_type = "i32", db_type = "Integer")]
pub enum WeatherCondition {
    #[sea_orm(num_value = 0)]
    Thunderstorm,
    #[sea_orm(num_value = 1)]
    Sunny,
    #[sea_orm(num_value = 2)]
    Rain,
    #[sea_orm(num_value = 3)]
    Clouds,
    #[sea_orm(num_value = 4)]
    Snow,
}
