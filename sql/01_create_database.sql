/* =====================================================
   Step 1: Create database, schemas and raw tables
   Layers:  raw   -> data exactly as received (all text)
            clean -> typed, de-duplicated, validated
            mart  -> star schema consumed by Power BI
   ===================================================== */
IF DB_ID('logistics_db') IS NULL
    CREATE DATABASE logistics_db;
GO

USE logistics_db;
GO

IF SCHEMA_ID('raw')   IS NULL EXEC('CREATE SCHEMA raw');
IF SCHEMA_ID('clean') IS NULL EXEC('CREATE SCHEMA clean');
GO

-- Raw tables: every column is NVARCHAR so dirty values never fail the load.
DROP TABLE IF EXISTS raw.raw_customers;
CREATE TABLE raw.raw_customers (
    customer_id     NVARCHAR(255),
    customer_name   NVARCHAR(255),
    city            NVARCHAR(255),
    phone           NVARCHAR(255),
    signup_date     NVARCHAR(255)
);

DROP TABLE IF EXISTS raw.raw_drivers;
CREATE TABLE raw.raw_drivers (
    driver_id       NVARCHAR(255),
    driver_name     NVARCHAR(255),
    hire_date       NVARCHAR(255),
    city            NVARCHAR(255)
);

DROP TABLE IF EXISTS raw.raw_vehicles;
CREATE TABLE raw.raw_vehicles (
    vehicle_id       NVARCHAR(255),
    vehicle_type     NVARCHAR(255),
    capacity_kg      NVARCHAR(255),
    fuel_cost_per_km NVARCHAR(255)
);

DROP TABLE IF EXISTS raw.raw_shipments;
CREATE TABLE raw.raw_shipments (
    shipment_id     NVARCHAR(255),
    customer_id     NVARCHAR(255),
    driver_id       NVARCHAR(255),
    vehicle_id      NVARCHAR(255),
    ship_date       NVARCHAR(255),
    promised_date   NVARCHAR(255),
    delivered_date  NVARCHAR(255),
    distance_km     NVARCHAR(255),
    price           NVARCHAR(255),
    status          NVARCHAR(255),
    failure_reason  NVARCHAR(255)
);
GO
