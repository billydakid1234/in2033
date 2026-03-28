CREATE DATABASE IF NOT EXISTS CA_db;
USE CA_db;

-- ==========================================
-- DROP TABLES (safe re-run)
-- ==========================================
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS ca_payment_reminders;
DROP TABLE IF EXISTS ca_statements;
DROP TABLE IF EXISTS ca_online_order_items;
DROP TABLE IF EXISTS ca_online_orders;
DROP TABLE IF EXISTS delivery_items;
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS supplier_invoices;
DROP TABLE IF EXISTS supplier_order_items;
DROP TABLE IF EXISTS supplier_orders;
DROP TABLE IF EXISTS discounts;
DROP TABLE IF EXISTS ca_sale_items;
DROP TABLE IF EXISTS ca_payments;
DROP TABLE IF EXISTS ca_sales;
DROP TABLE IF EXISTS ca_checkout_items;
DROP TABLE IF EXISTS ca_checkouts;
DROP TABLE IF EXISTS ca_customers;
DROP TABLE IF EXISTS ca_stock;
DROP TABLE IF EXISTS ca_products;
DROP TABLE IF EXISTS ca_users;
DROP TABLE IF EXISTS ca_roles;

-- ==========================================
-- ROLES & USERS
-- ==========================================
CREATE TABLE ca_roles (
    role_id INT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE ca_users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES ca_roles(role_id)
);

-- ==========================================
-- PRODUCTS & STOCK
-- ==========================================
CREATE TABLE ca_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    vat_rate DECIMAL(5,2),
    description TEXT
);

CREATE TABLE ca_stock (
    product_id INT PRIMARY KEY,
    quantity INT NOT NULL DEFAULT 0,
    low_stock_threshold INT NOT NULL DEFAULT 10,
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);

-- ==========================================
-- CUSTOMERS
-- ==========================================
CREATE TABLE ca_customers ( 
	customer_id INT AUTO_INCREMENT PRIMARY KEY, 
    firstname VARCHAR(100) NOT NULL, 
    surname VARCHAR(100) NOT NULL, 
    dob date NOT NULL, 
    email VARCHAR(120), 
    phone VARCHAR(30), 
    houseNumber INT, 
    postcode VARCHAR(10), 
    account_holder BOOLEAN DEFAULT FALSE, 
    credit_limit DECIMAL(10,2) DEFAULT 0.00, 
    outstanding_balance DECIMAL(10,2) DEFAULT 0.00, 
    account_status VARCHAR(30) DEFAULT 'ACTIVE' );

-- ==========================================
-- CHECKOUTS
-- Used before sale is completed
-- ==========================================
CREATE TABLE ca_checkouts (
    checkout_id INT PRIMARY KEY,
    customer_id INT,
    checkout_status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checked_out_at TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES ca_customers(customer_id)
);

CREATE TABLE ca_checkout_items (
    checkout_item_id INT PRIMARY KEY,
    checkout_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    base_unit_price DECIMAL(10,2) NOT NULL,
    final_unit_price DECIMAL(10,2),
    deal_checked BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (checkout_id) REFERENCES ca_checkouts(checkout_id),
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);

-- ==========================================
-- DISCOUNTS
-- ==========================================
CREATE TABLE discounts (
    discount_check_id INT PRIMARY KEY,
    checkout_item_id INT NOT NULL,
    customer_id INT,
    external_discount_ref VARCHAR(50),
    deal_code VARCHAR(50),
    deal_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    checked_price DECIMAL(10,2),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (checkout_item_id) REFERENCES ca_checkout_items(checkout_item_id),
    FOREIGN KEY (customer_id) REFERENCES ca_customers(customer_id)
);

-- ==========================================
-- SALES
-- ==========================================
CREATE TABLE ca_sales (
    sale_id INT PRIMARY KEY,
    checkout_id INT UNIQUE,
    customer_id INT,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_deferred BOOLEAN DEFAULT FALSE,
    sale_source VARCHAR(20) DEFAULT 'IN_STORE',
    FOREIGN KEY (checkout_id) REFERENCES ca_checkouts(checkout_id),
    FOREIGN KEY (customer_id) REFERENCES ca_customers(customer_id)
);

CREATE TABLE ca_sale_items (
    sale_item_id INT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES ca_sales(sale_id),
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);

-- ==========================================
-- PAYMENTS
-- ==========================================
CREATE TABLE ca_payments (
    payment_id INT PRIMARY KEY,
    customer_id INT,
    sale_id INT,
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES ca_customers(customer_id),
    FOREIGN KEY (sale_id) REFERENCES ca_sales(sale_id)
);

-- ==========================================
-- SUPPLIER (SA INTERACTION - LOCAL COPY)
-- ==========================================
CREATE TABLE supplier_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    sa_order_ref VARCHAR(50),
    status VARCHAR(30) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP,
    last_status_at TIMESTAMP
);

CREATE TABLE supplier_order_items (
    order_item_id INT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES supplier_orders(order_id),
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);

CREATE TABLE supplier_invoices (
    invoice_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    due_date DATE,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES supplier_orders(order_id)
);

-- ==========================================
-- DELIVERIES
-- ==========================================
CREATE TABLE deliveries (
    delivery_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES supplier_orders(order_id)
);

CREATE TABLE delivery_items (
    delivery_item_id INT PRIMARY KEY,
    delivery_id VARCHAR(50) NOT NULL,
    product_id INT NOT NULL,
    quantity_received INT NOT NULL,
    FOREIGN KEY (delivery_id) REFERENCES deliveries(delivery_id),
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);

-- ==========================================
-- ONLINE ORDERS
-- ==========================================
CREATE TABLE ca_online_orders (
    online_order_id VARCHAR(50) PRIMARY KEY,
    pu_order_ref VARCHAR(50),
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE ca_online_order_items (
    online_order_item_id INT PRIMARY KEY,
    online_order_id VARCHAR(50) NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (online_order_id) REFERENCES ca_online_orders(online_order_id),
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);

-- ==========================================
-- STATEMENTS & REMINDERS
-- ==========================================
CREATE TABLE ca_statements (
    statement_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES ca_customers(customer_id)
);

CREATE TABLE ca_payment_reminders (
    reminder_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    reminder_type VARCHAR(20) NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'GENERATED',
    FOREIGN KEY (customer_id) REFERENCES ca_customers(customer_id)
);

-- ==========================================
-- STOCK MOVEMENTS
-- ==========================================
CREATE TABLE stock_movements (
    movement_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    change_amount INT NOT NULL,
    movement_type VARCHAR(30) NOT NULL,
    reference_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES ca_products(product_id)
);
