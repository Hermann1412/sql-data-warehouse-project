# SQL Data Warehouse Project

A modern data warehouse solution built with **SQL Server**, implementing the **Medallion Architecture** (Bronze → Silver → Gold layers). It integrates data from CRM and ERP source systems into a unified, analytics-ready star schema optimised for BI reporting and analytics.

---

## 📑 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Data Sources](#data-sources)
- [Layer Details](#layer-details)
  - [Bronze Layer – Raw Ingestion](#bronze-layer--raw-ingestion)
  - [Silver Layer – Cleansing & Standardisation](#silver-layer--cleansing--standardisation)
  - [Gold Layer – Star Schema (Analytics)](#gold-layer--star-schema-analytics)
- [Star Schema](#star-schema)
- [Data Catalog](#data-catalog)
- [Data Flow](#data-flow)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Execution Order](#execution-order)
- [Data Quality & Testing](#data-quality--testing)
- [Key Features](#key-features)

---

## Project Overview

This project builds a fully layered SQL data warehouse that demonstrates enterprise data engineering practices:

- **ELT pipelines** using SQL Server stored procedures and `BULK INSERT` (raw data is loaded first, then transformed in-place)
- **Three-tier Medallion Architecture**: raw → cleaned → analytics
- **Star schema** dimensional model optimised for OLAP queries
- **Data quality checks** to validate each transformation layer
- **Multi-source integration** combining CRM and ERP datasets

---

## Architecture

The warehouse is structured around the Medallion Architecture pattern:

```
┌─────────────────────────────────────┐
│        SOURCE SYSTEMS               │
│  CRM System        ERP System       │
│  (CSV files)       (CSV files)      │
└────────────┬───────────┬────────────┘
             │ BULK INSERT│
             ▼            ▼
┌─────────────────────────────────────┐
│         BRONZE LAYER                │
│  Raw data – loaded as-is from CSV   │
│  No transformations applied         │
└─────────────────┬───────────────────┘
                  │ Stored Procedure
                  ▼
┌─────────────────────────────────────┐
│         SILVER LAYER                │
│  Cleaned, deduplicated, standardised│
│  Type conversions & NULL handling   │
└─────────────────┬───────────────────┘
                  │ Views (JOINs)
                  ▼
┌─────────────────────────────────────┐
│          GOLD LAYER                 │
│  Star schema – analytics-ready      │
│  Dimension & Fact views             │
└─────────────────┬───────────────────┘
                  │
                  ▼
         BI Tools / Reporting
```

---

## Repository Structure

```
sql-data-warehouse-project/
├── datasets/                       # Source CSV data files
│   ├── source_crm/
│   │   ├── cust_info.csv          # Customer information
│   │   ├── prd_info.csv           # Product information
│   │   └── sales_details.csv      # Sales transactions
│   └── source_erp/
│       ├── CUST_AZ12.csv          # Customer demographics (birthdate, gender)
│       ├── LOC_A101.csv           # Location / country data
│       └── PX_CAT_G1V2.csv        # Product categories
├── scripts/                        # SQL scripts by layer
│   ├── init_db.sql                # Create database and schemas
│   ├── bronze/
│   │   ├── ddl_bronze.sql         # Bronze table definitions
│   │   └── proc_load_bronze.sql   # Stored procedure – BULK INSERT from CSV
│   ├── silver/
│   │   ├── ddl_silver.sql         # Silver table definitions
│   │   └── proc_load_silver.sql   # Stored procedure – cleanse & transform
│   └── gold/
│       └── ddl_gold.sql           # Gold analytical views (star schema)
├── tests/
│   ├── quality_checks_silver.sql  # Data quality validation – silver layer
│   └── quality_checks_gold.sql    # Data quality validation – gold layer
└── docs/
    ├── data_catalog.md            # Full data dictionary
    ├── Star_Schema_Diagram.md     # Star schema diagram
    ├── Data_Warehouse_Architecture.drawio
    ├── 'Data Mart(Start Schema).drawio'
    ├── IntegrationModel.drawio
    ├── data_flow_diagram.drawio
    └── Datawarehouse_report.pdf
```

---

## Data Sources

Two source systems supply data via CSV exports:

| System | File | Description |
|--------|------|-------------|
| CRM | `cust_info.csv` | Customer master data |
| CRM | `prd_info.csv` | Product catalogue |
| CRM | `sales_details.csv` | Sales order transactions |
| ERP | `CUST_AZ12.csv` | Customer demographics (birthdate, gender) |
| ERP | `LOC_A101.csv` | Customer location / country codes |
| ERP | `PX_CAT_G1V2.csv` | Product category hierarchy |

---

## Layer Details

### Bronze Layer – Raw Ingestion

**Tables:** `bronze.crm_cust_info`, `bronze.crm_prd_info`, `bronze.crm_sales_details`, `bronze.erp_cust_az12`, `bronze.erp_loc_a101`, `bronze.erp_px_cat_g1v2`

- Data is loaded verbatim from the CSV files using `BULK INSERT`.
- Tables are truncated before each load (full refresh).
- Load duration is logged for each table.
- Error handling via `TRY…CATCH` blocks in the stored procedure.

> **Note:** The file paths in `proc_load_bronze.sql` are Windows-style absolute paths. Update them to match the location of the CSV files on your server before running.

---

### Silver Layer – Cleansing & Standardisation

**Tables:** `silver.crm_cust_info`, `silver.crm_prd_info`, `silver.crm_sales_details`, `silver.erp_cust_az12`, `silver.erp_loc_a101`, `silver.erp_px_cat_g1v2`

Key transformations applied by `proc_load_silver`:

| Table | Transformations |
|-------|----------------|
| `crm_cust_info` | Deduplication (keep latest record per customer), trim whitespace, standardise marital status (`S`→`Single`, `M`→`Married`) and gender (`F`→`Female`, `M`→`Male`) |
| `crm_prd_info` | Extract `cat_id` from product key, map `prd_line` codes to full names (`M`→`Mountain`, `R`→`Road`, `S`→`Other Sale`, `T`→`Touring`), derive `prd_end_dt` from next row's `prd_start_dt` |
| `crm_sales_details` | Convert integer dates (`YYYYMMDD`) to `DATE`, calculate `sls_sales` where NULL or invalid (`sls_quantity × sls_price`) |
| `erp_cust_az12` | Strip `NAS` prefix from customer ID, set future birthdates to NULL, standardise gender strings |
| `erp_loc_a101` | Remove dashes from IDs, map country codes (`DE`→`Germany`, `US`→`United States`) |
| `erp_px_cat_g1v2` | Direct copy with `dwh_create_date` timestamp added |

All silver tables include a `dwh_create_date` column populated with `GETDATE()` at load time.

---

### Gold Layer – Star Schema (Analytics)

**Views:** `gold.dim_customers`, `gold.dim_products`, `gold.fact_sales`

The gold layer creates analytical views that join across silver tables and add surrogate keys via `ROW_NUMBER()`. No data is physically stored – everything is computed on-the-fly from silver.

---

## Star Schema

```
                   ┌────────────────────────┐
                   │   gold.dim_customers   │
                   │────────────────────────│
                   │ customer_key  (PK)     │
                   │ customer_id            │
                   │ customer_number        │
                   │ first_name             │
                   │ last_name              │
                   │ country                │
                   │ marital_status         │
                   │ gender                 │
                   │ birthdate              │
                   │ create_date            │
                   └───────────┬────────────┘
                               │ FK
┌──────────────────────┐       │       ┌──────────────────────┐
│  gold.dim_products   │       │       │   gold.fact_sales    │
│──────────────────────│       │       │──────────────────────│
│ product_key   (PK)   │◄──────┼───────│ product_key   (FK)   │
│ product_id           │       └───────►customer_key  (FK)   │
│ product_number       │               │ order_number         │
│ product_name         │               │ order_date           │
│ category_id          │               │ shipping_date        │
│ category             │               │ due_date             │
│ subcategory          │               │ sales_amount         │
│ maintenance          │               │ quantity             │
│ cost                 │               │ price                │
│ product_line         │               └──────────────────────┘
│ start_date           │
└──────────────────────┘
```

---

## Data Catalog

### `gold.dim_customers`

| Column | Type | Description |
|--------|------|-------------|
| `customer_key` | INT | Surrogate key (auto-generated) |
| `customer_id` | INT | Source CRM customer ID |
| `customer_number` | NVARCHAR | Business key (e.g. `AW00011000`) |
| `first_name` | NVARCHAR | Customer first name |
| `last_name` | NVARCHAR | Customer last name |
| `country` | NVARCHAR | Country of residence |
| `marital_status` | NVARCHAR | `Single` or `Married` |
| `gender` | NVARCHAR | `Male`, `Female`, or `n/a` |
| `birthdate` | DATE | Date of birth |
| `create_date` | DATE | Date added to CRM |

### `gold.dim_products`

| Column | Type | Description |
|--------|------|-------------|
| `product_key` | INT | Surrogate key (auto-generated) |
| `product_id` | INT | Source CRM product ID |
| `product_number` | NVARCHAR | Business key (e.g. `BK-R93R-62`) |
| `product_name` | NVARCHAR | Full product name |
| `category_id` | NVARCHAR | Category code (e.g. `AC_BR`) |
| `category` | NVARCHAR | Category name (e.g. `Accessories`) |
| `subcategory` | NVARCHAR | Subcategory name |
| `maintenance` | NVARCHAR | `Yes` / `No` – requires maintenance |
| `cost` | INT | Standard cost |
| `product_line` | NVARCHAR | `Mountain`, `Road`, `Touring`, `Other Sale` |
| `start_date` | DATE | Product availability start date |

### `gold.fact_sales`

| Column | Type | Description |
|--------|------|-------------|
| `order_number` | NVARCHAR | Sales order number (e.g. `SO43697`) |
| `product_key` | INT | FK → `dim_products.product_key` |
| `customer_key` | INT | FK → `dim_customers.customer_key` |
| `order_date` | DATE | Date the order was placed |
| `shipping_date` | DATE | Date the order was shipped |
| `due_date` | DATE | Due date for the order |
| `sales_amount` | INT | Total sales amount |
| `quantity` | INT | Number of units sold |
| `price` | INT | Unit price |

---

## Data Flow

```
CRM CSVs          ERP CSVs
    │                 │
    └────────┬────────┘
             │  BULK INSERT
             ▼
       Bronze Layer         ← Raw data, no transformations
             │
             │  proc_load_silver (Stored Procedure)
             ▼
       Silver Layer         ← Deduplicated, cleaned, standardised
             │
             │  SQL Views (JOINs + ROW_NUMBER)
             ▼
        Gold Layer          ← Star schema (dim + fact views)
             │
             ▼
     BI Tools / Reports
```

---

## Getting Started

### Prerequisites

- **SQL Server** 2016 or later (or Azure SQL with bulk insert support)
- Access to the `datasets/` CSV files from the SQL Server host
- A SQL client such as SQL Server Management Studio (SSMS) or Azure Data Studio

### Execution Order

Run the scripts in the following order:

```
1. scripts/init_db.sql                  -- Create DataWarehouse DB and schemas
2. scripts/bronze/ddl_bronze.sql        -- Create bronze tables
3. scripts/bronze/proc_load_bronze.sql  -- Create bronze load procedure
   EXEC bronze.load_bronze;             -- ← Run to load CSV data into bronze
4. scripts/silver/ddl_silver.sql        -- Create silver tables
5. scripts/silver/proc_load_silver.sql  -- Create silver load procedure
   EXEC silver.load_silver;             -- ← Run to cleanse & load silver
6. scripts/gold/ddl_gold.sql            -- Create gold views (star schema)
```

> **Important:** Before running step 3, open `scripts/bronze/proc_load_bronze.sql` and update the file paths in the `BULK INSERT` statements to point to the actual location of the CSV files on your SQL Server host.

### Example – Load and Query

```sql
-- Load bronze layer
EXEC bronze.load_bronze;

-- Load silver layer
EXEC silver.load_silver;

-- Query analytics
SELECT
    dc.first_name,
    dc.last_name,
    dc.country,
    dp.product_name,
    dp.category,
    fs.order_date,
    fs.sales_amount
FROM gold.fact_sales fs
JOIN gold.dim_customers dc ON fs.customer_key = dc.customer_key
JOIN gold.dim_products  dp ON fs.product_key  = dp.product_key
ORDER BY fs.order_date DESC;
```

---

## Data Quality & Testing

Data quality scripts are provided for the silver and gold layers:

| Script | Validates |
|--------|-----------|
| `tests/quality_checks_silver.sql` | No NULL or duplicate primary keys; no leading/trailing spaces; standardised gender and marital status values; valid date ranges; `sales = quantity × price` consistency |
| `tests/quality_checks_gold.sql` | Unique surrogate keys; referential integrity between fact and dimension tables; no orphaned fact records |

Run these scripts after each load to confirm data integrity before exposing the gold layer to consumers.

---

## Key Features

| Feature | Detail |
|---------|--------|
| **Medallion Architecture** | Three-tier Bronze → Silver → Gold design |
| **Full Refresh ETL** | Tables are truncated and reloaded on each run |
| **Data Deduplication** | `ROW_NUMBER()` window functions to keep the latest record |
| **Value Standardisation** | Consistent mapping for gender, marital status, country codes, and product lines |
| **Error Handling** | `TRY…CATCH` blocks in all stored procedures |
| **Performance Logging** | Load durations printed for each table |
| **Star Schema** | Surrogate keys, conformed dimensions, one fact table |
| **Quality Assurance** | Dedicated test scripts for silver and gold layers |
| **Multi-source Integration** | CRM and ERP data unified in one model |
