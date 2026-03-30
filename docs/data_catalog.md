# Data Catalog – Gold Layer

## Overview
The **Gold Layer** represents the final, business-ready data used for reporting and analytics.

It contains:
- **Dimension tables** (descriptive data)
- **Fact tables** (measurable data)

---

## 1. gold.dim_customers

**Purpose:**  
Stores customer details enriched with demographic and geographic data.

### Columns

| Column Name     | Data Type    | Description |
|----------------|-------------|-------------|
| customer_key    | INT         | Surrogate key uniquely identifying each customer record. |
| customer_id     | INT         | Unique numerical identifier assigned to each customer. |
| customer_number | NVARCHAR(50)| Alphanumeric identifier for tracking customers. |
| first_name      | NVARCHAR(50)| Customer’s first name. |
| last_name       | NVARCHAR(50)| Customer’s last name. |
| country         | NVARCHAR(50)| Country of residence. |
| marital_status  | NVARCHAR(50)| Marital status (e.g., Married, Single). |
| gender          | NVARCHAR(50)| Gender (e.g., Male, Female, n/a). |
| birthdate       | DATE        | Date of birth (YYYY-MM-DD). |
| create_date     | DATE        | Record creation date. |

---

## 2. gold.dim_products

**Purpose:**  
Provides information about products and their attributes.

### Columns

| Column Name          | Data Type    | Description |
|----------------------|-------------|-------------|
| product_key          | INT         | Surrogate key for product. |
| product_id           | INT         | Internal product identifier. |
| product_number       | NVARCHAR(50)| Product code. |
| product_name         | NVARCHAR(50)| Product description. |
| category_id          | NVARCHAR(50)| Category identifier. |
| category             | NVARCHAR(50)| Product category (e.g., Bikes). |
| subcategory          | NVARCHAR(50)| Subcategory classification. |
| maintenance_required | NVARCHAR(50)| Maintenance flag (Yes/No). |
| cost                 | INT         | Product cost. |
| product_line         | NVARCHAR(50)| Product line. |
| start_date           | DATE        | Availability date. |

---

## 3. gold.fact_sales

**Purpose:**  
Stores transactional sales data.

### Columns

| Column Name    | Data Type    | Description |
|---------------|-------------|-------------|
| order_number   | NVARCHAR(50)| Unique order identifier. |
| product_key    | INT         | Links to dim_products. |
| customer_key   | INT         | Links to dim_customers. |
| order_date     | DATE        | Order date. |
| shipping_date  | DATE        | Shipping date. |
| due_date       | DATE        | Payment due date. |
| sales_amount   | INT         | Total sales value. |
| quantity       | INT         | Number of units sold. |
| price          | INT         | Price per unit. |
