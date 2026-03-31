# 🏗️ SQL Data Warehouse Project

A modern data warehouse built with **SQL Server**, implementing the **Medallion Architecture** (Bronze → Silver → Gold) with ETL processes, data modeling, and analytics-ready views.

---

## 📖 Project Overview

This project demonstrates how to build a fully functional data warehouse from scratch using SQL Server. It ingests raw data from two source systems (CRM and ERP), cleanses and transforms it through multiple layers, and exposes a **Star Schema** model ready for business intelligence and analytics.

### Key Features

- 🥉 **Bronze Layer** – Raw data ingestion from CSV files via `BULK INSERT`
- 🥈 **Silver Layer** – Cleaned, deduplicated, and standardized data
- 🥇 **Gold Layer** – Business-ready Star Schema (dimension & fact views)
- 🔍 **Quality Checks** – SQL scripts to validate data integrity at each layer
- 📚 **Data Catalog** – Full column-level documentation for the Gold layer

---

## 🏛️ Architecture

```
Source Systems                 Data Warehouse Layers
─────────────                  ─────────────────────────────────────────
  CRM CSVs    ──►  [Bronze]  ──►  [Silver]  ──►  [Gold]  ──►  Analytics
  ERP CSVs    ──►  (Raw)         (Cleansed)     (Star Schema)
```

| Layer  | Schema   | Description |
|--------|----------|-------------|
| Bronze | `bronze` | Exact copy of source CSV data, loaded with `BULK INSERT` |
| Silver | `silver` | Deduplicated, trimmed, type-cast, and standardized data |
| Gold   | `gold`   | Aggregated views forming a Star Schema for reporting |

---

## 📁 Repository Structure

```
sql-data-warehouse-project/
│
├── datasets/               # Placeholder for source CSV files (CRM & ERP)
│
├── docs/
│   ├── data_catalog.md     # Column-level documentation for Gold layer tables
│   └── Star_Schema_Diagram.md  # ASCII diagram of the Star Schema
│
├── scripts/
│   ├── init_db.sql         # Creates the DataWarehouse database and schemas
│   ├── bronze/
│   │   ├── ddl_bronze.sql          # DDL: Create Bronze tables
│   │   └── proc_load_bronze.sql    # Stored procedure: Load Bronze from CSVs
│   ├── silver/
│   │   ├── ddl_silver.sql          # DDL: Create Silver tables
│   │   └── proc_load_silver.sql    # Stored procedure: Load & transform Silver
│   └── gold/
│       └── ddl_gold.sql            # DDL: Create Gold views (Star Schema)
│
└── tests/
    ├── quality_checks_silver.sql   # Data quality checks for Silver layer
    └── quality_checks_gold.sql     # Data quality checks for Gold layer
```

---

## 🗄️ Data Sources

Data is sourced from two systems, provided as CSV files:

### CRM System (`source_crm/`)
| File | Bronze Table | Description |
|------|-------------|-------------|
| `cust_info.csv` | `bronze.crm_cust_info` | Customer personal details |
| `prd_info.csv` | `bronze.crm_prd_info` | Product information |
| `sales_details.csv` | `bronze.crm_sales_details` | Sales transactions |

### ERP System (`source_erp/`)
| File | Bronze Table | Description |
|------|-------------|-------------|
| `CUST_AZ12.csv` | `bronze.erp_cust_az12` | Customer birthdates and gender |
| `LOC_A101.csv` | `bronze.erp_loc_a101` | Customer country/location |
| `PX_CAT_G1V2.csv` | `bronze.erp_px_cat_g1v2` | Product categories and subcategories |

---

## 🚀 Getting Started

### Prerequisites

- **SQL Server** (2016 or later recommended)
- **SQL Server Management Studio (SSMS)** or Azure Data Studio
- Source CSV files placed in the `datasets/` directory

### Setup Steps

Run the scripts in the following order:

#### 1. Initialize the Database

Open `scripts/init_db.sql` in SSMS and execute it.

> ⚠️ **WARNING:** This will **DROP and recreate** the `DataWarehouse` database if it already exists. All existing data will be lost.

#### 2. Create Bronze Tables

Open `scripts/bronze/ddl_bronze.sql` in SSMS and execute it.

#### 3. Load Bronze Layer

> **Note:** Before running, update the file paths inside `scripts/bronze/proc_load_bronze.sql`
> to point to your local CSV file locations.

Open `scripts/bronze/proc_load_bronze.sql` in SSMS and execute it to create the stored procedure, then run:

```sql
EXEC bronze.load_bronze;
```

#### 4. Create Silver Tables

Open `scripts/silver/ddl_silver.sql` in SSMS and execute it.

#### 5. Load Silver Layer

Open `scripts/silver/proc_load_silver.sql` in SSMS and execute it to create the stored procedure, then run:

```sql
EXEC silver.load_silver;
```

#### 6. Create Gold Views

Open `scripts/gold/ddl_gold.sql` in SSMS and execute it to create all Gold layer views.

---

## ⭐ Data Model (Star Schema)

The Gold layer exposes a Star Schema consisting of two dimension tables and one fact table:

```
           +----------------------+
           |  gold.dim_customers  |
           |----------------------|
           | customer_key (PK)    |
           | customer_id          |
           | customer_number      |
           | first_name           |
           | last_name            |
           | country              |
           | marital_status       |
           | gender               |
           | birthdate            |
           | create_date          |
           +----------+-----------+
                      |
                      |
+------------------+  |  +-------------------------+
| gold.dim_products|  |  |    gold.fact_sales       |
|------------------|  |  |-------------------------|
| product_key (PK) +--+--+ product_key (FK)        |
| product_id       |     | customer_key (FK)        |
| product_number   |     | order_number             |
| product_name     |     | order_date               |
| category_id      |     | shipping_date            |
| category         |     | due_date                 |
| subcategory      |     | sales_amount             |
| maintenance      |     | quantity                 |
| cost             |     | price                    |
| product_line     |     +-------------------------+
| start_date       |
+------------------+
```

For full column descriptions, see [docs/data_catalog.md](docs/data_catalog.md).

---

## ✅ Data Quality Checks

After loading each layer, run the quality check scripts to validate data integrity.
Open each script in SSMS and execute it:

- `tests/quality_checks_silver.sql` – Validates the Silver layer
- `tests/quality_checks_gold.sql` – Validates the Gold layer

### Silver Layer Checks
- No NULL or duplicate primary keys
- No unwanted leading/trailing spaces in string fields
- No negative or NULL values in cost columns
- No invalid date orders (start date after end date)
- Sales = Quantity × Price consistency

### Gold Layer Checks
- Uniqueness of `customer_key` in `gold.dim_customers`
- Uniqueness of `product_key` in `gold.dim_products`
- No orphaned rows in `gold.fact_sales` (all FK references resolve)

---

## 🔄 ETL Transformations (Silver Layer)

The Silver stored procedure applies the following transformations:

| Table | Transformations |
|-------|----------------|
| `crm_cust_info` | Deduplication (latest record per customer), trim strings, map `M/S` → `Married/Single`, map `M/F` → `Male/Female` |
| `crm_prd_info` | Split product key into `cat_id` and `prd_key`, map product line codes, derive `prd_end_dt` using `LEAD()` |
| `crm_sales_details` | Validate and cast integer dates to `DATE`, fix negative prices, recalculate sales if inconsistent |
| `erp_cust_az12` | Strip `NAS` prefix from customer IDs, null out future birthdates, standardize gender values |
| `erp_loc_a101` | Remove dashes from IDs, standardize country codes (`DE` → `Germany`, `US/USA` → `United States`) |
| `erp_px_cat_g1v2` | Pass-through (already clean) |

---

## 🛠️ Technologies Used

- **Database:** Microsoft SQL Server
- **Language:** T-SQL (Transact-SQL)
- **Concepts:** Medallion Architecture, Star Schema, ETL, Stored Procedures, Views, Window Functions

---

## 📄 License

This project is open source and available for educational purposes.
