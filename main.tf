provider "azurerm" {
  version = "=1.34.0"
}

variable "owner" {}
variable "location" {}
variable "admin_login" {}
variable "admin_password" {}
variable "dbserver_name" {}
variable "db_name" {}

resource "azurerm_resource_group" "demo" {
    location = "uksouth"
    name     = "pgsql-face-off"
    tags     = {}
}

resource "azurerm_postgresql_server" "demo" {
  name                = var.dbserver_name
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  sku {
    name     = "GP_Gen5_2" #  {pricing tier}_{compute generation/family}_{no of vCores}
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
    auto_grow = "Disabled"
  }

  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  version                      = "10"
  ssl_enforcement              = "Enabled"

  tags = {
    owner = var.owner
  }
}

resource "azurerm_postgresql_database" "demo" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.demo.name
  server_name         = azurerm_postgresql_server.demo.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}


output psql_admin {
  sensitive   = true
  description = "Provides a ready to use psql command line to connect to PostgreSQL Staging Db as swdbadmin."
  value       = format("PGPASSWORD='%s' psql -h %s -U %s@%s %s", var.admin_password, azurerm_postgresql_server.demo.fqdn, var.admin_login, azurerm_postgresql_server.demo.name, azurerm_postgresql_database.demo.name)
}


variable dbuser_login {}
variable dbuser_password {}

provider "postgresql" {
  version = "=1.2.0"
  alias   = "demo"

  host            = azurerm_postgresql_server.demo.fqdn
  database        = azurerm_postgresql_database.demo.name
  username        = "${azurerm_postgresql_server.demo.administrator_login}@${azurerm_postgresql_server.demo.name}"
  password        = var.admin_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

resource "postgresql_role" "demo" {
  provider = "postgresql.demo"

  name            = var.dbuser_login
  password        = var.dbuser_password
  login           = true
  superuser       = false # default
  inherit         = true  # default
  create_database = false # default
  create_role     = false # default
  replication     = false # default
}

resource "postgresql_grant" "demo-tables" {
  provider = "postgresql.demo"

  role        = postgresql_role.demo.name
  database    = azurerm_postgresql_database.demo.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "demo-sequences" {
  provider = "postgresql.demo"

  role        = postgresql_role.demo.name
  database    = azurerm_postgresql_database.demo.name
  schema      = "public"
  object_type = "sequence"
  privileges  = ["SELECT", "UPDATE"]
}

output psql_user {
  sensitive   = true
  description = "Provides a ready to use psql command line to connect to PostgreSQL Staging Db as swdbadmin."
  value       = format("PGPASSWORD='%s' psql -h %s -U %s@%s %s", var.dbuser_password, azurerm_postgresql_server.demo.fqdn, var.dbuser_login, azurerm_postgresql_server.demo.name, azurerm_postgresql_database.demo.name)
}
