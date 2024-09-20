use std::ops::Deref;
use sea_orm::{ConnectionTrait, DbBackend, Statement};
use sea_orm::sqlx::Executor;
use migration::{Migrator, MigratorTrait};

pub mod entities;
pub mod enums;
pub mod repositories;

#[cfg(target_os = "android")]
mod storage {
    pub fn get_path() -> &'static str {
        "/data/data/me.maxjoehnk.holiday_planner/files/database"
    }
}

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
mod storage {
    pub fn get_path() -> &'static str {
        "db.sqlite"
    }
}

pub type DbResult<T> = Result<T, sea_orm::error::DbErr>;

#[derive(Clone)]
pub struct Database {
    pub connection: sea_orm::DatabaseConnection
}

impl Deref for Database {
    type Target = sea_orm::DatabaseConnection;

    fn deref(&self) -> &Self::Target {
        &self.connection
    }
}

impl Database {
    pub async fn new() -> anyhow::Result<Self> {
        let path = storage::get_path();
        let connection = sea_orm::Database::connect(&format!("sqlite://{path}?mode=rwc")).await?;

        // Migrator::refresh(&connection).await?;
        Migrator::up(&connection, None).await?;

        let migrations = Migrator::get_applied_migrations(&connection).await?;
        tracing::debug!("Applied migrations: {:?}", migrations.into_iter().map(|m| m.name().to_string()).collect::<Vec<_>>());

        let tables = connection.query_all(Statement::from_string(DbBackend::Sqlite, "SELECT
    name, sql
FROM
    sqlite_schema
WHERE
    type ='table' AND
    name NOT LIKE 'sqlite_%';")).await?;
        let tables = tables.into_iter()
            .map(|row| (row.try_get::<String>("", "name").unwrap(), row.try_get::<String>("", "sql").unwrap()))
            .collect::<Vec<_>>();
        for (name, sql) in tables {
            tracing::trace!("Table: {} - {}", name, sql);
        }

        Ok(Database {
            connection
        })
    }
}
