-- =====================================================================
-- Ador Retail Analytics :: MySQL 8.0+ practice database (setup script)
-- =====================================================================
-- !!! WARNING: DESTRUCTIVE !!!
-- The next two statements DROP and recreate ONLY the dedicated practice
-- database `ador_retail`. Any data inside that database is permanently
-- deleted. No other database on your server is touched.
-- Do NOT rename `ador_retail` to the name of a database you care about.
-- =====================================================================
DROP DATABASE IF EXISTS ador_retail;
CREATE DATABASE ador_retail CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ador_retail;

-- Tables are created in foreign-key dependency order (parents first).

CREATE TABLE departments (
    department_id   INT            NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(60)    NOT NULL,
    location        VARCHAR(60)    NOT NULL,
    annual_budget   DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    PRIMARY KEY (department_id),
    UNIQUE KEY uq_departments_name (department_name),
    CONSTRAINT chk_departments_budget CHECK (annual_budget >= 0)
) ENGINE=InnoDB;

CREATE TABLE employees (
    employee_id   INT            NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(50)    NOT NULL,
    last_name     VARCHAR(50)    NOT NULL,
    email         VARCHAR(120)   NOT NULL,
    department_id INT            NOT NULL,
    manager_id    INT            NULL,
    job_title     VARCHAR(80)    NOT NULL,
    hire_date     DATE           NOT NULL,
    salary        DECIMAL(10,2)  NOT NULL,
    is_active     BOOLEAN        NOT NULL DEFAULT TRUE,
    PRIMARY KEY (employee_id),
    UNIQUE KEY uq_employees_email (email),
    KEY idx_employees_department (department_id),
    KEY idx_employees_manager (manager_id),
    CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES departments (department_id),
    CONSTRAINT fk_employees_manager FOREIGN KEY (manager_id) REFERENCES employees (employee_id),
    CONSTRAINT chk_employees_salary CHECK (salary > 0)
) ENGINE=InnoDB;

CREATE TABLE customers (
    customer_id             INT          NOT NULL AUTO_INCREMENT,
    first_name              VARCHAR(50)  NOT NULL,
    last_name               VARCHAR(50)  NOT NULL,
    email                   VARCHAR(120) NULL,
    phone                   VARCHAR(25)  NULL,
    birth_date              DATE         NULL,
    signup_date             DATE         NOT NULL,
    segment                 VARCHAR(20)  NOT NULL DEFAULT 'Consumer',
    region                  VARCHAR(30)  NOT NULL,
    is_active               BOOLEAN      NOT NULL DEFAULT TRUE,
    loyalty_points          INT          NOT NULL DEFAULT 0,
    referred_by_customer_id INT          NULL,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customers_email (email),
    KEY idx_customers_region (region),
    KEY idx_customers_signup (signup_date),
    CONSTRAINT fk_customers_referrer FOREIGN KEY (referred_by_customer_id) REFERENCES customers (customer_id),
    CONSTRAINT chk_customers_segment CHECK (segment IN ('Consumer','Small Business','Corporate')),
    CONSTRAINT chk_customers_points CHECK (loyalty_points >= 0)
) ENGINE=InnoDB;

CREATE TABLE customer_addresses (
    address_id     INT          NOT NULL AUTO_INCREMENT,
    customer_id    INT          NOT NULL,
    address_type   VARCHAR(10)  NOT NULL,
    street         VARCHAR(120) NOT NULL,
    city           VARCHAR(60)  NOT NULL,
    state_region   VARCHAR(40)  NOT NULL,
    postal_code    VARCHAR(10)  NULL,
    country        VARCHAR(40)  NOT NULL DEFAULT 'Bangladesh',
    is_default     BOOLEAN      NOT NULL DEFAULT FALSE,
    PRIMARY KEY (address_id),
    KEY idx_addresses_customer (customer_id),
    CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    CONSTRAINT chk_addresses_type CHECK (address_type IN ('Billing','Shipping'))
) ENGINE=InnoDB;

CREATE TABLE categories (
    category_id        INT         NOT NULL AUTO_INCREMENT,
    category_name      VARCHAR(60) NOT NULL,
    parent_category_id INT         NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_name (category_name),
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) REFERENCES categories (category_id)
) ENGINE=InnoDB;

CREATE TABLE suppliers (
    supplier_id    INT           NOT NULL AUTO_INCREMENT,
    supplier_name  VARCHAR(80)   NOT NULL,
    country        VARCHAR(40)   NOT NULL,
    contact_email  VARCHAR(120)  NULL,
    lead_time_days INT           NOT NULL,
    rating         DECIMAL(3,2)  NULL,
    is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
    PRIMARY KEY (supplier_id),
    UNIQUE KEY uq_suppliers_name (supplier_name),
    CONSTRAINT chk_suppliers_lead CHECK (lead_time_days > 0),
    CONSTRAINT chk_suppliers_rating CHECK (rating IS NULL OR rating BETWEEN 0 AND 5)
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id   INT           NOT NULL AUTO_INCREMENT,
    sku          VARCHAR(20)   NOT NULL,
    product_name VARCHAR(100)  NOT NULL,
    category_id  INT           NOT NULL,
    supplier_id  INT           NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL,
    unit_cost    DECIMAL(10,2) NOT NULL,
    launch_date  DATE          NOT NULL,
    discontinued BOOLEAN       NOT NULL DEFAULT FALSE,
    weight_kg    DECIMAL(6,2)  NULL,
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_products_sku (sku),
    KEY idx_products_category (category_id),
    KEY idx_products_supplier (supplier_id),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (category_id),
    CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id),
    CONSTRAINT chk_products_price CHECK (unit_price >= 0 AND unit_cost >= 0)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id                INT           NOT NULL AUTO_INCREMENT,
    customer_id             INT           NOT NULL,
    order_date              DATETIME      NOT NULL,
    order_status            VARCHAR(12)   NOT NULL DEFAULT 'Pending',
    sales_channel           VARCHAR(12)   NOT NULL DEFAULT 'Web',
    shipping_fee            DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
    handled_by_employee_id  INT           NULL,
    created_at              TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id),
    KEY idx_orders_customer (customer_id),
    KEY idx_orders_date (order_date),
    KEY idx_orders_status (order_status),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_employee FOREIGN KEY (handled_by_employee_id) REFERENCES employees (employee_id),
    CONSTRAINT chk_orders_status CHECK (order_status IN ('Pending','Completed','Cancelled','Returned')),
    CONSTRAINT chk_orders_channel CHECK (sales_channel IN ('Web','Mobile App','Store','Marketplace')),
    CONSTRAINT chk_orders_shipping CHECK (shipping_fee >= 0)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id INT           NOT NULL AUTO_INCREMENT,
    order_id      INT           NOT NULL,
    product_id    INT           NOT NULL,
    quantity      INT           NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    discount_pct  DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
    PRIMARY KEY (order_item_id),
    UNIQUE KEY uq_order_items_order_product (order_id, product_id),
    KEY idx_order_items_product (product_id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT chk_order_items_qty CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price CHECK (unit_price >= 0),
    CONSTRAINT chk_order_items_discount CHECK (discount_pct BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id     INT           NOT NULL AUTO_INCREMENT,
    order_id       INT           NOT NULL,
    payment_date   DATETIME      NOT NULL,
    payment_method VARCHAR(20)   NOT NULL,
    amount         DECIMAL(12,2) NOT NULL,
    payment_status VARCHAR(10)   NOT NULL,
    PRIMARY KEY (payment_id),
    KEY idx_payments_order (order_id),
    KEY idx_payments_status (payment_status),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT chk_payments_status CHECK (payment_status IN ('Paid','Pending','Failed','Refunded')),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE warehouses (
    warehouse_id   INT          NOT NULL AUTO_INCREMENT,
    warehouse_name VARCHAR(60)  NOT NULL,
    city           VARCHAR(60)  NOT NULL,
    region         VARCHAR(30)  NOT NULL,
    capacity_units INT          NOT NULL,
    PRIMARY KEY (warehouse_id),
    UNIQUE KEY uq_warehouses_name (warehouse_name),
    CONSTRAINT chk_warehouses_capacity CHECK (capacity_units > 0)
) ENGINE=InnoDB;

CREATE TABLE inventory (
    inventory_id      INT  NOT NULL AUTO_INCREMENT,
    warehouse_id      INT  NOT NULL,
    product_id        INT  NOT NULL,
    quantity_on_hand  INT  NOT NULL DEFAULT 0,
    reorder_level     INT  NOT NULL DEFAULT 20,
    last_restock_date DATE NULL,
    PRIMARY KEY (inventory_id),
    UNIQUE KEY uq_inventory_wh_product (warehouse_id, product_id),
    KEY idx_inventory_product (product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT chk_inventory_qty CHECK (quantity_on_hand >= 0 AND reorder_level >= 0)
) ENGINE=InnoDB;

CREATE TABLE shipments (
    shipment_id     INT         NOT NULL AUTO_INCREMENT,
    order_id        INT         NOT NULL,
    warehouse_id    INT         NOT NULL,
    shipped_date    DATE        NOT NULL,
    delivered_date  DATE        NULL,
    carrier         VARCHAR(30) NOT NULL,
    shipment_status VARCHAR(12) NOT NULL,
    PRIMARY KEY (shipment_id),
    KEY idx_shipments_order (order_id),
    KEY idx_shipments_warehouse (warehouse_id),
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_shipments_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CONSTRAINT chk_shipments_status CHECK (shipment_status IN ('Preparing','In Transit','Delivered','Returned','Lost'))
) ENGINE=InnoDB;

CREATE TABLE returns (
    return_id         INT           NOT NULL AUTO_INCREMENT,
    order_item_id     INT           NOT NULL,
    return_date       DATE          NOT NULL,
    quantity_returned INT           NOT NULL,
    reason            VARCHAR(40)   NOT NULL,
    refund_amount     DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (return_id),
    KEY idx_returns_order_item (order_item_id),
    CONSTRAINT fk_returns_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id),
    CONSTRAINT chk_returns_qty CHECK (quantity_returned > 0),
    CONSTRAINT chk_returns_refund CHECK (refund_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE marketing_campaigns (
    campaign_id   INT           NOT NULL AUTO_INCREMENT,
    campaign_name VARCHAR(80)   NOT NULL,
    channel       VARCHAR(20)   NOT NULL,
    start_date    DATE          NOT NULL,
    end_date      DATE          NOT NULL,
    budget        DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (campaign_id),
    UNIQUE KEY uq_campaigns_name (campaign_name),
    CONSTRAINT chk_campaigns_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_campaigns_budget CHECK (budget >= 0)
) ENGINE=InnoDB;

CREATE TABLE campaign_interactions (
    interaction_id       INT         NOT NULL AUTO_INCREMENT,
    campaign_id          INT         NOT NULL,
    customer_id          INT         NOT NULL,
    interaction_type     VARCHAR(12) NOT NULL,
    interaction_datetime DATETIME    NOT NULL,
    order_id             INT         NULL,
    PRIMARY KEY (interaction_id),
    KEY idx_interactions_campaign (campaign_id),
    KEY idx_interactions_customer (customer_id),
    KEY idx_interactions_order (order_id),
    CONSTRAINT fk_interactions_campaign FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns (campaign_id),
    CONSTRAINT fk_interactions_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_interactions_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT chk_interactions_type CHECK (interaction_type IN ('Impression','Click','Signup','Purchase'))
) ENGINE=InnoDB;
