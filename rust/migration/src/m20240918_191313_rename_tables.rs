use sea_orm_migration::{prelude::*, schema::*};

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();
        
        db.execute_unprepared(r#"
            ALTER TABLE location RENAME TO locations;
            ALTER TABLE trip_packing_list_entry RENAME TO trip_packing_list_entries;
        "#).await?;
        
        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared(r#"
            ALTER TABLE locations RENAME TO location;
            ALTER TABLE trip_packing_list_entries RENAME TO trip_packing_list_entry;
        "#).await?;

        Ok(())
    }
}
