-- Terminal code to run this script:
-- sqlite3 CA_db.db < setup.sql
    
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
DROP TABLE IF EXISTS ca_customer_discounts;
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
    password_hash TEXT NOT NULL,
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
    product_type TEXT,
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
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    firstname VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    dob date NOT NULL,
    email VARCHAR(120),
    phone VARCHAR(30),
    houseNumber INT,
    postcode VARCHAR(10),
    account_holder INTEGER DEFAULT FALSE,
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
    deal_checked INTEGER NOT NULL DEFAULT FALSE,
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

CREATE TABLE ca_customer_discounts (
    customer_id INT PRIMARY KEY,
    plan_type VARCHAR(20) NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
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
    payment_deferred INTEGER DEFAULT FALSE,
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
    notes TEXT,
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
    processed INTEGER DEFAULT FALSE
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


-- ==========================================
-- FAKE DATA FOR CA_db
-- Generated using Python + Faker
-- ==========================================



-- ROLES
INSERT INTO ca_roles (role_id, role_name) VALUES (1, 'Admin');
INSERT INTO ca_roles (role_id, role_name) VALUES (2, 'Pharmacist');
INSERT INTO ca_roles (role_id, role_name) VALUES (3, 'Cashier');
INSERT INTO ca_roles (role_id, role_name) VALUES (4, 'Manager');

-- USERS
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (1, 'jenningshenry', '364b970d4123ab492bb8811e5bb187be1e3e04504af17001535f71bb003cb345', 1, '2024-07-16 14:06:28');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (2, 'daviesjanice', 'eff3cfda4c3ba15ea3e712126f43fe74f72330166e4d48e6a32e8f5523f8e016', 1, '2025-02-20 22:07:31');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (3, 'hollandcharlie', 'af738b28e0a93deae4483d186d93ab0ae1300f80dbd1bf73b8b367a58cb3cb4b', 3, '2025-07-10 19:22:30');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (4, 'moorefrancesca', 'c638a6858506086d5687b1ecb43c859eefd9919ac9b43a5745863f22f615b049', 2, '2025-02-19 01:20:55');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (5, 'lucywright', 'e5c3a3eab2dfaa06909c048da252ff9c315b6946a2ab2418bd99c755caeefa94', 2, '2024-04-04 06:04:41');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (6, 'ameliaoliver', '23c760a2a63fe3ddbfafc9dfdc23dd46efc18b856351d200d0e84d1212733c41', 2, '2024-09-13 10:40:18');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (7, 'timothy16', 'd246541e19cfec795a65143f6ab5a47d2b84e253b6be8df430a5a36f6859117d', 1, '2026-01-17 11:22:21');
INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES (8, 'rachael40', '82f6a5dbff87da01f016e11ce370ae7eea2e1d53820cafa5b6ddd511cbdece9a', 1, '2025-05-20 16:56:55');

-- PRODUCTS
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (1, 'Paracetamol', 3.50, 0.00, 'Pain relief and anti-inflammatory','Relieves mild to moderate pain and reduces fever.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (2, 'Ibuprofen', 4.20, 0.00, 'Pain relief and anti-inflammatory','Reduces pain, inflammation, and fever.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (3, 'Aspirin', 2.80, 0.00, 'Pain relief and anti-inflammatory','Relieves pain and can help prevent blood clots.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (4, 'Naproxen', 6.50, 0.00, 'Pain relief and anti-inflammatory','Treats pain and inflammation in joints and muscles.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (5, 'Codeine', 8.99, 0.00, 'Pain relief and anti-inflammatory','A stronger painkiller used for moderate pain relief.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (6, 'Loratadine', 5.99, 0.00, 'Cold, flue and allergy','Relieves allergy symptoms like sneezing and itching.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (7, 'Cetirizine', 4.75, 0.00, 'Cold, flue and allergy','Treats hay fever and allergic reactions.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (8, 'Diphenhydramine', 6.20, 0.00, 'Cold, flue and allergy','Relieves allergies and causes drowsiness.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (9, 'Pseudoephedrine', 5.40, 0.00, 'Cold, flue and allergy','Relieves nasal congestion.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (10, 'Phenylephrine', 4.60, 0.00, 'Cold, flue and allergy','Reduces blocked nose symptoms.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (11, 'Chlorphenamine', 3.90, 0.00, 'Cold, flue and allergy','Treats allergic reactions and hay fever.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (12, 'Omeprazole', 7.99, 0.00, 'Digestive system','Reduces stomach acid and treats acid reflux.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (13, 'Lansoprazole', 7.50, 0.00, 'Digestive system','Helps prevent and treat stomach ulcers.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (14, 'Gaviscon', 5.25, 0.00, 'Digestive system','Relieves heartburn by forming a protective barrier.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (15, 'Loperamide', 3.20, 0.00, 'Digestive system','Stops diarrhoea by slowing bowel movement.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (16, 'Senna', 2.95, 0.00, 'Digestive system','A laxative used to treat constipation.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (17, 'Bisacodyl', 3.10, 0.00, 'Digestive system','Stimulates bowel movements to relieve constipation.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (18, 'Amoxicillin', 9.99, 0.00, 'Antibiotics','Treats a wide range of bacterial infections.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (19, 'Doxycycline', 10.50, 0.00, 'Antibiotics','Used for infections such as acne and chest infections.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (20, 'Clarithromycin', 11.20, 0.00, 'Antibiotics','Treats respiratory and skin infections.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (21, 'Metronidazole', 8.75, 0.00, 'Antibiotics','Treats bacterial and parasitic infections.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (22, 'Flucloxacillin', 9.40, 0.00, 'Antibiotics','Used for skin and soft tissue infections.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (23, 'Hydrocortisone Cream', 4.30, 0.00, 'Skin treatment','Reduces inflammation and itching on the skin.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (24, 'Clotrimazole', 3.80, 0.00, 'Skin treatment','Treats fungal infections like athlete’s foot.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (25, 'Miconazole', 4.10, 0.00, 'Skin treatment','Used for fungal infections and oral thrush.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (26, 'Benzoyl Peroxide', 5.60, 0.00, 'Skin treatment','Treats acne by killing bacteria.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (27, 'Calamine Lotion', 3.70, 0.00, 'Skin treatment','Soothes itchy or irritated skin.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (28, 'Salbutamol Inhaler', 9.99, 0.00, 'Respiratory','Relieves asthma symptoms by opening airways.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (29, 'Beclometasone Inhaler', 12.50, 0.00, 'Respiratory','Prevents asthma attacks by reducing inflammation.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (30, 'Montelukast', 11.75, 0.00, 'Respiratory','Helps prevent asthma and allergy symptoms.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (31, 'Atorvastatin', 8.90, 0.00, 'Cardiovascular','Lowers cholesterol levels.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (32, 'Amlodipine', 7.80, 0.00, 'Cardiovascular','Treats high blood pressure.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (33, 'Ramipril', 7.60, 0.00, 'Cardiovascular','Lowers blood pressure and protects the heart.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (34, 'Warfarin', 9.20, 0.00, 'Cardiovascular','Prevents blood clots.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (35, 'Sertraline', 10.00, 0.00, 'Mental health / Neurological','Treats depression and anxiety.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (36, 'Fluoxetine', 9.50, 0.00, 'Mental health / Neurological','Used for depression and OCD.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (37, 'Diazepam', 8.30, 0.00, 'Mental health / Neurological','Relieves anxiety and muscle spasms.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (38, 'Insulin', 15.00, 0.00, 'Diabetes care','Controls blood sugar in diabetes.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (39, 'Levothyroxine', 6.80, 0.00, 'Hormone therapy','Treats an underactive thyroid.');
INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (40, 'Ferrous Sulfate', 4.50, 0.00, 'Health supplements','Treats iron deficiency anaemia.');


-- STOCK
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (1, 51, 27);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (2, 183, 23);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (3, 66, 17);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (4, 104, 29);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (5, 15, 23);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (6, 147, 6);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (7, 256, 10);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (8, 158, 24);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (9, 256, 15);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (10, 91, 30);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (11, 93, 24);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (12, 159, 12);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (13, 59, 25);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (14, 172, 23);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (15, 55, 8);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (16, 220, 20);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (17, 222, 9);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (18, 190, 15);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (19, 229, 28);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (20, 155, 7);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (21, 59, 12);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (22, 10, 16);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (23, 56, 15);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (24, 219, 10);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (25, 118, 25);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (26, 220, 7);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (27, 125, 27);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (28, 65, 26);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (29, 229, 25);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (30, 230, 28);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (31, 240, 15);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (32, 250, 19);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (33, 112, 5);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (34, 104, 13);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (35, 177, 11);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (36, 230, 12);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (37, 85, 27);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (38, 0, 7);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (39, 218, 16);
INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (40, 120, 13);

-- CUSTOMERS
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Maria', 'Jones', '1976-07-10', 'chloe14@example.org', '+44(0)118 496 0558', 139, 'G2 6FH', TRUE, 1500.00, 691.45, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Philip', 'Allan', '1982-10-05', 'nsanderson@example.com', '(0141) 496 0909', 122, 'LS05 6SX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Janice', 'Roberts', '1975-04-02', 'blloyd@example.com', '+44113 4960656', 25, 'DA7E 6YY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Cheryl', 'Payne', '2003-12-25', 'dkirk@example.org', '0114 496 0465', 106, 'W55 4SL', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jonathan', 'Jones', '1996-12-13', 'watkinsbruce@example.org', '+44(0)28 9018100', 14, 'L09 3FU', TRUE, 250.00, 80.52, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Aimee', 'Clark', '1975-01-28', 'xharrison@example.com', '+44116 496 0991', 28, 'M19 4YR', TRUE, 500.00, 76.08, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Patricia', 'Howarth', '1973-09-27', 'wrightteresa@example.org', '01154960491', 109, 'B5J 5DW', TRUE, 750.00, 277.58, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Eileen', 'Cook', '1988-10-29', 'xwebb@example.net', '+448081570726', 20, 'M98 7SY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Max', 'Stanley', '1976-12-12', 'whitebarbara@example.org', '0306 999 0799', 141, 'IM5A 5GU', TRUE, 250.00, 130.43, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Phillip', 'Evans', '1977-10-28', 'leonard94@example.net', '01134960831', 4, 'S78 7UT', TRUE, 500.00, 66.52, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Andrew', 'Green', '1975-04-28', 'tmarshall@example.net', '(020) 74960578', 55, 'N6T 5TL', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stewart', 'Smith', '1968-06-14', 'guybaldwin@example.net', '(0306) 999 0233', 43, 'LS4Y 1HN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Julian', 'Evans', '1980-10-23', 'waltersmalcolm@example.com', '+44(0)1134960084', 100, 'CO7B 9NU', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Catherine', 'Williams', '1972-10-15', 'smithlesley@example.org', '+44808 157 0167', 117, 'B2 9ND', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Frederick', 'Iqbal', '1988-07-25', 'zoepalmer@example.com', '(0121) 4960964', 143, 'B9T 3HL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Irene', 'Francis', '1976-07-25', 'lynntucker@example.org', '+441414960797', 76, 'BD3 4TD', TRUE, 250.00, 115.84, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joyce', 'Barnes', '1978-03-31', 'dianeclark@example.org', '+44(0)28 9018 0242', 81, 'B2 9YN', TRUE, 250.00, 116.84, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jennifer', 'Harvey', '2007-02-09', 'beth64@example.net', '+44191 496 0771', 136, 'B6T 9LA', TRUE, 250.00, 192.16, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('George', 'Wilson', '2006-02-16', 'watkinsellie@example.com', '(020) 7496 0027', 48, 'W4C 7DU', TRUE, 1500.00, 81.55, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Damien', 'Miles', '1982-02-02', 'taylorhugh@example.com', '+44(0)29 2018 0746', 104, 'B7B 4PE', TRUE, 1500.00, 295.46, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sophie', 'Taylor', '1960-04-27', 'mali@example.net', '+441314960977', 21, 'L4 4TU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Adrian', 'Day', '2003-02-12', 'carolynsteele@example.net', '(0113) 496 0861', 145, 'E71 7NW', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Diana', 'Robertson', '1993-01-28', 'jsmith@example.org', '01414960398', 53, 'WS2B 6PW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Vincent', 'Perry', '1979-06-29', 'kate97@example.org', '+44151 496 0875', 102, 'NR8 7PH', TRUE, 750.00, 274.33, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amelia', 'Smith', '1986-04-21', 'victoriathomas@example.net', '0161 4960662', 19, 'BD28 1TE', TRUE, 1000.00, 496.93, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kerry', 'Walker', '1961-04-15', 'michellecarr@example.org', '+44114 4960745', 26, 'S1W 8RP', TRUE, 1500.00, 255.79, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kayleigh', 'Edwards', '1993-06-13', 'richardsdamian@example.net', '+4429 2018431', 90, 'CB17 4AB', TRUE, 500.00, 147.81, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Victor', 'Coles', '1980-03-16', 'karen62@example.org', '(0191) 496 0692', 140, 'G19 9JU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Carole', 'Wilkins', '1991-08-16', 'kelly40@example.com', '0121 4960821', 136, 'HS94 4TN', TRUE, 1500.00, 359.25, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joe', 'Watkins', '1993-02-15', 'smithalexandra@example.com', '(020) 7496 0440', 35, 'IV4A 9UN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bernard', 'Jenkins', '1984-03-20', 'heatherbates@example.com', '(029)2018210', 28, 'TN7 9QF', TRUE, 750.00, 169.05, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('George', 'Walker', '1982-06-23', 'ijarvis@example.net', '+449098790588', 88, 'WA2 7NP', TRUE, 750.00, 303.25, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Geoffrey', 'Jones', '1965-05-14', 'erictaylor@example.net', '(029) 2018685', 14, 'S0 8ET', TRUE, 1000.00, 663.48, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Laura', 'Davies', '2005-12-30', 'fiona65@example.org', '(029) 2018370', 86, 'N9D 7NS', TRUE, 750.00, 96.95, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Connor', 'Davidson', '1962-10-10', 'valerie11@example.org', '+44(0)9098790826', 110, 'IG86 6EU', TRUE, 250.00, 15.05, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amber', 'Miles', '1979-04-12', 'marshallcharlie@example.com', '(0151)4960351', 39, 'IG8X 0RL', TRUE, 750.00, 349.51, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Karl', 'Morgan', '1991-03-10', 'adamsjemma@example.net', '+442074960005', 33, 'G93 8HY', TRUE, 750.00, 218.79, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Robin', 'Bradley', '1976-02-06', 'sean90@example.com', '(0909) 879 0228', 11, 'TR2 0FA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sarah', 'Pearson', '1976-06-07', 'andrew24@example.org', '+441154960681', 64, 'BR7R 8YE', TRUE, 750.00, 468.07, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alison', 'Heath', '2002-02-06', 'woodkaty@example.net', '(0121)4960700', 105, 'WD66 7TD', TRUE, 500.00, 345.84, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jonathan', 'Storey', '1970-05-03', 'clarkesara@example.net', '(020)74960856', 46, 'M7J 1EX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Robin', 'Sykes', '1975-10-17', 'dcook@example.com', '+44(0)141 4960156', 86, 'SG4 2UD', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('George', 'Lee', '1966-08-03', 'vglover@example.com', '(0808) 157 0280', 64, 'N1G 6BN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Grace', 'Webster', '1967-04-18', 'deanmoss@example.org', '0909 879 0158', 28, 'CH4 6XZ', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jayne', 'Davies', '1998-02-16', 'johnsylvia@example.net', '+441184960024', 121, 'TA4N 0GF', TRUE, 500.00, 326.63, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Anna', 'Moss', '1964-12-23', 'ashleighpage@example.org', '+44(0)1632960836', 79, 'LE52 4PY', TRUE, 500.00, 9.47, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jodie', 'Cunningham', '1963-10-28', 'charlesmitchell@example.org', '(029) 2018147', 85, 'KW7W 6LH', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sally', 'Clark', '1989-07-01', 'abbottjosephine@example.net', '(0161) 4960840', 72, 'S90 3NH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ashley', 'Miller', '1979-12-10', 'trevor07@example.net', '01514960226', 103, 'L8J 1RB', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amanda', 'Brown', '1965-07-17', 'beverley69@example.com', '01632 960641', 30, 'BA52 5DS', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kenneth', 'Smith', '2000-04-25', 'zbarry@example.com', '+44(0)1632 960535', 68, 'E81 5QF', TRUE, 250.00, 119.31, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Damian', 'Webb', '1977-08-30', 'kylefoster@example.net', '+44114 4960277', 81, 'W9S 5FT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joseph', 'Jones', '2003-03-18', 'henry90@example.com', '+44(0)161 496 0147', 131, 'BD05 1DZ', TRUE, 1000.00, 719.60, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marilyn', 'O''Sullivan', '1991-09-24', 'poweralexandra@example.net', '0117 496 0597', 12, 'G0H 5DW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Leah', 'Thompson', '1977-02-06', 'hscott@example.net', '028 9018 0255', 138, 'IP6 9BP', TRUE, 750.00, 258.78, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gary', 'Sheppard', '1998-03-19', 'uabbott@example.net', '+44(0)20 74960251', 85, 'G5E 2ZD', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dylan', 'Moore', '2004-01-13', 'scott81@example.net', '(029) 2018 0685', 32, 'N4 3PU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alex', 'Wilson', '1969-08-09', 'martindoyle@example.org', '+44(0)161 496 0880', 105, 'HR9E 2GG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hazel', 'Vaughan', '1971-07-05', 'xthomas@example.net', '(01632) 960379', 76, 'SY7 8JN', TRUE, 500.00, 168.18, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Pauline', 'Cooke', '1973-06-12', 'josephine97@example.com', '(0306) 9990468', 45, 'S2W 9FL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lee', 'Hart', '1985-07-03', 'ellisgeorgia@example.org', '0121 496 0124', 1, 'ZE82 1JT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Damien', 'Begum', '1988-06-23', 'frostkaren@example.org', '01414960153', 111, 'N1 2FB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mitchell', 'Bell', '1992-05-23', 'dianajones@example.net', '0113 4960104', 114, 'G89 1NJ', TRUE, 1500.00, 567.82, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Josh', 'Blake', '1976-06-20', 'ndawson@example.com', '(0114) 4960179', 44, 'B8K 2NS', TRUE, 750.00, 309.27, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('David', 'Richards', '1976-08-12', 'qkay@example.org', '01914960518', 86, 'B6W 0RQ', TRUE, 500.00, 269.12, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Howard', 'Morris', '1984-07-17', 'wardsylvia@example.net', '01154960952', 51, 'N8 2TU', TRUE, 250.00, 9.24, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Julia', 'Clayton', '1969-06-02', 'edwardsclare@example.org', '(0121) 496 0303', 19, 'N4 8UL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alan', 'Mitchell', '1973-03-31', 'susan05@example.com', '+44115 4960566', 148, 'LA6N 7UQ', TRUE, 1000.00, 395.50, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Maureen', 'Phillips', '1965-11-12', 'mferguson@example.org', '+44191 4960451', 2, 'N4 7ZS', TRUE, 1000.00, 175.07, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mohammed', 'Marshall', '1984-03-01', 'wthomas@example.net', '(0151) 496 0401', 133, 'RH6N 0FZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Josephine', 'Porter', '1962-08-11', 'josephsmith@example.net', '+44(0)131 496 0569', 64, 'G7 5TD', TRUE, 1000.00, 106.67, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marion', 'Khan', '1985-03-19', 'rmclean@example.org', '(0115)4960027', 136, 'S8B 4TH', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Molly', 'Hussain', '1993-09-01', 'adriankirk@example.org', '+44151 4960271', 114, 'WD5X 1XX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gregory', 'Ball', '1970-12-17', 'lindabond@example.org', '(0117) 496 0237', 141, 'N8 7XF', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Molly', 'Young', '1964-09-19', 'patricia78@example.com', '(0306) 9990691', 122, 'N17 8QF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lynn', 'Dawson', '1972-08-16', 'annkerr@example.org', '+448081570182', 64, 'DA2 3QW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Glen', 'Baker', '1977-04-18', 'heatherandrews@example.com', '+441154960498', 134, 'G9 2ZZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Tom', 'Gray', '1998-08-06', 'masonmatthew@example.org', '+44(0)1134960943', 71, 'S9S 7XN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jemma', 'Andrews', '1993-02-08', 'lydiastevenson@example.com', '+44114 496 0027', 74, 'LS73 9FP', TRUE, 750.00, 201.51, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stanley', 'Hunter', '1983-09-30', 'xclarke@example.net', '+44(0)1914960153', 21, 'CM47 2EB', TRUE, 500.00, 92.50, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gregory', 'Harding', '2002-02-13', 'ksmith@example.com', '(020) 7496 0532', 55, 'ML77 7AD', TRUE, 1000.00, 326.08, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lisa', 'Lowe', '1976-08-16', 'caroleingram@example.org', '0121 496 0797', 107, 'NN0 6FL', TRUE, 500.00, 333.16, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Claire', 'Miller', '1985-02-22', 'matthewsshirley@example.net', '0117 4960584', 150, 'S8 8LZ', TRUE, 1500.00, 456.46, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gail', 'Talbot', '1968-12-30', 'northdeclan@example.net', '+44(0)131 496 0239', 91, 'S8A 0FP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Elaine', 'Reynolds', '1970-05-18', 'tobybegum@example.com', '(0116)4960694', 108, 'N8W 9NU', TRUE, 1000.00, 175.54, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Andrew', 'Chan', '2006-02-04', 'robinsoncarole@example.com', '+44(0)3069990097', 8, 'SA9 0YU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ronald', 'Barry', '2002-06-01', 'rkennedy@example.org', '+441134960913', 104, 'W5 2SH', TRUE, 1000.00, 735.63, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Victoria', 'Knight', '2001-11-08', 'vwong@example.net', '(0114) 496 0283', 137, 'N7J 5GT', TRUE, 1000.00, 473.51, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stacey', 'Ward', '1984-05-08', 'kathryn73@example.org', '+44(0)1184960843', 22, 'TD4 7PU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Damien', 'Moore', '1978-11-07', 'adrian98@example.com', '(0141)4960524', 119, 'M1 7LU', TRUE, 250.00, 52.03, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Allan', 'Howell', '1996-11-22', 'chelsea42@example.org', '028 9018933', 117, 'L3 1SP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Megan', 'Spencer', '1969-08-06', 'arnoldcharles@example.com', '+44(0)289018773', 98, 'HG4 1YJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Eleanor', 'Hicks', '1962-10-13', 'helenyoung@example.org', '+44(0)113 496 0672', 108, 'WR4A 4YZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kenneth', 'Murray', '1983-01-16', 'sandra88@example.com', '+44(0)9098790287', 121, 'DG1 2TL', TRUE, 1500.00, 62.50, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Christian', 'Brown', '1983-03-08', 'kirsty32@example.net', '(0909) 879 0668', 58, 'CA6 2FU', TRUE, 250.00, 150.85, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brandon', 'Hudson', '1960-09-15', 'jacqueline37@example.com', '0131 496 0499', 52, 'M5 0ET', TRUE, 1500.00, 182.86, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mohammad', 'Walsh', '2006-12-06', 'hollie14@example.com', '028 9018332', 30, 'CV79 6XU', TRUE, 1000.00, 559.57, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Shannon', 'Roberts', '1975-02-08', 'gailmitchell@example.org', '01914960785', 43, 'E0 9XF', TRUE, 500.00, 385.89, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Roger', 'Mills', '1995-08-27', 'nclark@example.net', '(020)74960718', 7, 'TS07 8ST', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lynne', 'Tomlinson', '1991-09-16', 'daniel64@example.org', '+44(0)1632 960391', 97, 'S5 8BD', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Megan', 'Higgins', '1988-01-25', 'barrymiller@example.net', '+44(0)28 9018 0656', 51, 'WR66 8FQ', TRUE, 1500.00, 828.74, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Terence', 'Carpenter', '1996-10-20', 'uhill@example.org', '+44(0)808 157 0004', 27, 'SK86 3JT', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Denis', 'Nash', '1973-01-25', 'higginsirene@example.com', '028 9018033', 31, 'E9 7ZB', TRUE, 750.00, 319.65, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Duncan', 'Cox', '1987-08-14', 'nhenry@example.org', '+44(0)1154960843', 18, 'OX5W 3NF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Irene', 'Bishop', '1988-05-21', 'henry08@example.net', '+44(0)909 879 0268', 108, 'BL56 6SF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Clifford', 'Patel', '1996-11-06', 'osmith@example.com', '(0909) 879 0270', 93, 'S6J 6JL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dennis', 'Sheppard', '1965-08-16', 'fbaker@example.net', '(01632)960304', 112, 'SK99 1HY', TRUE, 1500.00, 1158.57, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Vanessa', 'Moore', '1992-11-12', 'brettstokes@example.org', '+44117 496 0317', 138, 'L63 4RT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Eleanor', 'Brooks', '1981-03-25', 'rebecca87@example.com', '0115 4960753', 69, 'HD6 9JF', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Andrew', 'Smith', '1999-12-27', 'mharris@example.com', '+44(0)117 4960693', 23, 'NR54 7TG', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jay', 'Thompson', '1997-06-08', 'igallagher@example.net', '(0114) 496 0801', 63, 'BL0P 3DF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('John', 'Lloyd', '1991-04-11', 'darren99@example.com', '029 2018 0700', 98, 'S0A 8NA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stephanie', 'Bradley', '2006-02-10', 'lforster@example.org', '0115 496 0823', 84, 'M54 1QR', TRUE, 1000.00, 169.70, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kelly', 'Armstrong', '2007-09-09', 'cliffordrichardson@example.org', '+44(0)289018016', 88, 'IM87 0GD', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dawn', 'Brady', '2004-02-17', 'anna18@example.org', '+44(0)117 4960397', 71, 'BH1 8YB', TRUE, 1500.00, 1137.68, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Antony', 'Murray', '1981-08-23', 'huntkate@example.org', '0306 999 0614', 105, 'L96 6FD', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Donna', 'Morris', '1983-10-12', 'gibsondale@example.org', '(0131) 496 0999', 62, 'TF50 7UJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Susan', 'Fisher', '1985-10-16', 'lskinner@example.net', '0141 4960194', 126, 'E14 6FR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Elliott', 'Evans', '1966-06-21', 'hewittlouise@example.com', '03069990412', 24, 'G6 8XW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jane', 'Webb', '1966-05-05', 'andrea19@example.net', '+443069990560', 63, 'KA6 8JY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Maria', 'Thompson', '1986-02-25', 'bradleyphillips@example.com', '+44161 496 0212', 95, 'FY64 1QL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Louis', 'Atkinson', '1993-12-25', 'claredean@example.com', '0113 4960659', 89, 'TR57 6ZF', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Clifford', 'Potter', '2007-07-23', 'catherinemclean@example.com', '+44(0)121 496 0479', 141, 'N64 5EY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marc', 'Wright', '1997-05-16', 'jillread@example.org', '+441632 960 737', 117, 'WA1 7FN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Cameron', 'Smith', '1970-09-25', 'epearson@example.com', '+44(0)20 7496 0796', 60, 'S8A 8ZD', TRUE, 500.00, 126.22, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Raymond', 'Hilton', '2004-12-28', 'mohammed90@example.net', '+44(0)28 9018 0656', 48, 'B1 3WW', TRUE, 500.00, 295.44, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Nicole', 'Jackson', '1999-05-22', 'katiepatel@example.com', '(0306)9990982', 135, 'BB7 4SD', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Connor', 'Holden', '1969-11-19', 'graeme57@example.org', '0191 4960757', 50, 'W7 1NB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Carolyn', 'Clark', '1983-08-04', 'daviesroger@example.net', '01184960828', 46, 'N86 3RG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Christian', 'Hart', '1989-08-25', 'nday@example.org', '+44151 4960966', 137, 'L3 1YE', TRUE, 750.00, 27.31, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Paula', 'Birch', '1982-06-05', 'clareclark@example.net', '(0909) 8790785', 75, 'S9G 5QT', TRUE, 1000.00, 82.07, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marian', 'Thompson', '2006-01-30', 'jayne91@example.net', '+44(0)115 4960513', 73, 'CH2 2WR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Samantha', 'Anderson', '1999-05-11', 'fdavison@example.net', '(0191)4960282', 88, 'GL22 7ZB', TRUE, 250.00, 50.50, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sarah', 'Watson', '1993-03-22', 'gordonsharp@example.net', '+44(0)161 496 0767', 30, 'SO77 1YA', TRUE, 1000.00, 393.40, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gerald', 'Harris', '1978-12-12', 'shannonbarber@example.com', '020 7946 0788', 14, 'E4 8BT', TRUE, 500.00, 324.46, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Janice', 'Lloyd', '1989-03-05', 'newmanhilary@example.org', '(0121) 4960074', 22, 'WN1 1JH', TRUE, 250.00, 111.61, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joan', 'Conway', '2001-10-09', 'ithompson@example.org', '(0808) 1570309', 58, 'NN4 5NN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marion', 'Phillips', '1995-04-01', 'kirkvictoria@example.org', '+44(0)118 4960223', 114, 'N36 2YL', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Teresa', 'Carroll', '1991-01-01', 'parkinsoncolin@example.com', '+44(0)1614960457', 110, 'HG90 7QD', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Eleanor', 'Simmons', '1989-06-24', 'oliviaphillips@example.com', '01314960892', 16, 'W5S 0ET', TRUE, 500.00, 250.21, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Andrew', 'Harvey', '1970-12-29', 'bmurphy@example.org', '+44292018242', 21, 'CA5 1QG', TRUE, 500.00, 69.53, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lee', 'Frost', '1981-01-12', 'annelynch@example.net', '0115 496 0037', 1, 'G9 8TA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('John', 'Booth', '1968-06-13', 'egarner@example.org', '+44(0)117 4960611', 121, 'N5 2RF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jemma', 'Turner', '1969-12-18', 'hilljohn@example.net', '+44(0)28 9018275', 74, 'DN2P 3DE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bradley', 'Mitchell', '2000-05-12', 'bparsons@example.com', '+44(0)306 9990234', 117, 'BT3V 0NH', TRUE, 500.00, 369.56, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Maureen', 'Jenkins', '1973-01-29', 'dharris@example.org', '+44161 496 0613', 51, 'RH91 5PF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Charlotte', 'Taylor', '1998-12-03', 'rowen@example.org', '(0306) 999 0710', 58, 'E0E 0BR', TRUE, 750.00, 495.98, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kathleen', 'Hussain', '1994-05-04', 'zdavison@example.org', '+4428 9018889', 43, 'M14 8HF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Paula', 'Rose', '2000-02-24', 'gordonamanda@example.net', '0909 879 0303', 146, 'S1 9ZB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dylan', 'King', '2005-01-08', 'trevorbrown@example.org', '+44(0)292018027', 120, 'NE8 2QF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Max', 'Hope', '1968-04-11', 'goodwinanne@example.com', '01914960149', 70, 'BS7R 0UY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mohammed', 'Owen', '1977-08-08', 'lawrencefrances@example.net', '(0115)4960380', 11, 'B3 7QR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kieran', 'Gardner', '1962-08-25', 'pwilson@example.com', '(01632) 960541', 65, 'N1J 2JW', TRUE, 250.00, 45.78, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jordan', 'Watson', '1964-12-07', 'xtaylor@example.com', '+44(0)1214960187', 148, 'N3 9NZ', TRUE, 750.00, 345.75, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Norman', 'Hall', '2000-07-04', 'xturner@example.org', '+441632 960832', 45, 'S0 8QA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Albert', 'Winter', '2004-12-21', 'ubaker@example.com', '01154960383', 114, 'LU02 1BJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Maria', 'Ali', '1985-08-04', 'fsimpson@example.net', '0115 496 0826', 150, 'B6 3NL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Guy', 'Bennett', '1986-12-25', 'elliott74@example.org', '+44114 4960329', 126, 'G1 7TP', TRUE, 1000.00, 278.37, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jane', 'O''Neill', '1984-08-16', 'alisonherbert@example.com', '09098790112', 27, 'GU9A 5FD', TRUE, 750.00, 246.99, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Frederick', 'Morgan', '1987-03-17', 'davieselliot@example.org', '+44113 4960678', 103, 'NR3B 1FE', TRUE, 1000.00, 70.45, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('James', 'Long', '1975-05-16', 'joewest@example.com', '+4429 2018199', 30, 'TW1 1HT', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Scott', 'Green', '1982-10-21', 'thomasbethany@example.org', '+44116 4960966', 1, 'BB66 5HG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Henry', 'White', '1970-05-11', 'flynnamber@example.org', '+44(0)28 9018 0476', 49, 'W0B 6FS', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marc', 'Graham', '1996-01-10', 'harrietturner@example.net', '+44(0)3069990065', 128, 'NP75 6LG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Richard', 'Newton', '1975-02-23', 'wheelerleonard@example.org', '(0808) 157 0785', 53, 'L2B 3LX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('William', 'Miller', '1975-03-05', 'levans@example.org', '0118 496 0955', 74, 'B5K 9HU', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joanna', 'Gordon', '1993-08-13', 'greendonald@example.net', '+441174960087', 125, 'N9 2PG', TRUE, 250.00, 194.63, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brandon', 'Howard', '1970-04-18', 'jamiebaker@example.com', '+44114 496 0569', 62, 'N4 2GS', TRUE, 750.00, 330.50, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ruth', 'Hunt', '2004-06-02', 'clive89@example.com', '+44(0)117 496 0926', 24, 'SS4 2AY', TRUE, 250.00, 92.29, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Deborah', 'Barton', '1998-11-10', 'claytonelliott@example.net', '+441174960917', 40, 'N13 5GD', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lindsey', 'Davies', '1983-02-03', 'nbrown@example.org', '+44(0)29 2018 0154', 75, 'B0 7SG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amy', 'Hughes', '1986-01-05', 'janice61@example.com', '+44(0)306 999 0932', 124, 'BS04 5LE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Liam', 'Cook', '1985-10-17', 'keithkaur@example.org', '01314960997', 142, 'BB6X 9SG', TRUE, 1000.00, 152.49, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alexander', 'Spencer', '1974-03-25', 'michelleharrison@example.net', '+441632 960 844', 35, 'EC1 6YX', TRUE, 750.00, 463.61, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Abigail', 'Dyer', '1984-10-18', 'rowebilly@example.net', '(028) 9018973', 88, 'B3 4DU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Connor', 'Herbert', '1987-04-17', 'qjones@example.com', '+44(0)1144960862', 73, 'WV6 2TB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marcus', 'Williams', '1978-03-02', 'maxarmstrong@example.org', '0306 999 0115', 149, 'S9D 6WS', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Paula', 'Holmes', '1992-07-21', 'aliceburns@example.com', '09098790089', 115, 'G1U 2GH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alex', 'Clarke', '1989-01-20', 'scotttracy@example.org', '+44808 157 0294', 142, 'SS1 6XR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lynn', 'Rose', '1979-01-15', 'abell@example.net', '(028) 9018 0986', 83, 'S2 9YY', TRUE, 500.00, 228.72, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Oliver', 'Bennett', '1998-07-14', 'thorntonpaula@example.com', '+449098790646', 106, 'LU9W 0GL', TRUE, 750.00, 446.82, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sophie', 'Connor', '2001-08-30', 'vthomas@example.net', '0118 496 0074', 98, 'BA5 4LU', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bethan', 'Richardson', '1975-10-03', 'cliffordsimpson@example.com', '+44306 999 0546', 39, 'E3H 6UW', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Karen', 'Perry', '1995-04-23', 'garykemp@example.net', '+44141 4960289', 33, 'G3 0JB', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Caroline', 'Bentley', '1984-10-07', 'henrychan@example.com', '+44(0)161 496 0610', 113, 'N79 2UY', TRUE, 1500.00, 1092.53, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lynn', 'Stone', '1971-05-16', 'charlene14@example.org', '01414960029', 37, 'L33 6WA', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jill', 'Bailey', '1969-03-31', 'graceroberts@example.org', '(0118) 4960944', 40, 'YO65 4HT', TRUE, 1000.00, 625.22, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Josh', 'Davies', '2002-09-05', 'ajackson@example.net', '029 2018589', 102, 'M4S 7DP', TRUE, 750.00, 511.40, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Martyn', 'Hart', '1979-02-01', 'abbie43@example.org', '0191 498 0309', 98, 'SE52 7NL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Samantha', 'Gibbons', '1962-08-24', 'glennwood@example.org', '+4429 2018875', 125, 'M2W 4EU', TRUE, 1500.00, 82.10, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Scott', 'Cox', '1998-04-14', 'gaillyons@example.net', '+44(0)114 4960353', 74, 'WR4P 5LY', TRUE, 250.00, 86.79, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Billy', 'Hall', '1968-04-04', 'ocollier@example.net', '(020) 74960917', 26, 'E68 6BF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ashley', 'Chambers', '1983-07-25', 'dscott@example.org', '+441214960217', 77, 'RG2 0AT', TRUE, 250.00, 64.87, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Henry', 'Kelly', '1971-09-19', 'wendythornton@example.org', '+44(0)115 496 0966', 92, 'KW76 0XH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Karen', 'Giles', '1982-03-03', 'jackdavies@example.net', '+441632 960335', 63, 'CO1 8YN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mohammed', 'Collins', '1963-05-10', 'gregory78@example.net', '01914960562', 47, 'ZE7 3GR', TRUE, 500.00, 31.59, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jack', 'Wilson', '1969-03-04', 'danielwright@example.org', '+44115 4960506', 62, 'EN8W 9BE', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hilary', 'Lee', '1963-07-11', 'fletcherjessica@example.org', '+441914960472', 37, 'B46 8LZ', TRUE, 1000.00, 510.32, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lynda', 'Harrison', '1988-09-28', 'lewismarian@example.org', '0121 496 0117', 3, 'L48 5SN', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Shaun', 'Thomas', '1994-01-07', 'charlenebegum@example.com', '0118 496 0001', 140, 'W2 8DE', TRUE, 250.00, 88.35, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Douglas', 'Berry', '1991-04-29', 'arthur70@example.org', '(0808) 1570204', 77, 'TR5 1EB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('John', 'Davis', '2005-05-20', 'hughevans@example.com', '(028) 9018 0415', 117, 'DE1 6TL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Emma', 'Marshall', '1992-10-14', 'zbrooks@example.org', '(0115) 4960202', 99, 'S9 9TG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kathryn', 'Palmer', '1984-08-24', 'taylorcallum@example.com', '(0161) 4960167', 98, 'E4 0WY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Anna', 'Wilson', '2005-10-29', 'maureen89@example.org', '01514960375', 76, 'SK6E 0GW', TRUE, 1000.00, 219.58, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Pauline', 'Barton', '1971-07-02', 'myersdanny@example.org', '0131 496 0408', 13, 'S63 7TY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lucy', 'Nicholson', '1994-03-01', 'fsaunders@example.net', '+44(0)289018016', 74, 'BD88 1ZZ', TRUE, 1500.00, 962.32, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kim', 'Rogers', '1994-11-01', 'abbiedavies@example.com', '+44(0)131 496 0037', 49, 'NW9 5TE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lewis', 'Carter', '1975-05-02', 'cookashleigh@example.com', '+441914960851', 36, 'G7 6EL', TRUE, 250.00, 61.79, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kathryn', 'Chapman', '1968-06-17', 'ystevens@example.org', '(01632) 960 516', 149, 'E7 9WF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dawn', 'Burgess', '1963-07-20', 'ebryant@example.net', '+44306 9990292', 24, 'TW2B 9ZP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Leanne', 'Wallace', '1988-09-24', 'henrysimmons@example.com', '(0121) 496 0722', 107, 'PL84 8HH', TRUE, 500.00, 52.86, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rhys', 'Johnson', '1980-01-07', 'ellie22@example.net', '+44191 496 0515', 94, 'W9K 8NS', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('James', 'Norris', '1961-12-18', 'qlane@example.org', '(0117) 496 0424', 66, 'EN2A 3XB', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sarah', 'Bradley', '1967-03-21', 'eileenmoore@example.org', '+44(0)161 4960406', 76, 'KT58 0LH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jasmine', 'Taylor', '1990-05-24', 'ashleighcampbell@example.net', '+44(0)131 4960989', 120, 'L47 1GG', TRUE, 500.00, 301.66, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Katherine', 'Baldwin', '1963-01-03', 'qwhite@example.org', '(0116)4960940', 102, 'LL2 2PZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lee', 'Griffin', '2002-10-19', 'abigail98@example.com', '+44114 496 0583', 102, 'E82 8XR', TRUE, 750.00, 321.94, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Colin', 'Stone', '1974-10-05', 'mohamed54@example.org', '0306 999 0987', 68, 'B1S 7JZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brenda', 'Smith', '1962-12-16', 'margaret16@example.com', '+44191 496 0408', 96, 'ML8 7BN', TRUE, 500.00, 188.59, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Naomi', 'Lucas', '1995-03-19', 'wellsmohammed@example.net', '(0191) 4960013', 144, 'RG3X 1HX', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rita', 'Shaw', '1989-11-10', 'morriscarl@example.org', '+44(0)151 496 0501', 57, 'B2 8DY', TRUE, 1000.00, 727.51, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Julian', 'Walker', '1987-12-25', 'zprice@example.com', '+441214960061', 105, 'B9B 1QW', TRUE, 500.00, 18.14, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kenneth', 'Harris', '2006-12-01', 'lynda14@example.com', '0141 4960607', 127, 'L26 2NQ', TRUE, 250.00, 46.96, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mark', 'Fisher', '1998-01-06', 'harrythomas@example.net', '+442074960688', 100, 'M3 3SW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Patrick', 'Walsh', '1975-04-08', 'gordon12@example.net', '0808 157 0908', 139, 'RM81 1LE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joe', 'Wood', '1993-05-25', 'susan23@example.org', '0121 496 0913', 40, 'LU7 9NY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Carl', 'Armstrong', '1985-01-17', 'anne20@example.com', '(0118) 496 0364', 126, 'CR5 7TQ', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stewart', 'Jones', '1967-08-26', 'leahjenkins@example.com', '(0909) 879 0283', 72, 'SS1 0WA', TRUE, 750.00, 130.36, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kimberley', 'Jackson', '2000-05-24', 'alanfisher@example.net', '+44191 496 0725', 61, 'DT94 7WW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('George', 'Frost', '1994-06-01', 'adamsjayne@example.net', '+44116 496 0827', 95, 'G99 7QB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gerald', 'Carter', '1976-01-06', 'pritcharddonald@example.org', '(029) 2018 0385', 71, 'LN70 5EW', TRUE, 250.00, 189.80, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ashleigh', 'Burke', '1978-02-28', 'nicolalambert@example.com', '+4420 7496 0184', 24, 'DT86 5UU', TRUE, 1500.00, 1165.31, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rachael', 'Bailey', '1969-09-13', 'ethompson@example.net', '+44289018432', 86, 'G59 3SP', TRUE, 500.00, 314.79, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Geoffrey', 'Jones', '1992-10-29', 'kkelly@example.net', '+44(0)808 157 0603', 142, 'G9 2WB', TRUE, 1500.00, 259.14, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marion', 'Kennedy', '1971-07-25', 'jeremy86@example.net', '020 7946 0041', 85, 'W97 2JS', TRUE, 1500.00, 3.40, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Grace', 'Sanders', '1999-11-22', 'saraknowles@example.com', '+44116 496 0579', 38, 'E3G 2EA', TRUE, 1500.00, 300.79, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Reece', 'Norris', '1994-07-25', 'mmason@example.org', '+44(0)116 496 0799', 7, 'E1 2ZX', TRUE, 250.00, 71.65, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('David', 'Wheeler', '2006-06-02', 'xbishop@example.org', '+44(0)29 2018863', 83, 'TQ65 6FL', TRUE, 500.00, 106.15, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lesley', 'Miller', '1965-12-12', 'june86@example.com', '0117 496 0009', 108, 'E8A 3PS', TRUE, 250.00, 95.25, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Linda', 'Dean', '1989-03-28', 'elliot86@example.net', '+44(0)131 496 0946', 132, 'S88 2QX', TRUE, 1000.00, 403.07, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Suzanne', 'Jones', '1981-02-09', 'diana62@example.net', '+44115 496 0372', 12, 'L8 5XZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bethan', 'Richardson', '1963-10-14', 'janetarnold@example.org', '0808 1570127', 8, 'S1B 3QD', TRUE, 1000.00, 677.84, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Tina', 'Thomas', '1986-05-25', 'hflynn@example.com', '01632960902', 28, 'ME7A 8NH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joshua', 'Leonard', '1994-12-26', 'jaynethompson@example.org', '+441314960302', 114, 'M6 6RY', TRUE, 250.00, 64.42, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marc', 'Weston', '2008-02-15', 'bellgeorgina@example.com', '(01632)960895', 33, 'TW4 9HT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sophie', 'Allen', '1978-01-04', 'janelowe@example.net', '+44114 496 0845', 150, 'M8 7RY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Pamela', 'Moran', '1983-05-11', 'ldavies@example.org', '(0161) 496 0141', 136, 'RH33 6QW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Paula', 'Potts', '1978-03-01', 'gerardgreen@example.net', '+44(0)1632960518', 111, 'W55 9LG', TRUE, 250.00, 170.56, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jill', 'Begum', '1973-03-08', 'ppratt@example.net', '0118 4960433', 142, 'L95 1ED', TRUE, 1000.00, 361.24, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sian', 'Andrews', '1993-10-08', 'millerjoanna@example.org', '0909 8790759', 87, 'ME9 7GW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Leonard', 'Simmons', '1999-06-27', 'alexandercarey@example.com', '01614960808', 25, 'IV2 1WT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Guy', 'Conway', '1961-01-17', 'jessicajackson@example.com', '+441314960942', 66, 'M3E 9PQ', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jeffrey', 'Morley', '1974-07-27', 'xharrison@example.com', '09098790647', 122, 'G93 4JX', TRUE, 250.00, 166.35, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ann', 'Baxter', '1973-08-02', 'kieranjones@example.org', '+44(0)116 496 0672', 25, 'NE8Y 7NL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Chelsea', 'Taylor', '1963-06-28', 'kgibson@example.org', '+44117 4960471', 143, 'SW54 5XX', TRUE, 1500.00, 1147.95, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Douglas', 'Ward', '1988-04-06', 'parsonsjosephine@example.net', '01174960998', 32, 'M55 7DR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jayne', 'Hussain', '2003-03-26', 'mohammedhart@example.com', '+44(0)1414960996', 109, 'E2 3PP', TRUE, 750.00, 360.25, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hilary', 'Harris', '1978-06-12', 'cdixon@example.com', '+44(0)1632960987', 148, 'DA20 3LD', TRUE, 500.00, 262.69, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rhys', 'Thompson', '1967-04-03', 'collinselaine@example.net', '0114 4960068', 28, 'E4 1RN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bernard', 'Smith', '1979-08-01', 'ijohnson@example.net', '+44(0)808 1570200', 95, 'HU5R 8LX', TRUE, 750.00, 344.46, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Louise', 'Kirk', '2007-09-19', 'marieanderson@example.net', '+44(0)1632960968', 144, 'RH8M 7XJ', TRUE, 1500.00, 1114.90, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Craig', 'Williams', '1985-02-18', 'tsmith@example.org', '0113 496 0825', 69, 'LN8 7UN', TRUE, 500.00, 109.31, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('John', 'Miller', '1980-03-05', 'thomasfrench@example.org', '+44(0)141 496 0866', 87, 'G66 4DS', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kayleigh', 'Smith', '2001-12-21', 'glen84@example.com', '0117 496 0122', 37, 'CH7 4ZU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Roy', 'Potter', '1970-08-06', 'morgandaniel@example.org', '01154960442', 8, 'LA0H 2AU', TRUE, 1500.00, 258.16, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Charlie', 'Cook', '1981-06-12', 'dturner@example.net', '+44(0)306 9990051', 88, 'B46 8UG', TRUE, 750.00, 186.98, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alex', 'Bowen', '1977-04-05', 'hfinch@example.net', '(0118) 496 0673', 146, 'BD3R 8HU', TRUE, 250.00, 31.12, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Janet', 'Davies', '1981-06-25', 'sam08@example.net', '+44115 4960474', 13, 'N03 3SP', TRUE, 750.00, 265.87, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stephen', 'Thompson', '1979-01-12', 'byrnenorman@example.org', '+44(0)113 4960979', 114, 'N13 7DZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Declan', 'Begum', '2002-10-13', 'howardleah@example.org', '+44(0)292018812', 132, 'DY58 7HA', TRUE, 750.00, 257.95, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Charlene', 'Patel', '1969-05-30', 'simon77@example.net', '(0121) 496 0873', 125, 'G8F 7LZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Andrea', 'Walsh', '1996-05-21', 'barbaradoyle@example.com', '+44191 496 0570', 102, 'MK6Y 0ZQ', TRUE, 250.00, 40.88, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jasmine', 'Smith', '1964-07-21', 'rbarrett@example.com', '(0306) 9990829', 36, 'HG6 1EW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Katy', 'Rice', '1969-01-27', 'ryanhowell@example.com', '0117 4960109', 31, 'WC6X 8ZY', TRUE, 1000.00, 597.61, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Douglas', 'Parker', '1975-04-07', 'browngavin@example.net', '(0161)4960170', 98, 'NW6 0ZL', TRUE, 1500.00, 670.47, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Debra', 'Thomas', '1965-01-12', 'martin38@example.org', '0115 4960386', 91, 'L83 8XS', TRUE, 1000.00, 689.41, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kenneth', 'Miller', '1999-06-24', 'frances76@example.org', '+44116 496 0286', 5, 'N2J 5PX', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Victor', 'Brady', '1988-04-20', 'umason@example.net', '0118 4960983', 81, 'TD84 7TR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('David', 'Wood', '1979-08-08', 'westonjosh@example.org', '(0121) 4960335', 107, 'M8 1BT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Susan', 'Bryan', '1978-04-11', 'carole33@example.com', '(0808) 157 0419', 6, 'OL31 7GU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hollie', 'Campbell', '1966-09-25', 'ian96@example.org', '+44306 9990055', 118, 'KT13 6BN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Judith', 'Thomas', '1996-12-26', 'tobykerr@example.org', '(0116) 496 0067', 28, 'E3G 6FF', TRUE, 1000.00, 471.10, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Tom', 'Barlow', '1999-02-17', 'frenchmarcus@example.org', '+44141 496 0862', 102, 'W83 6YH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Chelsea', 'Richards', '1995-12-02', 'normanhammond@example.com', '+44(0)121 4960911', 57, 'KA6N 3PQ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marilyn', 'Lynch', '1980-12-26', 'brucerichards@example.com', '(028) 9018 0270', 20, 'L52 1BJ', TRUE, 1500.00, 611.94, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jasmine', 'Bennett', '1979-10-27', 'wardjamie@example.com', '+44151 4960705', 90, 'L38 8UZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Patrick', 'Booth', '2005-09-19', 'patelcheryl@example.net', '+44(0)1134960420', 38, 'DH9 0TA', TRUE, 250.00, 29.29, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joseph', 'McCarthy', '1978-09-15', 'raymond04@example.net', '01414960368', 40, 'CB5R 2HW', TRUE, 500.00, 380.52, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Clare', 'Moore', '1961-09-15', 'smithmelanie@example.com', '0131 4960762', 119, 'N5 4JW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Martyn', 'Barker', '2002-10-30', 'charlotte08@example.com', '+44(0)117 496 0256', 145, 'CR1Y 8ZJ', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Helen', 'Smith', '1970-08-21', 'mcoates@example.com', '+44151 496 0823', 81, 'CR9V 2NW', TRUE, 1000.00, 54.63, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Barry', 'Sykes', '1970-02-13', 'elliotttownsend@example.net', '(01632) 960125', 78, 'B56 4TL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Derek', 'Marsh', '1967-07-05', 'jeffreypayne@example.net', '028 9018499', 91, 'L9D 0QD', TRUE, 750.00, 277.05, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Charlene', 'Porter', '1969-05-14', 'xellis@example.org', '09098790677', 95, 'G33 6AL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amy', 'Wilson', '2005-12-05', 'denniscollins@example.com', '(0909)8790975', 24, 'WV36 0ZR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Terry', 'North', '1999-03-01', 'reynoldsalison@example.com', '+44808 1570038', 142, 'S0J 8BH', TRUE, 1000.00, 727.24, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Iain', 'Williams', '1980-12-19', 'bethany26@example.com', '028 9018 0082', 49, 'WA71 2YX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Barry', 'Leach', '1982-04-03', 'djennings@example.net', '01632960371', 129, 'HG2 1ET', TRUE, 250.00, 90.10, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ashleigh', 'Evans', '1995-11-21', 'gwood@example.net', '(0116) 4960686', 88, 'G5 2FG', TRUE, 1500.00, 775.35, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lee', 'Burton', '1981-04-22', 'lbarber@example.org', '+44(0)115 496 0309', 113, 'AL7 7XA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Tina', 'Young', '1976-06-06', 'joanknowles@example.com', '+441414960719', 41, 'B3J 9XH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Adam', 'Gallagher', '1963-12-28', 'alan20@example.net', '(020) 7496 0945', 73, 'B1 2GN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kathryn', 'Benson', '2007-11-13', 'carolinemorris@example.com', '+44(0)113 496 0145', 87, 'YO6 6XD', TRUE, 750.00, 39.55, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Iain', 'Jones', '1968-07-18', 'hugh86@example.net', '(0117)4960390', 99, 'E7 6ZP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Garry', 'Whittaker', '2002-08-27', 'callum99@example.com', '0191 4960772', 39, 'L4D 1AT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kayleigh', 'Roberts', '1974-05-09', 'vcarroll@example.com', '+44(0)1914960303', 37, 'GL4B 4WX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brandon', 'Perkins', '1967-12-28', 'maurice69@example.net', '+44113 4960235', 101, 'SK7 0FU', TRUE, 1500.00, 850.60, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dean', 'Johnson', '1996-10-13', 'bethany60@example.net', '(0121) 4960958', 144, 'B3K 5DF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Leonard', 'Gray', '1983-04-28', 'kjohnson@example.net', '+44(0)2074960629', 85, 'M5 4SD', TRUE, 1500.00, 112.14, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jean', 'Shaw', '1985-07-12', 'tburke@example.org', '01914960421', 131, 'TN0 1TW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Peter', 'Roberts', '1994-04-09', 'karlcook@example.com', '+441632 960845', 80, 'E82 0TR', TRUE, 500.00, 136.69, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Zoe', 'Clark', '1981-05-28', 'holmesmarilyn@example.org', '0131 4960701', 50, 'M0K 3PH', TRUE, 500.00, 61.98, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alex', 'Hussain', '1996-06-18', 'chloe14@example.org', '(0116) 4960410', 26, 'E3J 8PL', TRUE, 750.00, 525.84, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Patrick', 'Hewitt', '1979-07-09', 'ronaldhammond@example.net', '01314960870', 97, 'B70 6BD', TRUE, 500.00, 72.34, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rachel', 'Gilbert', '2008-03-12', 'trichards@example.com', '(0808)1570381', 43, 'OL21 1TN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lydia', 'Berry', '1991-11-30', 'obarnes@example.org', '(0909) 8790945', 94, 'DE55 7AD', TRUE, 1000.00, 488.48, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alice', 'Clark', '1992-10-24', 'sbaker@example.com', '+44(0)20 74960928', 115, 'S1 8DN', TRUE, 1500.00, 287.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stacey', 'Hall', '2000-06-05', 'psmith@example.net', '(0116) 4960761', 121, 'DL9 6YP', TRUE, 750.00, 406.98, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Paige', 'Garner', '1972-01-09', 'coxmarion@example.com', '(0115)4960997', 113, 'NW1 2NR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brian', 'Anderson', '2006-11-22', 'pmills@example.net', '(0114) 496 0132', 98, 'B2S 7XN', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Janet', 'Richards', '1990-09-03', 'russelldavies@example.com', '(0121) 4960946', 52, 'HS1W 9WR', TRUE, 750.00, 31.31, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Scott', 'Davis', '1964-06-28', 'georgina00@example.net', '+44(0)1914960514', 96, 'L6 5RR', TRUE, 1500.00, 1021.40, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Margaret', 'Williams', '1974-08-13', 'alicekhan@example.net', '01414960562', 42, 'WR2 0DA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gareth', 'Atkinson', '1993-05-13', 'isimpson@example.org', '+44(0)1154960679', 132, 'PR27 8TR', TRUE, 1000.00, 73.37, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Owen', 'Wilson', '1989-02-23', 'whiteheadfrank@example.net', '+441614960468', 116, 'N0A 5EY', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hayley', 'Hunt', '1965-09-09', 'kerryrobinson@example.com', '+44(0)1514960818', 107, 'E3H 8YN', TRUE, 1000.00, 401.61, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Molly', 'Manning', '1983-08-15', 'jonessally@example.com', '02074960565', 21, 'GY2 9NY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Elliot', 'Long', '1992-06-10', 'marionbarnett@example.com', '(0808) 157 0904', 82, 'BT28 4LF', TRUE, 750.00, 474.83, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amber', 'White', '1977-09-23', 'coxrachael@example.org', '+4420 74960275', 74, 'M37 8BP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Graham', 'Morgan', '2000-10-08', 'oliviamitchell@example.com', '(0306)9990637', 36, 'RH2H 0LE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lee', 'Thompson', '1987-05-18', 'vatkins@example.net', '+44(0)1174960667', 2, 'CT8 0NT', TRUE, 250.00, 51.18, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Margaret', 'Davies', '1996-04-29', 'gibsonstacey@example.net', '+44131 496 0694', 141, 'FK4 4YR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bethany', 'Griffin', '1976-09-11', 'mariahaynes@example.net', '+44(0)116 4960580', 74, 'AL1A 1WE', TRUE, 750.00, 73.11, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lydia', 'Williams', '1975-03-05', 'tony30@example.org', '0289018109', 118, 'YO3W 1DZ', TRUE, 250.00, 167.34, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Callum', 'Patel', '2004-05-01', 'jamiebooth@example.com', '(0121) 496 0717', 138, 'TD6 4GD', TRUE, 1500.00, 690.06, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Martyn', 'O''Donnell', '1986-04-17', 'dross@example.com', '(0808) 1570427', 75, 'W3 2UE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gareth', 'Henderson', '1989-08-03', 'jaynegraham@example.com', '(01632) 960 410', 91, 'E9 7AU', TRUE, 1500.00, 499.88, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kieran', 'Riley', '1960-04-20', 'kingvincent@example.org', '+44(0)292018569', 22, 'W7 6DX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Eric', 'Harper', '2007-02-23', 'ioneill@example.com', '0131 4960460', 135, 'RM1N 1TN', TRUE, 1000.00, 698.67, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Eileen', 'Martin', '1997-12-22', 'morganirene@example.org', '(0121) 4960615', 100, 'BT73 0HA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jenna', 'Smith', '1986-09-12', 'jamescarly@example.com', '+44161 4960870', 5, 'N0 0RE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Phillip', 'Gough', '2005-08-27', 'isingh@example.org', '+44(0)1632 960 931', 89, 'G7 7ZB', TRUE, 250.00, 154.30, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Norman', 'Harrison', '1969-02-15', 'thompsonadam@example.com', '+44808 157 0179', 86, 'E11 9ZJ', TRUE, 250.00, 70.46, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Philip', 'Roberts', '1989-03-31', 'josephine65@example.org', '+4429 2018982', 45, 'WC3 9GP', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Philip', 'O''Neill', '1969-11-08', 'xthompson@example.net', '+44116 496 0739', 123, 'G1 2AU', TRUE, 500.00, 25.24, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jonathan', 'Bailey', '1972-06-14', 'goddardjenna@example.com', '+44(0)141 4960723', 118, 'M87 3GZ', TRUE, 750.00, 120.95, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hazel', 'Thomas', '1972-06-28', 'fblackburn@example.net', '+44808 1570456', 11, 'L3 8EZ', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Linda', 'Taylor', '1996-12-20', 'gillianwelch@example.net', '(0117)4960403', 132, 'G7 2GB', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alexander', 'Berry', '1979-08-23', 'tracysmith@example.net', '08081570701', 140, 'BL8E 0UW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Connor', 'Bruce', '1976-04-03', 'uwright@example.com', '01174960531', 49, 'DY1 6HR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gerald', 'Ford', '2000-01-22', 'bholloway@example.org', '+44117 4960972', 13, 'IG27 5LH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Albert', 'Clarke', '2007-05-07', 'whitejamie@example.com', '+44(0)151 496 0625', 95, 'M92 9XJ', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Nicholas', 'Ali', '1995-10-01', 'ntaylor@example.net', '0161 4960740', 113, 'KW3H 6YJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marie', 'Harding', '1999-04-14', 'fletchersamuel@example.org', '0161 496 0806', 48, 'S7U 7UJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jake', 'Doherty', '1961-02-01', 'igiles@example.com', '(0121) 496 0310', 95, 'SG42 9YA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sandra', 'Hall', '1969-09-04', 'xgallagher@example.net', '+44(0)151 4960016', 109, 'HP8A 6LZ', TRUE, 1000.00, 481.96, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joanna', 'Allen', '1974-05-04', 'houghtonalbert@example.net', '01144960850', 140, 'S5 9BQ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Claire', 'Jarvis', '1998-04-08', 'mooredennis@example.org', '0131 4960381', 21, 'LS9Y 3PQ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Vincent', 'Heath', '1989-01-08', 'alexander15@example.com', '+44151 4960788', 79, 'W8 7ZQ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ellie', 'Harding', '1964-09-16', 'clarehopkins@example.com', '+44(0)116 496 0411', 110, 'M12 2HW', TRUE, 1000.00, 281.24, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Teresa', 'Brown', '1988-08-03', 'elaineward@example.com', '+441632960043', 91, 'B3 6YP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Abbie', 'Willis', '1982-06-13', 'swright@example.net', '+44(0)8081570877', 15, 'OL2 2LJ', TRUE, 1000.00, 290.65, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Pamela', 'Patel', '1979-11-07', 'brayglen@example.com', '+44116 496 0928', 41, 'DE2 2JE', TRUE, 500.00, 339.47, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Luke', 'Turner', '1999-05-04', 'chloesmith@example.org', '(0117) 4960805', 113, 'CT5 8GX', TRUE, 500.00, 26.89, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Josh', 'Blake', '1961-12-09', 'xbegum@example.org', '+44(0)151 496 0520', 94, 'NP8N 7NY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dorothy', 'Kennedy', '1998-09-15', 'hcook@example.net', '01614960028', 146, 'M0 9JT', TRUE, 1500.00, 184.13, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Susan', 'Green', '1963-12-27', 'carolehill@example.com', '01174960018', 95, 'SK18 3UP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mandy', 'Butler', '1964-01-22', 'patricia26@example.com', '01414960504', 20, 'HS4 8DH', TRUE, 1500.00, 440.34, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Louise', 'Cox', '1988-07-11', 'zbarber@example.net', '0151 496 0629', 72, 'E2D 7WP', TRUE, 250.00, 5.18, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gary', 'Begum', '2000-06-09', 'anicholson@example.net', '+44(0)118 496 0628', 133, 'SO92 2RN', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Andrea', 'Hughes', '1980-10-17', 'valerie87@example.org', '+44113 496 0024', 31, 'RH7 4SG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Abigail', 'Walker', '2004-02-14', 'matthewbaldwin@example.com', '+44161 496 0195', 115, 'W9G 7EQ', TRUE, 1500.00, 342.69, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sally', 'Hope', '1961-06-09', 'ben90@example.org', '+44(0)121 496 0725', 126, 'B45 5BN', TRUE, 250.00, 27.15, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Iain', 'Hill', '1965-06-21', 'teresaakhtar@example.org', '+44(0)20 7496 0285', 45, 'UB4 5EX', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rosemary', 'Parsons', '1970-01-09', 'khanlawrence@example.com', '+44306 9990765', 82, 'E32 3XZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hollie', 'Holden', '1996-01-06', 'fletchermartin@example.org', '(0808)1570207', 141, 'HA5 7ZW', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Glenn', 'Thompson', '1980-12-22', 'morristerence@example.org', '+441154960234', 41, 'L21 1DA', TRUE, 750.00, 305.25, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Pamela', 'Reed', '1963-02-19', 'raymondrhodes@example.net', '+44(0)1614960907', 52, 'M0 4AE', TRUE, 500.00, 316.15, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Harry', 'Wall', '1974-03-22', 'jeffreydavies@example.org', '+44(0)1144960249', 142, 'HU2 8YD', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Nigel', 'Perry', '1961-03-12', 'alexrobson@example.org', '0306 9990801', 142, 'W59 7EG', TRUE, 1500.00, 1061.10, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Owen', 'Robinson', '1989-02-06', 'katherinewilson@example.org', '03069990517', 102, 'G7 4XB', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jake', 'Mills', '1968-02-13', 'mabbott@example.net', '+44121 4960738', 105, 'GY63 7QG', TRUE, 500.00, 388.95, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('James', 'Watkins', '1993-09-12', 'frostzoe@example.net', '(029)2018112', 116, 'JE91 1QH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Declan', 'Thorpe', '1987-10-03', 'barnesdiane@example.net', '+44161 4960499', 89, 'SY6 7ZR', TRUE, 1500.00, 767.75, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Danielle', 'Lewis', '1970-04-10', 'qgriffiths@example.com', '+44161 4960320', 34, 'B1 0GR', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rachael', 'Davies', '1970-08-21', 'brenda91@example.org', '029 2018877', 15, 'M77 8PX', TRUE, 1500.00, 183.62, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Janice', 'Brown', '1962-05-24', 'hshaw@example.com', '+44151 4960567', 83, 'BD02 2US', TRUE, 750.00, 568.49, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Aaron', 'Webster', '1986-09-20', 'kmiller@example.net', '(0161)4960889', 73, 'LN82 6LU', TRUE, 750.00, 117.78, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marie', 'Coates', '2002-03-24', 'glen50@example.org', '+4420 74960025', 71, 'TS9 5RE', TRUE, 750.00, 368.66, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Anne', 'Ward', '1984-07-24', 'qparsons@example.org', '(0118) 496 0349', 44, 'E4 5GA', TRUE, 500.00, 263.49, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Shannon', 'Rose', '1991-08-10', 'apearce@example.com', '(0113)4960790', 87, 'IM9 5YE', TRUE, 250.00, 16.24, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Wendy', 'Spencer', '2006-03-08', 'tomhughes@example.net', '01314960294', 148, 'KY3 1XH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gerard', 'Pritchard', '1980-06-22', 'nroberts@example.net', '+44(0)1144960919', 147, 'FK1 6HQ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Martin', 'Riley', '1980-10-13', 'ann85@example.org', '+44(0)141 4960649', 8, 'W8C 8GY', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dawn', 'Dobson', '1992-01-16', 'kim89@example.com', '020 7946 0083', 140, 'LL2 2NS', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Victoria', 'Newton', '1964-08-17', 'amyphillips@example.com', '+44(0)28 9018 0249', 78, 'S31 3AJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dylan', 'Hall', '1998-05-04', 'coliver@example.org', '(0116) 4960420', 104, 'TQ4 0UA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('William', 'Taylor', '1965-12-15', 'mandy41@example.com', '+44(0)131 496 0162', 16, 'E98 8YW', TRUE, 1000.00, 332.50, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Tony', 'Hughes', '1966-05-21', 'graceblake@example.com', '0131 496 0963', 88, 'DN21 3LT', TRUE, 750.00, 516.89, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Michelle', 'Smith', '2000-05-10', 'joneskaren@example.net', '(0115) 4960586', 89, 'SL34 5UQ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Mohammad', 'Brown', '2001-06-20', 'graycheryl@example.org', '+44292018348', 95, 'HA51 7RA', TRUE, 750.00, 145.04, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lisa', 'Murray', '1977-08-19', 'george34@example.org', '(0909) 8790275', 116, 'KA0M 7US', TRUE, 500.00, 38.72, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brett', 'Edwards', '1967-01-28', 'ameliasmith@example.org', '+44131 496 0698', 99, 'HG7Y 0GT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jemma', 'Khan', '1987-07-05', 'teresarogers@example.net', '+44(0)114 496 0123', 41, 'G9S 5TU', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Aaron', 'Smith', '2007-01-10', 'lawrence31@example.com', '+44(0)131 4960266', 81, 'L0A 1TH', TRUE, 500.00, 199.31, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marcus', 'Harrison', '1971-09-23', 'alexanderanne@example.net', '+44118 496 0215', 128, 'E08 7UE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Francis', 'Edwards', '1973-03-18', 'gerard76@example.org', '01514960393', 24, 'SS3 2SF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Matthew', 'Harris', '1978-01-22', 'marianprice@example.org', '+44(0)131 4960971', 62, 'W2 6HR', TRUE, 1500.00, 423.47, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lindsey', 'Davison', '2000-11-18', 'liam18@example.org', '0114 4960537', 127, 'PL9 0LW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jasmine', 'Palmer', '1987-02-07', 'wayne80@example.net', '+44(0)116 496 0428', 3, 'HR72 5WS', TRUE, 1000.00, 107.15, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Patrick', 'Smith', '1981-07-24', 'robinsondawn@example.com', '+44(0)1632960564', 94, 'PO4 6GP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Abigail', 'Miller', '1970-07-15', 'jmanning@example.org', '+44(0)117 4960207', 103, 'CW7 1UB', TRUE, 1500.00, 674.18, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Angela', 'Evans', '1998-05-30', 'hmurphy@example.net', '(0909)8790215', 74, 'L4 2WL', TRUE, 1000.00, 403.40, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lynne', 'Ball', '2000-02-06', 'caroleturner@example.org', '01914960926', 72, 'L7 5AN', TRUE, 500.00, 390.03, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gail', 'Robinson', '1968-07-18', 'gpatel@example.com', '(0116) 496 0017', 87, 'SE7R 9AP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Samuel', 'Lynch', '1991-01-28', 'shirley23@example.org', '0808 1570450', 51, 'BS8W 1RL', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Antony', 'Smith', '1987-05-23', 'browngavin@example.org', '(0141) 496 0642', 12, 'M7 4ZF', TRUE, 500.00, 285.44, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sarah', 'King', '1985-04-01', 'wendywilliams@example.com', '0161 4960499', 133, 'CA65 6SD', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Simon', 'Lewis', '1991-10-14', 'eileenholmes@example.org', '+44161 496 0881', 132, 'LL6 7NF', TRUE, 750.00, 558.82, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Scott', 'Richardson', '1980-09-07', 'zoerowe@example.net', '0114 496 0810', 101, 'E8G 1TY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Howard', 'Evans', '2000-02-03', 'readandrew@example.org', '+44(0)1632 960 722', 130, 'BH16 5YT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Vanessa', 'Power', '1978-04-13', 'christian32@example.org', '+44(0)1632960941', 77, 'NN00 1AG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Abbie', 'Jones', '2007-04-27', 'vtaylor@example.net', '(01632)960749', 95, 'N6U 1FF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stephen', 'Bates', '1961-04-28', 'richardkelly@example.net', '0116 4960368', 107, 'E47 7SA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Connor', 'Thompson', '1970-08-13', 'erobson@example.org', '(0909) 8790793', 7, 'M96 5AE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Harriet', 'Baker', '1989-08-17', 'vbaker@example.net', '+442074960840', 149, 'JE78 3BW', TRUE, 250.00, 116.70, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jack', 'Oliver', '1981-09-26', 'phillipseileen@example.com', '+44(0)9098790717', 98, 'N7T 0GN', TRUE, 500.00, 12.63, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alex', 'Jones', '1990-01-21', 'kathleenlloyd@example.net', '01314960972', 29, 'SR6 5UG', TRUE, 250.00, 88.21, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brenda', 'Martin', '2007-03-31', 'kingcallum@example.org', '(0117) 496 0297', 106, 'S7 3HX', TRUE, 1000.00, 401.46, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Anthony', 'Watkins', '1984-08-28', 'susan22@example.net', '+441134960156', 121, 'L1 7LP', TRUE, 500.00, 207.47, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Owen', 'Hilton', '1998-02-23', 'derek89@example.net', '01154960077', 123, 'E9 8BW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stuart', 'Thompson', '1968-04-11', 'lindafraser@example.com', '01632 960787', 45, 'WR1E 5FE', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Reece', 'Williams', '1988-07-14', 'smithelaine@example.com', '0121 4960821', 88, 'IG6 3FW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Emily', 'Greenwood', '1969-08-19', 'aali@example.com', '09098790850', 68, 'CT08 1PP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Joanne', 'Robinson', '1971-06-05', 'wlong@example.org', '029 2018290', 64, 'SP8M 6XN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Terry', 'Walker', '1960-10-12', 'debra92@example.net', '+44141 4960738', 58, 'W5U 3ND', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Alan', 'Powell', '1986-10-13', 'mariachambers@example.com', '+44117 496 0188', 54, 'NE5 0AX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jenna', 'Smith', '1980-12-04', 'hscott@example.net', '(0114) 496 0548', 90, 'CM0 7NY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Christopher', 'Price', '1976-04-23', 'bruceburns@example.net', '+443069990926', 147, 'L1F 5TE', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sean', 'Ellis', '1988-04-13', 'greendiane@example.org', '0161 4960371', 102, 'SK8 9XW', FALSE, 0.00, 0.00, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Hannah', 'Carr', '2000-01-02', 'cwoods@example.net', '(0161)4960622', 38, 'G7T 2WW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Terence', 'Garner', '1991-03-27', 'khiggins@example.net', '+44(0)131 4960196', 21, 'E5 0WF', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Terence', 'Hyde', '1985-09-22', 'billy70@example.org', '0116 496 0960', 66, 'WV4 2UA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Adrian', 'French', '1964-11-03', 'fletchermarion@example.com', '020 7946 0756', 138, 'WA92 8TT', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dorothy', 'Patterson', '1982-05-17', 'robertsrosie@example.net', '+441414960636', 70, 'NP0 4DG', TRUE, 250.00, 123.14, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lindsey', 'Jennings', '2003-02-14', 'chelsea18@example.org', '0117 4960989', 63, 'L7 1XG', TRUE, 1500.00, 270.81, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jack', 'White', '1974-04-01', 'dianabryant@example.net', '(0151)4960189', 26, 'JE9 7AP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amanda', 'Farrell', '1961-11-17', 'margaret41@example.org', '0115 4960824', 121, 'G41 4SG', TRUE, 500.00, 2.07, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Darren', 'Flynn', '1982-05-19', 'richardedwards@example.com', '(0141) 496 0152', 41, 'YO54 1BH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Shane', 'Mitchell', '2000-02-14', 'valeriebuckley@example.net', '01414960140', 122, 'LL8 1UA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Jane', 'Parkinson', '1961-07-05', 'andrea91@example.org', '(0306) 999 0824', 74, 'S7B 2QX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Leslie', 'Gill', '1996-10-27', 'jhunt@example.com', '+44(0)113 4960079', 16, 'SA2 0UL', TRUE, 1500.00, 278.66, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('June', 'Smith', '2006-07-08', 'owatkins@example.org', '(020)74960840', 10, 'E41 1FX', TRUE, 1000.00, 705.80, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Leonard', 'Shaw', '1974-08-04', 'jill54@example.net', '+44151 4960435', 10, 'DL7 0FA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Tina', 'Jones', '1960-11-23', 'amyhumphreys@example.net', '01632 960 768', 48, 'E8 7EQ', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Nicola', 'Mason', '1984-08-08', 'xwilliamson@example.net', '01134960175', 3, 'W03 4QH', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('George', 'Warren', '2002-10-16', 'ross37@example.com', '+44(0)113 496 0479', 28, 'B36 4YW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Valerie', 'Thompson', '1973-06-06', 'garyfox@example.net', '(0114) 4960249', 140, 'M30 8TA', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rachel', 'Hart', '2004-06-23', 'davisbrandon@example.com', '0909 879 0641', 35, 'NE7R 8BJ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Anthony', 'White', '1988-10-29', 'zsaunders@example.org', '0131 4960190', 29, 'DT6B 3GP', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Graeme', 'Collins', '2002-10-17', 'dayann@example.org', '+4420 74960543', 118, 'W3 0PW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Frank', 'Curtis', '2001-01-26', 'omiller@example.com', '(020) 74960110', 4, 'S5 2BT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('William', 'Atkins', '2002-11-08', 'rcollins@example.org', '+44(0)1914960046', 146, 'CB96 9ZA', TRUE, 500.00, 244.38, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sandra', 'Cooper', '1989-05-17', 'cookfrances@example.org', '+441514960859', 104, 'E10 9HY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Malcolm', 'Todd', '1977-09-07', 'emily79@example.com', '+44(0)1164960320', 23, 'G4 8QN', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Carole', 'Young', '1970-02-25', 'paulineherbert@example.com', '01214960508', 48, 'G0D 6QH', TRUE, 1000.00, 258.88, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Marc', 'Hart', '1973-12-09', 'cookdorothy@example.com', '+44(0)29 2018 0795', 67, 'N9E 5GE', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Sandra', 'Hawkins', '1963-02-11', 'alloyd@example.net', '+44(0)117 496 0379', 69, 'L75 3RG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Thomas', 'Evans', '1965-04-05', 'robert81@example.org', '01214960739', 147, 'BH0 3NG', TRUE, 750.00, 392.21, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gerald', 'Young', '1972-02-07', 'andrea32@example.org', '(0113)4960241', 16, 'G6 5HN', TRUE, 1000.00, 245.45, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Caroline', 'Smith', '1985-07-31', 'kerrystewart@example.net', '+44(0)909 879 0611', 129, 'G33 5PZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Anne', 'Stewart', '1976-11-19', 'millerkate@example.org', '09098790842', 76, 'EH0 2WY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Wendy', 'Kelly', '1965-10-13', 'njames@example.org', '+44116 496 0868', 57, 'ME8 2PQ', TRUE, 1000.00, 122.55, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kerry', 'Garner', '1993-11-30', 'zphillips@example.net', '+44(0)306 9990903', 96, 'L73 3NS', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Gemma', 'Bradshaw', '1985-09-13', 'georgina12@example.org', '(0121) 496 0785', 121, 'B78 6TT', TRUE, 500.00, 272.14, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ann', 'Hanson', '1994-02-06', 'abdul60@example.org', '(0151)4960341', 21, 'ZE1 8WX', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Carly', 'Ferguson', '1979-01-20', 'nigeliqbal@example.com', '+44(0)113 496 0835', 93, 'N44 3ZF', TRUE, 1500.00, 134.65, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Paige', 'Walker', '1960-10-28', 'lawrence56@example.com', '+44808 157 0907', 130, 'ML2P 3HU', TRUE, 1500.00, 643.99, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Donald', 'Lewis', '1997-11-06', 'dwood@example.com', '+44(0)306 9990153', 134, 'TD63 7XA', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Karen', 'Khan', '1968-12-23', 'john75@example.com', '+44(0)117 496 0666', 53, 'NN4N 9BF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Carl', 'Stewart', '1982-09-19', 'nrobinson@example.com', '(0114) 4960863', 131, 'CF59 4DG', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Stuart', 'Davies', '1972-05-01', 'masonmandy@example.com', '+44113 496 0231', 117, 'GL33 8DT', TRUE, 1500.00, 498.51, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Kevin', 'Connolly', '1960-12-29', 'tobytaylor@example.com', '(0141) 4960212', 144, 'S7T 6HF', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Russell', 'Gordon', '2005-06-25', 'kwalsh@example.com', '+4420 7496 0387', 79, 'DH0 7DR', TRUE, 1000.00, 203.57, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rachael', 'Mann', '1996-01-11', 'shirley77@example.com', '(020) 7496 0014', 56, 'WS7N 6ZG', TRUE, 250.00, 84.74, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Elizabeth', 'Smith', '2002-04-12', 'qmurphy@example.org', '+44(0)29 2018916', 139, 'BH3E 8ND', TRUE, 250.00, 197.23, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Amelia', 'Wood', '1975-01-10', 'wali@example.net', '+44115 4960511', 74, 'N6H 4HW', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Samuel', 'Hall', '1965-03-23', 'vpalmer@example.com', '(0909) 879 0360', 35, 'M1 5TU', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Bethany', 'Townsend', '1997-07-25', 'jenniferdavidson@example.com', '+44(0)8081570220', 98, 'E2E 8RG', FALSE, 0.00, 0.00, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Martin', 'Davies', '1961-01-02', 'carl75@example.org', '+44117 4960083', 97, 'SN08 6NT', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lee', 'Anderson', '1963-07-22', 'pperkins@example.com', '0118 4960310', 139, 'BB05 1JE', TRUE, 750.00, 71.18, 'CLOSED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rosie', 'Thompson', '1971-08-11', 'sandersonraymond@example.com', '+44(0)121 4960839', 101, 'S61 3EQ', TRUE, 500.00, 333.93, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Brandon', 'Coleman', '1987-08-11', 'james63@example.com', '+441174960149', 77, 'BH1 6NZ', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Dawn', 'Robinson', '1967-03-04', 'tonyschofield@example.net', '+44(0)1214960625', 140, 'N71 0ZY', FALSE, 0.00, 0.00, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Lucy', 'Palmer', '2003-11-01', 'stephaniefox@example.org', '+44(0)1174960091', 59, 'EC6 9DB', TRUE, 1000.00, 276.93, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Ashley', 'Patel', '1980-06-05', 'derekpatel@example.net', '+44(0)113 496 0397', 29, 'WS5E 5BW', TRUE, 1000.00, 491.94, 'SUSPENDED');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Elizabeth', 'Miah', '1979-11-15', 'wilsonmohamed@example.com', '01184960380', 5, 'EH3W 8PG', TRUE, 500.00, 26.92, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Angela', 'Yates', '1964-08-22', 'mrees@example.org', '+4428 9018 0232', 115, 'G9 3WD', TRUE, 500.00, 296.22, 'ACTIVE');
INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES ('Rachel', 'Wood', '1981-06-09', 'joesmith@example.org', '+44(0)2074960344', 60, 'W3E 1QR', TRUE, 250.00, 28.03, 'CLOSED');

-- CHECKOUTS
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (1, 120, 'ABANDONED', '2025-08-24 03:16:28', '2025-10-28 06:58:02');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (2, 77, 'COMPLETED', '2025-04-27 09:13:07', '2025-09-03 19:11:09');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (3, 105, 'COMPLETED', '2025-08-22 19:01:41', '2026-03-01 15:42:31');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (4, 27, 'COMPLETED', '2025-09-05 04:52:08', '2025-09-20 06:45:42');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (5, 469, 'OPEN', '2025-10-14 08:35:12', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (6, 241, 'COMPLETED', '2025-08-17 19:19:04', '2025-08-28 18:41:00');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (7, 369, 'COMPLETED', '2025-06-02 20:16:49', '2025-11-15 15:00:38');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (8, 391, 'COMPLETED', '2025-07-06 15:37:23', '2025-11-01 00:30:48');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (9, 112, 'ABANDONED', '2025-06-10 12:57:52', '2025-08-27 13:52:08');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (10, 77, 'OPEN', '2026-03-27 10:45:31', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (11, 41, 'COMPLETED', '2025-10-05 03:51:09', '2026-01-05 01:16:20');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (12, 331, 'COMPLETED', '2025-12-03 05:57:58', '2026-02-03 19:27:01');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (13, 291, 'COMPLETED', '2026-01-16 23:30:53', '2026-03-22 00:49:56');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (14, 195, 'OPEN', '2026-01-12 01:24:35', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (15, 53, 'OPEN', '2025-03-31 02:20:13', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (16, 286, 'ABANDONED', '2025-07-29 03:32:54', '2025-08-22 04:21:27');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (17, 253, 'OPEN', '2025-05-25 15:24:05', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (18, 216, 'COMPLETED', '2026-02-10 09:44:34', '2026-03-28 04:17:20');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (19, 221, 'ABANDONED', '2025-11-30 12:45:25', '2026-01-11 10:00:55');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (20, 304, 'ABANDONED', '2025-09-10 12:05:42', '2026-03-13 08:42:15');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (21, 345, 'COMPLETED', '2025-05-07 05:46:35', '2025-06-27 01:51:33');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (22, 307, 'COMPLETED', '2025-10-03 19:22:30', '2025-11-29 07:54:48');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (23, 192, 'COMPLETED', '2025-07-01 23:37:39', '2025-12-03 00:37:29');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (24, 176, 'COMPLETED', '2025-12-01 00:28:04', '2026-02-25 10:52:09');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (25, 370, 'ABANDONED', '2025-08-20 02:23:29', '2025-08-24 14:32:01');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (26, 119, 'COMPLETED', '2025-08-30 09:08:32', '2026-03-26 16:54:32');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (27, 200, 'OPEN', '2025-12-11 05:07:30', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (28, 167, 'OPEN', '2025-04-14 15:31:59', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (29, 60, 'OPEN', '2025-07-25 04:29:14', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (30, 96, 'COMPLETED', '2025-04-13 17:04:39', '2025-06-25 18:03:03');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (31, 86, 'OPEN', '2025-05-19 08:19:32', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (32, 53, 'ABANDONED', '2025-07-13 01:40:46', '2026-03-15 22:47:02');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (33, 398, 'OPEN', '2025-08-24 14:41:13', NULL);
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (34, 144, 'ABANDONED', '2025-07-14 17:15:55', '2025-07-18 13:11:53');
INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES (35, 322, 'COMPLETED', '2025-10-30 16:38:43', '2026-02-23 03:45:40');

-- CHECKOUT ITEMS
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (1, 1, 21, 2, 4.96, 4.96, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (2, 1, 37, 1, 19.72, 19.72, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (3, 1, 39, 4, 6.45, 6.45, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (4, 1, 16, 4, 21.18, 21.18, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (5, 1, 20, 4, 17.62, 17.62, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (6, 2, 12, 2, 21.12, 21.12, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (7, 2, 35, 2, 55.15, 55.15, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (8, 2, 31, 1, 5.76, 5.76, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (9, 2, 16, 4, 21.18, 21.18, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (10, 3, 29, 3, 13.37, 13.37, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (11, 4, 39, 2, 6.45, 6.45, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (12, 4, 3, 2, 17.70, 17.70, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (13, 4, 5, 3, 17.33, 15.60, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (14, 4, 13, 1, 14.08, 14.08, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (15, 5, 14, 3, 21.34, 21.34, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (16, 5, 26, 4, 1.74, 1.74, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (17, 5, 16, 3, 21.18, 21.18, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (18, 5, 36, 3, 49.27, 49.27, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (19, 5, 21, 4, 4.96, 4.96, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (20, 6, 24, 4, 54.47, 54.47, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (21, 6, 21, 2, 4.96, 3.97, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (22, 7, 10, 2, 64.37, 64.37, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (23, 7, 13, 2, 14.08, 14.08, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (24, 7, 22, 3, 51.52, 51.52, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (25, 8, 30, 4, 37.41, 37.41, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (26, 8, 11, 1, 62.81, 62.81, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (27, 8, 23, 1, 74.71, 74.71, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (28, 8, 9, 2, 53.29, 53.29, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (29, 9, 24, 4, 54.47, 43.58, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (30, 9, 4, 1, 60.73, 60.73, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (31, 9, 40, 3, 18.99, 18.99, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (32, 9, 31, 4, 5.76, 5.18, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (33, 10, 40, 3, 18.99, 18.99, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (34, 10, 34, 3, 40.28, 40.28, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (35, 11, 30, 3, 37.41, 37.41, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (36, 11, 37, 1, 19.72, 19.72, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (37, 11, 16, 4, 21.18, 21.18, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (38, 11, 15, 2, 25.33, 25.33, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (39, 12, 7, 4, 35.27, 35.27, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (40, 12, 34, 1, 40.28, 40.28, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (41, 12, 3, 1, 17.70, 17.70, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (42, 12, 15, 1, 25.33, 25.33, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (43, 12, 14, 4, 21.34, 17.07, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (44, 13, 22, 3, 51.52, 46.37, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (45, 13, 25, 3, 48.61, 48.61, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (46, 13, 9, 3, 53.29, 53.29, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (47, 13, 6, 4, 27.88, 27.88, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (48, 13, 33, 4, 10.74, 10.74, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (49, 14, 19, 2, 56.41, 56.41, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (50, 14, 16, 2, 21.18, 21.18, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (51, 14, 5, 3, 17.33, 17.33, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (52, 14, 6, 1, 27.88, 23.70, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (53, 14, 18, 3, 20.97, 20.97, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (54, 15, 12, 4, 21.12, 21.12, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (55, 16, 27, 1, 38.29, 38.29, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (56, 16, 7, 4, 35.27, 29.98, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (57, 16, 2, 2, 3.45, 3.45, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (58, 16, 6, 2, 27.88, 27.88, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (59, 16, 23, 3, 74.71, 74.71, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (60, 17, 11, 4, 62.81, 62.81, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (61, 18, 5, 4, 17.33, 17.33, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (62, 18, 24, 3, 54.47, 54.47, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (63, 18, 17, 4, 49.67, 49.67, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (64, 18, 16, 4, 21.18, 21.18, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (65, 19, 9, 4, 53.29, 53.29, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (66, 19, 20, 2, 17.62, 17.62, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (67, 19, 21, 3, 4.96, 4.96, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (68, 19, 39, 4, 6.45, 5.48, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (69, 19, 13, 3, 14.08, 14.08, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (70, 20, 36, 4, 49.27, 49.27, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (71, 20, 2, 1, 3.45, 3.45, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (72, 21, 20, 3, 17.62, 17.62, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (73, 21, 16, 1, 21.18, 21.18, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (74, 22, 26, 3, 1.74, 1.57, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (75, 22, 35, 3, 55.15, 55.15, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (76, 22, 33, 4, 10.74, 10.74, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (77, 22, 27, 4, 38.29, 32.55, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (78, 22, 3, 2, 17.70, 17.70, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (79, 23, 38, 1, 18.41, 18.41, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (80, 23, 33, 1, 10.74, 10.74, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (81, 23, 10, 4, 64.37, 51.50, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (82, 23, 23, 3, 74.71, 74.71, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (83, 24, 34, 3, 40.28, 40.28, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (84, 24, 31, 1, 5.76, 5.76, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (85, 25, 21, 1, 4.96, 4.96, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (86, 25, 5, 1, 17.33, 17.33, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (87, 25, 20, 2, 17.62, 17.62, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (88, 25, 3, 4, 17.70, 17.70, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (89, 26, 12, 4, 21.12, 21.12, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (90, 26, 28, 4, 48.46, 48.46, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (91, 27, 14, 1, 21.34, 21.34, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (92, 27, 18, 2, 20.97, 20.97, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (93, 28, 8, 3, 23.05, 23.05, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (94, 28, 17, 4, 49.67, 42.22, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (95, 28, 32, 2, 37.22, 37.22, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (96, 28, 34, 1, 40.28, 36.25, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (97, 29, 10, 4, 64.37, 64.37, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (98, 29, 33, 2, 10.74, 10.74, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (99, 29, 25, 2, 48.61, 48.61, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (100, 30, 40, 4, 18.99, 16.14, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (101, 30, 4, 4, 60.73, 60.73, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (102, 30, 23, 4, 74.71, 74.71, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (103, 30, 1, 4, 3.84, 3.84, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (104, 31, 2, 2, 3.45, 3.45, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (105, 31, 15, 2, 25.33, 25.33, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (106, 31, 19, 4, 56.41, 56.41, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (107, 31, 3, 3, 17.70, 17.70, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (108, 31, 18, 2, 20.97, 20.97, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (109, 32, 20, 4, 17.62, 17.62, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (110, 32, 3, 3, 17.70, 17.70, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (111, 33, 38, 4, 18.41, 18.41, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (112, 33, 23, 2, 74.71, 74.71, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (113, 34, 11, 1, 62.81, 62.81, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (114, 34, 21, 1, 4.96, 4.96, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (115, 34, 19, 2, 56.41, 45.13, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (116, 34, 37, 2, 19.72, 19.72, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (117, 34, 18, 4, 20.97, 20.97, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (118, 35, 29, 3, 13.37, 13.37, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (119, 35, 5, 4, 17.33, 17.33, FALSE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (120, 35, 6, 3, 27.88, 27.88, TRUE);
INSERT INTO ca_checkout_items (checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES (121, 35, 26, 1, 1.74, 1.74, FALSE);

-- DISCOUNTS
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (1, 1, 120, 'EXT-77689', 'DEAL-YE62', 'REJECTED', 4.96, '2025-08-31 19:55:37');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (2, 2, 120, 'EXT-66149', 'DEAL-JU82', 'REJECTED', 19.72, '2025-10-31 08:54:38');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (3, 3, 120, 'EXT-46747', 'DEAL-JM46', 'PENDING', 6.45, '2026-02-26 21:04:06');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (4, 9, 77, 'EXT-27323', 'DEAL-GU00', 'REJECTED', 21.18, '2026-02-03 01:55:39');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (5, 10, 105, 'EXT-66656', 'DEAL-PL74', 'APPROVED', 13.37, '2025-09-19 10:58:49');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (6, 13, 27, 'EXT-16923', 'DEAL-XW64', 'PENDING', 17.33, '2026-01-18 13:51:27');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (7, 19, 469, 'EXT-75066', 'DEAL-Ec33', 'PENDING', 4.96, '2026-03-21 06:01:49');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (8, 20, 241, 'EXT-24972', 'DEAL-ML43', 'APPROVED', 54.47, '2025-10-19 11:55:49');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (9, 21, 241, 'EXT-01166', 'DEAL-Hm91', 'PENDING', 4.96, '2026-01-29 01:26:58');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (10, 25, 391, 'EXT-88694', 'DEAL-gO61', 'PENDING', 37.41, '2026-02-14 00:45:03');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (11, 26, 391, 'EXT-52436', 'DEAL-kF40', 'APPROVED', 62.81, '2025-07-07 06:20:11');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (12, 27, 391, 'EXT-11686', 'DEAL-kl46', 'PENDING', 74.71, '2025-11-29 03:37:37');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (13, 28, 391, 'EXT-22372', 'DEAL-CK81', 'APPROVED', 53.29, '2025-09-27 04:57:01');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (14, 29, 112, 'EXT-02346', 'DEAL-gO79', 'REJECTED', 54.47, '2025-08-14 01:22:20');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (15, 30, 112, 'EXT-14161', 'DEAL-vb41', 'REJECTED', 60.73, '2026-01-23 23:35:04');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (16, 31, 112, 'EXT-37710', 'DEAL-Wa04', 'PENDING', 18.99, '2026-02-23 22:13:03');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (17, 32, 112, 'EXT-90138', 'DEAL-MH06', 'PENDING', 5.76, '2025-09-21 18:44:01');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (18, 35, 41, 'EXT-59655', 'DEAL-px55', 'PENDING', 37.41, '2026-02-11 07:20:31');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (19, 36, 41, 'EXT-66905', 'DEAL-aD51', 'REJECTED', 19.72, '2026-03-23 04:52:11');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (20, 37, 41, 'EXT-62091', 'DEAL-SW84', 'PENDING', 21.18, '2026-03-12 10:16:08');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (21, 38, 41, 'EXT-35797', 'DEAL-Qm86', 'REJECTED', 25.33, '2025-10-05 18:26:06');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (22, 40, 331, 'EXT-05057', 'DEAL-Fz39', 'REJECTED', 40.28, '2025-12-19 01:10:27');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (23, 41, 331, 'EXT-56716', 'DEAL-mT49', 'REJECTED', 17.70, '2025-12-31 01:08:48');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (24, 42, 331, 'EXT-89802', 'DEAL-tR71', 'PENDING', 25.33, '2026-03-19 19:18:39');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (25, 43, 331, 'EXT-72717', 'DEAL-pn83', 'APPROVED', 17.07, '2026-01-05 08:14:29');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (26, 44, 291, 'EXT-11602', 'DEAL-Xr56', 'APPROVED', 46.37, '2026-02-07 09:01:41');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (27, 46, 291, 'EXT-47128', 'DEAL-YS71', 'REJECTED', 53.29, '2026-02-18 06:59:51');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (28, 47, 291, 'EXT-39915', 'DEAL-PP66', 'REJECTED', 27.88, '2026-03-12 12:50:11');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (29, 48, 291, 'EXT-63341', 'DEAL-hf41', 'PENDING', 10.74, '2026-02-19 00:19:34');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (30, 52, 195, 'EXT-93195', 'DEAL-yK25', 'REJECTED', 27.88, '2026-03-24 14:33:10');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (31, 56, 286, 'EXT-98366', 'DEAL-ZR55', 'APPROVED', 29.98, '2025-09-16 04:49:05');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (32, 57, 286, 'EXT-89931', 'DEAL-ID60', 'APPROVED', 3.45, '2025-11-28 20:11:39');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (33, 61, 216, 'EXT-43772', 'DEAL-jV94', 'APPROVED', 17.33, '2026-03-14 16:55:57');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (34, 62, 216, 'EXT-09548', 'DEAL-TK14', 'REJECTED', 54.47, '2026-03-05 14:58:57');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (35, 68, 221, 'EXT-74605', 'DEAL-UZ23', 'REJECTED', 6.45, '2026-01-13 05:40:02');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (36, 69, 221, 'EXT-02764', 'DEAL-Jz20', 'APPROVED', 14.08, '2026-02-04 01:12:07');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (37, 70, 304, 'EXT-56618', 'DEAL-Sm44', 'REJECTED', 49.27, '2026-02-10 10:19:13');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (38, 72, 345, 'EXT-59047', 'DEAL-iC29', 'REJECTED', 17.62, '2026-02-01 12:33:07');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (39, 74, 307, 'EXT-23330', 'DEAL-gR59', 'PENDING', 1.74, '2026-03-05 08:04:00');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (40, 75, 307, 'EXT-26620', 'DEAL-El15', 'APPROVED', 55.15, '2025-10-13 23:54:46');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (41, 77, 307, 'EXT-18596', 'DEAL-pc26', 'APPROVED', 32.55, '2025-10-26 21:02:05');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (42, 81, 192, 'EXT-74926', 'DEAL-Py17', 'APPROVED', 51.50, '2025-10-16 20:49:36');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (43, 85, 370, 'EXT-11117', 'DEAL-bL83', 'PENDING', 4.96, '2026-03-30 14:58:11');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (44, 86, 370, 'EXT-97419', 'DEAL-EP26', 'PENDING', 17.33, '2026-02-04 12:21:45');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (45, 87, 370, 'EXT-49215', 'DEAL-lz18', 'REJECTED', 17.62, '2025-08-27 18:26:27');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (46, 89, 119, 'EXT-87189', 'DEAL-WW81', 'APPROVED', 21.12, '2025-11-18 22:50:40');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (47, 91, 200, 'EXT-12920', 'DEAL-Zu87', 'PENDING', 21.34, '2026-01-04 02:33:27');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (48, 94, 167, 'EXT-29321', 'DEAL-Wc84', 'PENDING', 49.67, '2025-05-17 12:09:30');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (49, 96, 167, 'EXT-18458', 'DEAL-Qa26', 'REJECTED', 40.28, '2025-07-20 02:12:08');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (50, 97, 60, 'EXT-08487', 'DEAL-FS29', 'REJECTED', 64.37, '2025-11-23 17:15:45');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (51, 99, 60, 'EXT-85988', 'DEAL-Qc31', 'APPROVED', 48.61, '2025-10-25 06:25:21');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (52, 100, 96, 'EXT-24329', 'DEAL-Lw83', 'PENDING', 18.99, '2025-07-30 10:35:34');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (53, 106, 86, 'EXT-96184', 'DEAL-Pk46', 'REJECTED', 56.41, '2025-10-21 17:08:57');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (54, 107, 86, 'EXT-71462', 'DEAL-eO83', 'REJECTED', 17.70, '2026-02-27 21:21:02');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (55, 110, 53, 'EXT-35989', 'DEAL-ju26', 'APPROVED', 17.70, '2025-12-28 11:22:38');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (56, 111, 398, 'EXT-09314', 'DEAL-hR18', 'APPROVED', 18.41, '2026-03-25 13:51:16');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (57, 112, 398, 'EXT-61515', 'DEAL-jZ54', 'PENDING', 74.71, '2025-11-20 06:58:25');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (58, 113, 144, 'EXT-16361', 'DEAL-HU12', 'REJECTED', 62.81, '2025-11-10 18:30:51');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (59, 115, 144, 'EXT-97185', 'DEAL-Jr94', 'REJECTED', 56.41, '2026-03-07 15:16:03');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (60, 117, 144, 'EXT-10256', 'DEAL-ZV25', 'REJECTED', 20.97, '2026-02-06 04:54:07');
INSERT INTO discounts (discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES (61, 120, 322, 'EXT-67924', 'DEAL-Tj08', 'PENDING', 27.88, '2026-03-07 09:06:38');

-- SALES
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (1, 2, 77, '2025-09-03 19:11:09', 243.02, FALSE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (2, 3, 105, '2026-03-01 15:42:31', 40.11, FALSE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (3, 4, 27, '2025-09-20 06:45:42', 109.18, FALSE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (4, 6, 241, '2025-08-28 18:41:00', 225.82, TRUE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (5, 7, 369, '2025-11-15 15:00:38', 311.46, TRUE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (6, 8, 391, '2025-11-01 00:30:48', 393.74, FALSE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (7, 11, 41, '2026-01-05 01:16:20', 267.33, TRUE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (8, 12, 331, '2026-02-03 19:27:01', 292.67, FALSE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (9, 13, 291, '2026-03-22 00:49:56', 599.29, TRUE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (10, 18, 216, '2026-03-28 04:17:20', 516.13, FALSE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (11, 21, 345, '2025-06-27 01:51:33', 74.04, FALSE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (12, 22, 307, '2025-11-29 07:54:48', 378.72, FALSE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (13, 23, 192, '2025-12-03 00:37:29', 459.28, FALSE, 'ONLINE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (14, 24, 176, '2026-02-25 10:52:09', 126.60, FALSE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (15, 26, 119, '2026-03-26 16:54:32', 278.32, FALSE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (16, 30, 96, '2025-06-25 18:03:03', 621.68, TRUE, 'IN_STORE');
INSERT INTO ca_sales (sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES (17, 35, 322, '2026-02-23 03:45:40', 194.81, FALSE, 'ONLINE');

-- SALE ITEMS
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (1, 1, 12, 2, 21.12);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (2, 1, 35, 2, 55.15);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (3, 1, 31, 1, 5.76);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (4, 1, 16, 4, 21.18);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (5, 2, 29, 3, 13.37);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (6, 3, 39, 2, 6.45);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (7, 3, 3, 2, 17.70);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (8, 3, 5, 3, 15.60);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (9, 3, 13, 1, 14.08);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (10, 4, 24, 4, 54.47);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (11, 4, 21, 2, 3.97);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (12, 5, 10, 2, 64.37);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (13, 5, 13, 2, 14.08);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (14, 5, 22, 3, 51.52);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (15, 6, 30, 4, 37.41);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (16, 6, 11, 1, 62.81);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (17, 6, 23, 1, 74.71);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (18, 6, 9, 2, 53.29);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (19, 7, 30, 3, 37.41);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (20, 7, 37, 1, 19.72);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (21, 7, 16, 4, 21.18);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (22, 7, 15, 2, 25.33);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (23, 8, 7, 4, 35.27);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (24, 8, 34, 1, 40.28);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (25, 8, 3, 1, 17.70);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (26, 8, 15, 1, 25.33);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (27, 8, 14, 4, 17.07);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (28, 9, 22, 3, 46.37);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (29, 9, 25, 3, 48.61);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (30, 9, 9, 3, 53.29);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (31, 9, 6, 4, 27.88);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (32, 9, 33, 4, 10.74);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (33, 10, 5, 4, 17.33);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (34, 10, 24, 3, 54.47);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (35, 10, 17, 4, 49.67);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (36, 10, 16, 4, 21.18);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (37, 11, 20, 3, 17.62);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (38, 11, 16, 1, 21.18);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (39, 12, 26, 3, 1.57);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (40, 12, 35, 3, 55.15);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (41, 12, 33, 4, 10.74);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (42, 12, 27, 4, 32.55);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (43, 12, 3, 2, 17.70);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (44, 13, 38, 1, 18.41);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (45, 13, 33, 1, 10.74);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (46, 13, 10, 4, 51.50);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (47, 13, 23, 3, 74.71);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (48, 14, 34, 3, 40.28);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (49, 14, 31, 1, 5.76);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (50, 15, 12, 4, 21.12);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (51, 15, 28, 4, 48.46);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (52, 16, 40, 4, 16.14);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (53, 16, 4, 4, 60.73);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (54, 16, 23, 4, 74.71);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (55, 16, 1, 4, 3.84);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (56, 17, 29, 3, 13.37);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (57, 17, 5, 4, 17.33);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (58, 17, 6, 3, 27.88);
INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (59, 17, 26, 1, 1.74);

-- PAYMENTS
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (1, 77, 1, 'CARD', 243.02, '2025-10-22 21:01:27');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (2, 105, 2, 'CARD', 40.11, '2026-03-08 13:55:52');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (3, 27, 3, 'CASH', 109.18, '2025-12-02 20:06:02');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (4, 241, 4, 'BANK_TRANSFER', 225.82, '2025-12-10 14:45:05');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (5, 391, 6, 'CARD', 393.74, '2025-11-11 06:52:49');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (6, 41, 7, 'CARD', 267.33, '2026-03-16 11:37:17');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (7, 331, 8, 'CASH', 292.67, '2026-03-11 17:57:50');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (8, 216, 10, 'CARD', 516.13, '2026-03-30 07:48:27');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (9, 345, 11, 'CARD', 74.04, '2025-10-01 19:44:52');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (10, 307, 12, 'CARD', 378.72, '2026-03-27 12:40:29');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (11, 192, 13, 'BANK_TRANSFER', 459.28, '2026-02-22 05:46:54');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (12, 176, 14, 'CASH', 126.60, '2026-03-19 16:13:45');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (13, 119, 15, 'CARD', 278.32, '2026-03-27 19:34:31');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (14, 96, 16, 'CARD', 621.68, '2025-12-13 05:27:16');
INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES (15, 322, 17, 'CARD', 194.81, '2026-03-12 08:12:09');

-- SUPPLIER ORDERS
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1001', 'SA-78446', 'CREATED', '2025-10-18 14:59:11', NULL, '2026-03-07 03:17:03');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1002', 'SA-34146', 'DELIVERED', '2026-01-23 17:00:13', '2026-02-23 01:44:00', '2026-02-27 10:45:17');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1003', 'SA-13129', 'SHIPPED', '2025-04-21 17:48:24', '2025-05-24 14:11:49', '2026-03-09 07:16:31');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1004', 'SA-70682', 'SUBMITTED', '2025-10-02 17:24:35', '2026-01-07 09:21:00', '2026-02-26 09:24:49');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1005', 'SA-81609', 'CREATED', '2025-06-12 07:20:09', NULL, '2026-03-28 23:47:19');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1006', 'SA-68538', 'SUBMITTED', '2025-12-21 02:45:45', '2025-12-29 08:09:20', '2026-02-26 07:26:18');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1007', 'SA-83215', 'DELIVERED', '2026-02-19 10:33:03', '2026-02-25 21:52:42', '2026-03-22 20:21:50');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1008', 'SA-67625', 'CREATED', '2025-05-13 10:06:19', NULL, '2025-09-21 16:06:27');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1009', 'SA-38144', 'SHIPPED', '2025-10-04 01:44:27', '2025-11-30 01:45:35', '2026-01-20 11:35:16');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1010', 'SA-96348', 'SUBMITTED', '2026-02-14 03:01:46', '2026-03-29 11:56:12', '2026-03-29 13:13:35');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1011', 'SA-97050', 'CREATED', '2025-11-24 11:51:00', NULL, '2026-02-21 21:15:16');
INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES ('SO-1012', 'SA-51052', 'SUBMITTED', '2025-09-02 14:14:19', '2026-01-18 06:43:09', '2026-01-19 03:22:23');

-- SUPPLIER ORDER ITEMS
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (1, 'SO-1001', 8, 35);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (2, 'SO-1001', 28, 9);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (3, 'SO-1001', 9, 19);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (4, 'SO-1002', 7, 11);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (5, 'SO-1003', 20, 13);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (6, 'SO-1003', 9, 46);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (7, 'SO-1003', 25, 48);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (8, 'SO-1004', 34, 41);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (9, 'SO-1005', 29, 18);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (10, 'SO-1005', 23, 45);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (11, 'SO-1006', 40, 11);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (12, 'SO-1006', 29, 13);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (13, 'SO-1006', 14, 12);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (14, 'SO-1006', 6, 42);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (15, 'SO-1007', 28, 20);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (16, 'SO-1007', 21, 22);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (17, 'SO-1007', 9, 46);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (18, 'SO-1008', 36, 43);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (19, 'SO-1008', 39, 43);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (20, 'SO-1009', 20, 18);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (21, 'SO-1010', 19, 29);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (22, 'SO-1010', 4, 12);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (23, 'SO-1010', 16, 20);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (24, 'SO-1010', 32, 36);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (25, 'SO-1011', 24, 25);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (26, 'SO-1012', 37, 48);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (27, 'SO-1012', 27, 16);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (28, 'SO-1012', 24, 35);
INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (29, 'SO-1012', 35, 9);

-- SUPPLIER INVOICES
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1001', 'SO-1001', 1804.32, '2026-06-23', '2026-03-25 16:36:34');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1002', 'SO-1002', 310.38, '2026-05-30', '2026-01-31 10:11:36');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1003', 'SO-1003', 4010.94, '2026-04-26', '2025-11-22 22:57:00');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1004', 'SO-1004', 1321.18, '2026-06-04', '2026-02-11 03:24:21');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1005', 'SO-1005', 2882.09, '2026-03-30', '2026-03-16 15:47:24');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1006', 'SO-1006', 1447.79, '2026-05-12', '2026-01-22 20:10:48');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1007', 'SO-1007', 2823.73, '2026-05-03', '2026-02-21 21:51:40');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1008', 'SO-1008', 1916.77, '2026-06-26', '2026-02-01 03:25:58');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1009', 'SO-1009', 253.73, '2026-04-19', '2025-10-04 12:09:12');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1010', 'SO-1010', 3302.54, '2026-05-13', '2026-03-29 10:51:36');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1011', 'SO-1011', 1089.40, '2026-04-30', '2026-01-21 10:15:53');
INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES ('INV-1012', 'SO-1012', 3169.60, '2026-04-08', '2026-02-16 21:37:16');

-- DELIVERIES
INSERT INTO deliveries (delivery_id, order_id, received_at, notes) VALUES ('DEL-1001', 'SO-1002', '2026-03-12 11:33:15', 'Needs 30 minutes warning before delivery.');
INSERT INTO deliveries (delivery_id, order_id, received_at, notes) VALUES ('DEL-1002', 'SO-1003', '2025-06-21 04:23:13', 'Customer does not speak english fluently.');
INSERT INTO deliveries (delivery_id, order_id, received_at, notes) VALUES ('DEL-1003', 'SO-1007', '2026-03-04 12:31:11', 'Need ASAP.');
INSERT INTO deliveries (delivery_id, order_id, received_at, notes) VALUES ('DEL-1004', 'SO-1009', '2026-02-26 03:26:15', 'Deliver to back entrance at St Johns Street.');

-- DELIVERY ITEMS
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (1, 'DEL-1001', 7, 11);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (2, 'DEL-1002', 20, 13);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (3, 'DEL-1002', 9, 46);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (4, 'DEL-1002', 25, 46);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (5, 'DEL-1003', 28, 19);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (6, 'DEL-1003', 21, 22);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (7, 'DEL-1003', 9, 46);
INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES (8, 'DEL-1004', 20, 15);

-- ONLINE ORDERS
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1001', 'PU-65023', '2025-10-02 14:02:43', FALSE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1002', 'PU-41678', '2025-10-08 21:43:02', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1003', 'PU-25686', '2025-05-20 11:35:38', FALSE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1004', 'PU-11022', '2025-08-11 02:07:42', FALSE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1005', 'PU-80305', '2025-09-13 07:27:39', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1006', 'PU-90674', '2025-07-18 01:12:17', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1007', 'PU-71639', '2025-05-28 16:03:20', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1008', 'PU-82341', '2026-03-01 01:18:39', FALSE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1009', 'PU-43637', '2025-12-29 19:23:07', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1010', 'PU-18923', '2026-02-25 10:40:34', FALSE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1011', 'PU-92312', '2025-09-02 06:55:21', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1012', 'PU-04326', '2025-04-06 07:18:29', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1013', 'PU-93106', '2025-09-04 14:58:38', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1014', 'PU-84335', '2025-09-11 22:00:26', TRUE);
INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES ('ONL-1015', 'PU-70860', '2025-07-26 14:52:50', FALSE);

-- ONLINE ORDER ITEMS
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (1, 'ONL-1001', 28, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (2, 'ONL-1001', 26, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (3, 'ONL-1001', 6, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (4, 'ONL-1001', 35, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (5, 'ONL-1002', 6, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (6, 'ONL-1002', 33, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (7, 'ONL-1002', 14, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (8, 'ONL-1003', 20, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (9, 'ONL-1004', 4, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (10, 'ONL-1004', 16, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (11, 'ONL-1005', 40, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (12, 'ONL-1005', 39, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (13, 'ONL-1005', 4, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (14, 'ONL-1005', 20, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (15, 'ONL-1006', 1, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (16, 'ONL-1007', 11, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (17, 'ONL-1008', 11, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (18, 'ONL-1008', 24, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (19, 'ONL-1008', 9, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (20, 'ONL-1009', 22, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (21, 'ONL-1010', 17, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (22, 'ONL-1011', 30, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (23, 'ONL-1011', 33, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (24, 'ONL-1011', 24, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (25, 'ONL-1011', 4, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (26, 'ONL-1012', 7, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (27, 'ONL-1012', 37, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (28, 'ONL-1012', 8, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (29, 'ONL-1013', 1, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (30, 'ONL-1014', 24, 1);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (31, 'ONL-1014', 25, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (32, 'ONL-1014', 10, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (33, 'ONL-1014', 12, 3);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (34, 'ONL-1015', 21, 2);
INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (35, 'ONL-1015', 16, 3);

-- STATEMENTS
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (1, 164, '2025-05-10', '2025-08-22', '2025-08-18 15:28:04');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (2, 139, '2025-07-15', '2025-11-28', '2025-12-31 19:09:03');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (3, 423, '2025-09-07', '2025-12-11', '2025-08-01 15:49:32');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (4, 40, '2025-04-16', '2025-06-25', '2025-04-15 07:48:24');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (5, 293, '2025-03-29', '2025-04-18', '2025-12-11 22:21:11');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (6, 191, '2026-01-12', '2026-02-12', '2025-06-20 18:27:59');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (7, 62, '2025-07-17', '2026-01-16', '2025-07-17 05:58:00');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (8, 258, '2025-11-19', '2025-12-08', '2025-09-13 19:02:30');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (9, 345, '2025-06-08', '2025-09-13', '2025-10-07 05:48:47');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (10, 462, '2025-08-17', '2025-12-24', '2025-07-26 15:30:09');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (11, 27, '2025-05-11', '2025-06-17', '2025-12-15 05:44:07');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (12, 92, '2025-04-03', '2025-12-24', '2025-10-30 17:32:42');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (13, 115, '2026-01-22', '2026-02-03', '2025-08-06 01:48:34');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (14, 412, '2025-08-16', '2026-01-03', '2026-01-12 23:19:14');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (15, 265, '2026-01-25', '2026-03-23', '2025-10-21 20:02:39');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (16, 24, '2025-11-18', '2026-01-29', '2025-06-30 23:21:50');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (17, 489, '2025-12-06', '2026-01-28', '2025-06-20 00:20:41');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (18, 206, '2025-11-10', '2026-01-23', '2025-05-03 07:44:45');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (19, 36, '2025-05-09', '2025-06-28', '2025-11-29 22:36:15');
INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES (20, 450, '2026-01-11', '2026-03-10', '2025-05-16 04:28:34');

-- PAYMENT REMINDERS
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (1, 239, 'SMS', '2025-04-15 09:12:11', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (2, 168, 'EMAIL', '2025-11-13 05:50:29', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (3, 234, 'EMAIL', '2026-03-19 16:47:48', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (4, 103, 'SMS', '2026-03-08 18:33:19', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (5, 402, 'SMS', '2025-12-09 13:43:28', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (6, 319, 'EMAIL', '2026-02-10 21:29:52', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (7, 189, 'LETTER', '2025-06-12 09:39:44', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (8, 396, 'EMAIL', '2025-06-13 08:54:25', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (9, 462, 'LETTER', '2025-12-29 02:36:00', 'GENERATED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (10, 78, 'EMAIL', '2025-09-19 13:34:05', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (11, 13, 'EMAIL', '2026-03-24 20:59:01', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (12, 178, 'LETTER', '2025-05-07 18:03:35', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (13, 450, 'EMAIL', '2025-04-28 12:37:15', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (14, 1, 'LETTER', '2025-10-28 17:10:41', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (15, 435, 'LETTER', '2025-11-25 20:17:14', 'FAILED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (16, 158, 'EMAIL', '2025-08-10 14:43:59', 'GENERATED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (17, 272, 'EMAIL', '2025-07-25 12:39:22', 'SENT');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (18, 252, 'EMAIL', '2026-01-06 03:27:02', 'GENERATED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (19, 365, 'SMS', '2025-09-30 14:32:34', 'GENERATED');
INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES (20, 23, 'EMAIL', '2026-01-19 23:36:53', 'FAILED');

-- STOCK MOVEMENTS
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (1, 1, 51, 'INITIAL_STOCK', 'INIT-1', '2024-06-16 15:42:02');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (2, 2, 183, 'INITIAL_STOCK', 'INIT-2', '2024-10-23 10:02:57');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (3, 3, 66, 'INITIAL_STOCK', 'INIT-3', '2025-01-04 02:59:27');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (4, 4, 104, 'INITIAL_STOCK', 'INIT-4', '2024-05-28 21:15:45');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (5, 5, 15, 'INITIAL_STOCK', 'INIT-5', '2024-04-16 05:16:53');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (6, 6, 147, 'INITIAL_STOCK', 'INIT-6', '2024-05-18 20:24:45');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (7, 7, 256, 'INITIAL_STOCK', 'INIT-7', '2024-06-12 15:46:07');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (8, 8, 158, 'INITIAL_STOCK', 'INIT-8', '2024-09-08 14:57:21');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (9, 9, 256, 'INITIAL_STOCK', 'INIT-9', '2024-10-29 23:55:26');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (10, 10, 91, 'INITIAL_STOCK', 'INIT-10', '2024-12-31 13:33:15');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (11, 11, 93, 'INITIAL_STOCK', 'INIT-11', '2024-07-06 06:38:26');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (12, 12, 159, 'INITIAL_STOCK', 'INIT-12', '2025-03-11 11:07:20');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (13, 13, 59, 'INITIAL_STOCK', 'INIT-13', '2025-03-05 19:52:01');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (14, 14, 172, 'INITIAL_STOCK', 'INIT-14', '2025-01-19 02:38:07');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (15, 15, 55, 'INITIAL_STOCK', 'INIT-15', '2025-02-24 15:33:14');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (16, 16, 220, 'INITIAL_STOCK', 'INIT-16', '2025-02-21 19:02:40');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (17, 17, 222, 'INITIAL_STOCK', 'INIT-17', '2025-03-17 09:03:34');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (18, 18, 190, 'INITIAL_STOCK', 'INIT-18', '2024-11-02 19:44:10');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (19, 19, 229, 'INITIAL_STOCK', 'INIT-19', '2024-08-12 02:22:17');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (20, 20, 155, 'INITIAL_STOCK', 'INIT-20', '2025-03-12 18:07:35');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (21, 21, 59, 'INITIAL_STOCK', 'INIT-21', '2024-08-19 08:24:42');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (22, 22, 10, 'INITIAL_STOCK', 'INIT-22', '2024-09-20 09:05:23');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (23, 23, 56, 'INITIAL_STOCK', 'INIT-23', '2024-11-29 19:41:47');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (24, 24, 219, 'INITIAL_STOCK', 'INIT-24', '2025-01-02 18:53:39');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (25, 25, 118, 'INITIAL_STOCK', 'INIT-25', '2024-05-14 19:26:58');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (26, 26, 220, 'INITIAL_STOCK', 'INIT-26', '2025-03-18 22:39:43');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (27, 27, 125, 'INITIAL_STOCK', 'INIT-27', '2024-09-15 13:55:09');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (28, 28, 65, 'INITIAL_STOCK', 'INIT-28', '2024-04-25 12:01:17');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (29, 29, 229, 'INITIAL_STOCK', 'INIT-29', '2024-10-03 17:08:48');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (30, 30, 230, 'INITIAL_STOCK', 'INIT-30', '2024-09-08 22:20:03');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (31, 31, 240, 'INITIAL_STOCK', 'INIT-31', '2024-10-19 14:45:18');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (32, 32, 250, 'INITIAL_STOCK', 'INIT-32', '2025-03-26 21:34:44');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (33, 33, 112, 'INITIAL_STOCK', 'INIT-33', '2024-10-11 21:20:09');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (34, 34, 104, 'INITIAL_STOCK', 'INIT-34', '2025-01-31 08:30:59');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (35, 35, 177, 'INITIAL_STOCK', 'INIT-35', '2024-04-07 16:49:16');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (36, 36, 230, 'INITIAL_STOCK', 'INIT-36', '2024-06-03 00:52:50');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (37, 37, 85, 'INITIAL_STOCK', 'INIT-37', '2024-11-17 21:26:57');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (38, 38, 0, 'INITIAL_STOCK', 'INIT-38', '2024-07-14 16:10:58');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (39, 39, 218, 'INITIAL_STOCK', 'INIT-39', '2024-12-25 18:42:18');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (40, 40, 120, 'INITIAL_STOCK', 'INIT-40', '2024-05-19 06:41:12');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (41, 27, 12, 'DAMAGE', 'REF-40903', '2026-01-12 02:39:30');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (42, 30, 13, 'ADJUSTMENT', 'REF-67881', '2025-06-02 17:26:02');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (43, 38, -7, 'RETURN', 'REF-78686', '2025-09-02 02:52:32');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (44, 26, -8, 'ADJUSTMENT', 'REF-94320', '2025-05-31 14:01:44');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (45, 28, 11, 'RETURN', 'REF-93908', '2025-09-23 07:42:36');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (46, 16, -1, 'DAMAGE', 'REF-88443', '2025-07-23 13:00:08');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (47, 21, 19, 'RESTOCK', 'REF-48123', '2025-04-17 03:49:53');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (48, 21, 0, 'RESTOCK', 'REF-83402', '2026-03-08 14:27:52');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (49, 18, -3, 'ADJUSTMENT', 'REF-42403', '2026-02-13 05:25:56');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (50, 13, -6, 'ADJUSTMENT', 'REF-38105', '2025-12-01 03:43:27');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (51, 10, -7, 'RETURN', 'REF-95518', '2025-07-10 23:42:24');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (52, 29, 4, 'DAMAGE', 'REF-26945', '2025-04-21 16:25:34');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (53, 27, -7, 'DAMAGE', 'REF-05342', '2025-07-07 20:39:58');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (54, 14, 4, 'DAMAGE', 'REF-08916', '2025-12-09 08:46:50');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (55, 30, -2, 'ADJUSTMENT', 'REF-49837', '2025-06-24 03:11:50');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (56, 6, -5, 'DAMAGE', 'REF-54396', '2025-05-29 21:22:34');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (57, 39, -9, 'RETURN', 'REF-73652', '2026-03-15 19:30:32');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (58, 21, -6, 'ADJUSTMENT', 'REF-71727', '2025-06-10 07:16:43');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (59, 16, 20, 'DAMAGE', 'REF-23972', '2025-12-06 22:25:44');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (60, 26, 6, 'ADJUSTMENT', 'REF-40422', '2026-02-10 22:20:14');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (61, 20, -2, 'RETURN', 'REF-69312', '2025-04-27 10:14:05');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (62, 2, 20, 'RESTOCK', 'REF-63761', '2026-01-05 17:43:20');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (63, 29, 7, 'RETURN', 'REF-82091', '2025-08-24 04:44:38');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (64, 7, 4, 'ADJUSTMENT', 'REF-60100', '2025-05-20 18:41:25');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (65, 9, -7, 'ADJUSTMENT', 'REF-31429', '2025-04-04 16:29:33');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (66, 4, 16, 'RETURN', 'REF-01851', '2025-06-17 00:28:00');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (67, 9, -4, 'RESTOCK', 'REF-27972', '2025-07-27 19:43:41');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (68, 24, 11, 'ADJUSTMENT', 'REF-57230', '2025-10-27 12:43:33');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (69, 38, 8, 'DAMAGE', 'REF-48100', '2025-05-09 09:00:02');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (70, 5, -10, 'ADJUSTMENT', 'REF-84186', '2025-05-24 12:41:26');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (71, 13, 18, 'RESTOCK', 'REF-03036', '2025-08-27 02:43:22');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (72, 9, -8, 'DAMAGE', 'REF-25436', '2025-12-22 03:49:05');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (73, 8, -9, 'RESTOCK', 'REF-17213', '2025-05-08 22:56:35');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (74, 4, -5, 'RESTOCK', 'REF-45195', '2025-05-15 09:48:12');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (75, 26, 5, 'ADJUSTMENT', 'REF-51092', '2025-06-07 14:24:16');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (76, 25, 11, 'RESTOCK', 'REF-68592', '2025-12-19 07:28:11');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (77, 12, 1, 'RETURN', 'REF-62494', '2025-08-12 17:52:56');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (78, 12, -2, 'DAMAGE', 'REF-14754', '2026-02-08 07:08:42');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (79, 29, 18, 'RETURN', 'REF-10225', '2025-05-26 20:06:13');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (80, 3, 9, 'RETURN', 'REF-67711', '2025-11-09 20:34:42');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (81, 19, 5, 'RESTOCK', 'REF-64215', '2025-05-18 23:24:42');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (82, 36, 5, 'ADJUSTMENT', 'REF-26557', '2025-09-11 01:05:37');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (83, 6, -2, 'RESTOCK', 'REF-76952', '2026-02-04 23:11:16');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (84, 9, 3, 'RETURN', 'REF-36687', '2025-10-25 16:10:50');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (85, 34, -3, 'ADJUSTMENT', 'REF-87883', '2025-08-26 19:40:42');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (86, 25, 15, 'DAMAGE', 'REF-19689', '2026-01-26 01:03:35');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (87, 31, 7, 'RESTOCK', 'REF-31350', '2025-06-17 09:23:46');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (88, 23, 19, 'DAMAGE', 'REF-05872', '2026-03-23 02:08:27');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (89, 25, -2, 'RETURN', 'REF-10552', '2025-07-22 21:28:13');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (90, 2, 0, 'RETURN', 'REF-72863', '2025-06-20 06:54:25');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (91, 2, 18, 'DAMAGE', 'REF-30212', '2025-08-24 00:52:55');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (92, 4, 15, 'RESTOCK', 'REF-06501', '2025-12-12 19:56:42');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (93, 34, 1, 'RETURN', 'REF-91792', '2025-04-11 04:02:38');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (94, 11, -7, 'RETURN', 'REF-25213', '2025-04-29 08:59:35');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (95, 16, -2, 'ADJUSTMENT', 'REF-09622', '2025-09-28 21:13:01');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (96, 15, 8, 'RESTOCK', 'REF-28476', '2026-01-05 01:24:56');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (97, 23, 19, 'RETURN', 'REF-57041', '2025-05-29 23:40:04');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (98, 12, -3, 'DAMAGE', 'REF-00928', '2025-05-31 17:15:05');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (99, 23, 19, 'ADJUSTMENT', 'REF-06678', '2025-12-31 17:29:02');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (100, 23, 20, 'RETURN', 'REF-49843', '2025-09-10 23:35:07');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (101, 37, 20, 'RETURN', 'REF-24186', '2025-05-18 01:01:11');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (102, 32, 7, 'DAMAGE', 'REF-36903', '2025-08-29 19:06:33');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (103, 12, 5, 'ADJUSTMENT', 'REF-28917', '2025-10-01 20:32:04');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (104, 6, -9, 'RETURN', 'REF-56620', '2026-02-05 10:21:25');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (105, 39, -3, 'ADJUSTMENT', 'REF-56341', '2025-05-09 23:46:17');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (106, 34, 5, 'ADJUSTMENT', 'REF-15950', '2025-07-01 11:16:23');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (107, 22, 19, 'RETURN', 'REF-42811', '2025-06-20 17:50:10');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (108, 9, 0, 'RETURN', 'REF-90438', '2025-06-16 18:54:51');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (109, 21, -9, 'ADJUSTMENT', 'REF-03419', '2025-11-04 18:58:49');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (110, 10, 8, 'RETURN', 'REF-09700', '2025-07-30 14:47:36');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (111, 8, 17, 'DAMAGE', 'REF-14054', '2025-09-01 01:35:33');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (112, 5, 1, 'RESTOCK', 'REF-83565', '2025-05-19 17:52:38');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (113, 38, -7, 'DAMAGE', 'REF-15681', '2025-10-11 11:19:20');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (114, 20, 0, 'RETURN', 'REF-20967', '2025-11-13 03:56:49');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (115, 11, 13, 'RESTOCK', 'REF-04227', '2025-04-30 00:43:20');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (116, 32, 10, 'DAMAGE', 'REF-13322', '2025-10-11 06:07:44');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (117, 12, 12, 'DAMAGE', 'REF-89857', '2026-01-29 10:42:08');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (118, 15, 11, 'RETURN', 'REF-25459', '2026-02-25 20:44:54');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (119, 25, -1, 'DAMAGE', 'REF-60633', '2025-11-22 11:54:49');
INSERT INTO stock_movements (movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES (120, 9, -5, 'ADJUSTMENT', 'REF-91297', '2025-05-07 06:34:57');

