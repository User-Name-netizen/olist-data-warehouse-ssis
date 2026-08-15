USE OlistDW;
GO

-- =========================================================
-- 0. CREATE SCHEMA STAGE
-- =========================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Stage')
BEGIN
    EXEC('CREATE SCHEMA Stage');
END
GO

-- =========================================================
-- 1. STG_Customers
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Customers', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Customers;
GO

CREATE TABLE Stage.STG_Customers (
    customer_id              VARCHAR(32),
    customer_unique_id       VARCHAR(32),
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           CHAR(2)
);
GO

-- =========================================================
-- 2. STG_Orders
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Orders', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Orders;
GO

CREATE TABLE Stage.STG_Orders (
    order_id VARCHAR(32),
    customer_id VARCHAR(32),
    order_status VARCHAR(20),

    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);
GO

-- =========================================================
-- 3. STG_Order_Items
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Order_Items', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Order_Items;
GO

CREATE TABLE Stage.STG_Order_Items (
    order_id VARCHAR(32),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),

    shipping_limit_date DATETIME,

    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);
GO

-- =========================================================
-- 4. STG_Payments
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Payments', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Payments;
GO

CREATE TABLE Stage.STG_Payments (
    order_id VARCHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(20),

    payment_installments INT,
    payment_value DECIMAL(10,2)
);
GO

-- =========================================================
-- 5. STG_Reviews
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Reviews', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Reviews;
GO

CREATE TABLE Stage.STG_Reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32),

    review_score INT,

    review_comment_title VARCHAR(255),
    review_comment_message VARCHAR(2000),

    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);
GO

-- =========================================================
-- 6. STG_Products
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Products', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Products;
GO

CREATE TABLE Stage.STG_Products (
    product_id VARCHAR(32),
    product_category_name VARCHAR(100),

    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,

    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
GO

-- =========================================================
-- 7. STG_Sellers
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Sellers', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Sellers;
GO

CREATE TABLE Stage.STG_Sellers (
    seller_id VARCHAR(32),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
GO

-- =========================================================
-- 8. STG_Category_Translation
-- =========================================================
IF OBJECT_ID(N'Stage.STG_Category_Translation', N'U') IS NOT NULL 
    DROP TABLE Stage.STG_Category_Translation;
GO

CREATE TABLE Stage.STG_Category_Translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
GO
