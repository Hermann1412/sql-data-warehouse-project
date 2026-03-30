                +----------------------+
                |   gold.dim_customers|
                |----------------------|
                | customer_key (PK)   |
                | customer_id         |
                | first_name          |
                | last_name           |
                | ...                 |
                +----------+----------+
                           |
                           |
                           |
+------------------+       |       +----------------------+
| gold.dim_products|       |       |   gold.fact_sales    |
|------------------|       |       |----------------------|
| product_key (PK) |-------+------>| product_key (FK)     |
| product_id       |               | customer_key (FK)    |
| product_name     |               | order_number         |
| category         |               | order_date           |
| ...              |               | sales_amount         |
+------------------+               | quantity             |
                                   | price                |
                                   +----------------------+
