use sea_orm::{DeriveActiveEnum, EnumIter};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, EnumIter, DeriveActiveEnum)]
#[sea_orm(rs_type = "i32", db_type = "Integer")]
pub enum PollenType {
    #[sea_orm(num_value = 0)]
    Grass,
    #[sea_orm(num_value = 1)]
    Tree,
    #[sea_orm(num_value = 2)]
    Weed,
}
