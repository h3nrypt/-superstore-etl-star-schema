-- =========================================================================
-- FILE 02: BUILD DIMENSIONS
-- Purpose: Extract unique descriptive entities and enforce primary keys.
-- =========================================================================

USE superstore_db;

-- 1. Customer Dimension
DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    segment VARCHAR(50) NOT NULL,
    PRIMARY KEY (customer_id)
);

INSERT INTO dim_customer (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment 
FROM raw_staging;

-- 2. Product Dimension
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50) NOT NULL,
    PRIMARY KEY (product_id)
);

INSERT INTO dim_product (product_id, product_name, category, sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category 
FROM raw_staging;

CREATE TABLE IF NOT EXISTS dim_geography (
    geography_id INT AUTO_INCREMENT PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    state VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) DEFAULT 'N/A',
    CONSTRAINT unq_geo_combination UNIQUE (country, region, state, city, postal_code)
);

INSERT IGNORE INTO dim_geography (country, region, state, city, postal_code)
SELECT DISTINCT 
    Country, 
    Region, 
    State, 
    City, 
    COALESCE(CAST(Postal_Code AS CHAR), 'N/A')
FROM raw_staging;
ALTER TABLE fact_sales 
ADD COLUMN geography_id INT NULL;

UPDATE fact_sales f
JOIN raw_staging s ON f.Row_ID = s.Row_ID
JOIN dim_geography g 
    ON  s.Country = g.country
    AND s.Region = g.region
    AND s.State = g.state
    AND s.City = g.city
    AND COALESCE(CAST(s.Postal_Code AS CHAR), 'N/A') = g.postal_code
SET f.geography_id = g.geography_id;

Delete corrupt rows from raw_staging
DELETE FROM raw_staging
WHERE Row_ID IS NULL OR Order_ID IS NULL;

SELECT 
    COUNT(*) AS total_fact_rows,
    COUNT(geography_id) AS mapped_geo_rows,
    SUM(CASE WHEN geography_id IS NULL THEN 1 ELSE 0 END) AS unmapped_null_rows
FROM fact_sales;