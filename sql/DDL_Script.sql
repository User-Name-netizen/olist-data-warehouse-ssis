-- OLIST E-COMMERCE DATA WAREHOUSE
-- Phase 3.1 + 3.2: Dimension and Fact Tables DDL
IF DB_ID(N'OlistDW') IS NULL
BEGIN
    CREATE DATABASE OlistDW;
END
GO
USE OlistDW;
GO
-- =========================================================
-- 3.1.1 Dim_Date
-- =========================================================
IF OBJECT_ID(N'dbo.Dim_Date', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Date (
        date_key        INT         NOT NULL PRIMARY KEY,   -- YYYYMMDD
        full_date       DATE        NOT NULL,
        day_of_month    TINYINT     NOT NULL,
        day_of_week     TINYINT     NOT NULL,              -- 1=Sunday, 7=Saturday
        day_name        VARCHAR(10) NOT NULL,
        week_of_year    TINYINT     NOT NULL,
        month           TINYINT     NOT NULL,
        month_name      VARCHAR(10) NOT NULL,
        quarter         TINYINT     NOT NULL,
        year            SMALLINT    NOT NULL,
        is_weekend      BIT         NOT NULL,
        year_month      CHAR(7)     NOT NULL,              -- YYYY-MM
        year_quarter    CHAR(7)     NOT NULL               -- YYYY-Q#
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_DimDate_FullDate'
      AND object_id = OBJECT_ID(N'dbo.Dim_Date')
)
BEGIN
    CREATE UNIQUE INDEX UX_DimDate_FullDate ON dbo.Dim_Date(full_date);
END;

-- =========================================================
-- 3.1.2 Dim_Customer
-- =========================================================
IF OBJECT_ID(N'dbo.Dim_Customer', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Customer (
        customer_key        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        customer_id         VARCHAR(32) NOT NULL,
        customer_unique_id   VARCHAR(32) NULL,
        customer_zip_code    VARCHAR(10) NULL,
        customer_city       VARCHAR(100) NULL,
        customer_state      CHAR(2) NULL,
        effective_date      DATE NULL,
        expiration_date     DATE NULL,
        is_current          BIT NOT NULL DEFAULT 1,
        CONSTRAINT CK_DimCustomer_IsCurrent CHECK (is_current IN (0, 1)),
        CONSTRAINT CK_DimCustomer_SCDDateRange CHECK (
            expiration_date IS NULL OR effective_date IS NULL OR expiration_date >= effective_date
        )
    );
END;

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_DimCustomer_CustomerId'
      AND object_id = OBJECT_ID(N'dbo.Dim_Customer')
)
BEGIN
    DROP INDEX IX_DimCustomer_CustomerId ON dbo.Dim_Customer;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_DimCustomer_UniqueId'
      AND object_id = OBJECT_ID(N'dbo.Dim_Customer')
)
BEGIN
    CREATE INDEX IX_DimCustomer_UniqueId ON dbo.Dim_Customer(customer_unique_id);
END;

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_DimCustomer_CurrentRow'
      AND object_id = OBJECT_ID(N'dbo.Dim_Customer')
)
BEGIN
    DROP INDEX UX_DimCustomer_CurrentRow ON dbo.Dim_Customer;
END;

CREATE UNIQUE INDEX UX_DimCustomer_CurrentRow
ON dbo.Dim_Customer(customer_unique_id)
WHERE is_current = 1 AND customer_unique_id IS NOT NULL;

-- =========================================================
-- 3.1.3 Dim_Product
-- =========================================================
IF OBJECT_ID(N'dbo.Dim_Product', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Product (
        product_key                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        product_id                  VARCHAR(32) NOT NULL,
        product_category_pt         VARCHAR(100) NULL,
        product_category_en         VARCHAR(100) NULL,
        product_photos_qty          INT NULL,
        product_weight_g            INT NULL,
        product_length_cm           INT NULL,
        product_height_cm           INT NULL,
        product_width_cm            INT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_DimProduct_ProductId'
      AND object_id = OBJECT_ID(N'dbo.Dim_Product')
)
BEGIN
    CREATE UNIQUE INDEX UX_DimProduct_ProductId ON dbo.Dim_Product(product_id);
END;

-- =========================================================
-- 3.1.4 Dim_Seller
-- =========================================================
IF OBJECT_ID(N'dbo.Dim_Seller', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Seller (
        seller_key          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        seller_id           VARCHAR(32) NOT NULL,
        seller_zip_code     VARCHAR(10) NULL,
        seller_city         VARCHAR(100) NULL,
        seller_state        CHAR(2) NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_DimSeller_SellerId'
      AND object_id = OBJECT_ID(N'dbo.Dim_Seller')
)
BEGIN
    CREATE UNIQUE INDEX UX_DimSeller_SellerId ON dbo.Dim_Seller(seller_id);
END;

-- =========================================================
-- 3.1.5 Dim_Payment_Type
-- =========================================================
IF OBJECT_ID(N'dbo.Dim_Payment_Type', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Payment_Type (
        payment_type_key    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        payment_type        VARCHAR(20) NOT NULL,
        payment_type_desc   VARCHAR(100) NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_DimPaymentType_PaymentType'
      AND object_id = OBJECT_ID(N'dbo.Dim_Payment_Type')
)
BEGIN
    CREATE UNIQUE INDEX UX_DimPaymentType_PaymentType ON dbo.Dim_Payment_Type(payment_type);
END;

-- =========================================================
-- 3.1.6 Dim_Order_Status
-- =========================================================
IF OBJECT_ID(N'dbo.Dim_Order_Status', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Order_Status (
        status_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        status_code     VARCHAR(20) NOT NULL,
        status_name     VARCHAR(50) NULL,
        status_desc     VARCHAR(200) NULL,
        is_completed    BIT NOT NULL DEFAULT 0,
        display_order   INT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_DimOrderStatus_StatusCode'
      AND object_id = OBJECT_ID(N'dbo.Dim_Order_Status')
)
BEGIN
    CREATE UNIQUE INDEX UX_DimOrderStatus_StatusCode ON dbo.Dim_Order_Status(status_code);
END;

-- =========================================================
-- 3.2.1 Fact_Sales
-- =========================================================
IF OBJECT_ID(N'dbo.Fact_Sales', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Sales (
        sales_key        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        order_id         VARCHAR(32) NOT NULL,
        order_item_id    INT NOT NULL,
        purchase_date_key INT NOT NULL,
        customer_key     INT NOT NULL,
        product_key      INT NOT NULL,
        seller_key       INT NOT NULL,
        price            DECIMAL(10,2) NULL,
        freight_value    DECIMAL(10,2) NULL,
        total_value      DECIMAL(10,2) NULL,
        item_count       INT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_FactSales_OrderItem UNIQUE (order_id, order_item_id),
        CONSTRAINT CK_FactSales_Price CHECK (price IS NULL OR price >= 0),
        CONSTRAINT CK_FactSales_Freight CHECK (freight_value IS NULL OR freight_value >= 0),
        CONSTRAINT CK_FactSales_Total CHECK (total_value IS NULL OR total_value >= 0),
        CONSTRAINT CK_FactSales_ItemCount CHECK (item_count >= 1),
        FOREIGN KEY (purchase_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (customer_key) REFERENCES dbo.Dim_Customer(customer_key),
        FOREIGN KEY (product_key) REFERENCES dbo.Dim_Product(product_key),
        FOREIGN KEY (seller_key) REFERENCES dbo.Dim_Seller(seller_key)
    );
END;

-- =========================================================
-- 3.2.2 Fact_Payment
-- =========================================================
IF OBJECT_ID(N'dbo.Fact_Payment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Payment (
        payment_key            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        order_id               VARCHAR(32) NOT NULL,
        payment_sequential     INT NOT NULL,
        payment_date_key       INT NOT NULL,
        customer_key           INT NOT NULL,
        payment_type_key       INT NOT NULL,
        payment_value          DECIMAL(10,2) NULL,
        payment_installments   INT NULL,
        payment_count          INT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_FactPayment_OrderSeq UNIQUE (order_id, payment_sequential),
        CONSTRAINT CK_FactPayment_Value CHECK (payment_value IS NULL OR payment_value >= 0),
        CONSTRAINT CK_FactPayment_Installments CHECK (payment_installments IS NULL OR payment_installments >= 1),
        CONSTRAINT CK_FactPayment_Count CHECK (payment_count >= 1),
        FOREIGN KEY (payment_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (customer_key) REFERENCES dbo.Dim_Customer(customer_key),
        FOREIGN KEY (payment_type_key) REFERENCES dbo.Dim_Payment_Type(payment_type_key)
    );
END;

-- =========================================================
-- 3.2.3 Fact_Review
-- =========================================================
IF OBJECT_ID(N'dbo.Fact_Review', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Review (
        review_key       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        order_id         VARCHAR(32) NOT NULL,
        date_key         INT NOT NULL,
        customer_key     INT NOT NULL,
        review_score     DECIMAL(3,2) NULL,
        has_title        BIT NOT NULL DEFAULT 0,
        has_message      BIT NOT NULL DEFAULT 0,
        review_count     INT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_FactReview_ReviewOrder UNIQUE (order_id),
        CONSTRAINT CK_FactReview_Score CHECK (review_score IS NULL OR review_score BETWEEN 1 AND 5),
        CONSTRAINT CK_FactReview_Count CHECK (review_count >= 1),
        FOREIGN KEY (date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (customer_key) REFERENCES dbo.Dim_Customer(customer_key)
    );
END;

-- =========================================================
-- 3.2.4 Fact_Delivery
-- =========================================================
IF OBJECT_ID(N'dbo.Fact_Delivery', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Delivery (
        delivery_key           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        order_id               VARCHAR(32) NOT NULL,
        purchase_date_key      INT NOT NULL,
        approved_date_key      INT NULL,
        carrier_date_key       INT NULL,
        delivery_date_key      INT NULL,
        estimated_date_key     INT NOT NULL,
        customer_key           INT NOT NULL,
        status_key             INT NOT NULL,
        approval_hours         DECIMAL(10,2) NULL,
        carrier_days           DECIMAL(10,2) NULL,
        delivery_days          DECIMAL(10,2) NULL,
        estimated_days         INT NULL,
        days_early_late        INT NULL, -- estimated_date - actual_delivery_date (+ = early, - = late)
        is_on_time             BIT NOT NULL DEFAULT 0,
        is_delivered           BIT NOT NULL DEFAULT 0,
        order_count            INT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_FactDelivery_Order UNIQUE (order_id),
        CONSTRAINT CK_FactDelivery_OrderCount CHECK (order_count >= 1),
        FOREIGN KEY (purchase_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (approved_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (carrier_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (delivery_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (estimated_date_key) REFERENCES dbo.Dim_Date(date_key),
        FOREIGN KEY (customer_key) REFERENCES dbo.Dim_Customer(customer_key),
        FOREIGN KEY (status_key) REFERENCES dbo.Dim_Order_Status(status_key)
    );
END;

-- =========================================================
-- Indexes for fact tables
-- =========================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactSales_PurchaseDate'
      AND object_id = OBJECT_ID(N'dbo.Fact_Sales')
)
BEGIN
    CREATE INDEX IX_FactSales_PurchaseDate ON dbo.Fact_Sales(purchase_date_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactSales_Customer'
      AND object_id = OBJECT_ID(N'dbo.Fact_Sales')
)
BEGIN
    CREATE INDEX IX_FactSales_Customer ON dbo.Fact_Sales(customer_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactSales_Product'
      AND object_id = OBJECT_ID(N'dbo.Fact_Sales')
)
BEGIN
    CREATE INDEX IX_FactSales_Product ON dbo.Fact_Sales(product_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactSales_Seller'
      AND object_id = OBJECT_ID(N'dbo.Fact_Sales')
)
BEGIN
    CREATE INDEX IX_FactSales_Seller ON dbo.Fact_Sales(seller_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactPayment_PaymentDate'
      AND object_id = OBJECT_ID(N'dbo.Fact_Payment')
)
BEGIN
    CREATE INDEX IX_FactPayment_PaymentDate ON dbo.Fact_Payment(payment_date_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactPayment_PaymentType'
      AND object_id = OBJECT_ID(N'dbo.Fact_Payment')
)
BEGIN
    CREATE INDEX IX_FactPayment_PaymentType ON dbo.Fact_Payment(payment_type_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactPayment_Customer'
      AND object_id = OBJECT_ID(N'dbo.Fact_Payment')
)
BEGIN
    CREATE INDEX IX_FactPayment_Customer ON dbo.Fact_Payment(customer_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactReview_Date'
      AND object_id = OBJECT_ID(N'dbo.Fact_Review')
)
BEGIN
    CREATE INDEX IX_FactReview_Date ON dbo.Fact_Review(date_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactReview_Customer'
      AND object_id = OBJECT_ID(N'dbo.Fact_Review')
)
BEGIN
    CREATE INDEX IX_FactReview_Customer ON dbo.Fact_Review(customer_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactDelivery_PurchaseDate'
      AND object_id = OBJECT_ID(N'dbo.Fact_Delivery')
)
BEGIN
    CREATE INDEX IX_FactDelivery_PurchaseDate ON dbo.Fact_Delivery(purchase_date_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactDelivery_DeliveryDate'
      AND object_id = OBJECT_ID(N'dbo.Fact_Delivery')
)
BEGIN
    CREATE INDEX IX_FactDelivery_DeliveryDate ON dbo.Fact_Delivery(delivery_date_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactDelivery_Customer'
      AND object_id = OBJECT_ID(N'dbo.Fact_Delivery')
)
BEGIN
    CREATE INDEX IX_FactDelivery_Customer ON dbo.Fact_Delivery(customer_key);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_FactDelivery_Status'
      AND object_id = OBJECT_ID(N'dbo.Fact_Delivery')
)
BEGIN
    CREATE INDEX IX_FactDelivery_Status ON dbo.Fact_Delivery(status_key);
END;

