# coding=utf-8
from faker import Faker
import random
from decimal import Decimal

fake = Faker("en_GB")
random.seed(42)
Faker.seed(42)

output_file = "/Users/ben/Desktop/CA_db_fake_data.sql"

# -----------------------------
# SETTINGS
# -----------------------------
NUM_ROLES = 4
NUM_USERS = 8
NUM_PRODUCTS = 40
NUM_CUSTOMERS = 500
NUM_CHECKOUTS = 35
NUM_SALES = 25
NUM_SUPPLIER_ORDERS = 12
NUM_ONLINE_ORDERS = 15
NUM_STATEMENTS = 20
NUM_REMINDERS = 20
NUM_STOCK_MOVEMENTS = 80

# -----------------------------
# HELPERS
# -----------------------------
def sql_string(value):
    if value is None:
        return "NULL"
    return "'" + str(value).replace("\\", "\\\\").replace("'", "''") + "'"

def sql_date(value):
    if value is None:
        return "NULL"
    return f"'{value.strftime('%Y-%m-%d')}'"

def sql_timestamp(value):
    if value is None:
        return "NULL"
    return f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'"

def sql_bool(value):
    return "TRUE" if value else "FALSE"

def money(min_val, max_val):
    return round(random.uniform(min_val, max_val), 2)

# -----------------------------
# IN-MEMORY STORAGE
# -----------------------------
roles = []
users = []
products = []
customers = []
checkouts = []
checkout_items = []
discounts = []
sales = []
sale_items = []
payments = []
supplier_orders = []
supplier_order_items = []
supplier_invoices = []
deliveries = []
delivery_items = []
online_orders = []
online_order_items = []
statements = []
reminders = []
stock_movements = []
stock_levels = {}

# -----------------------------
# GENERATE ROLES
# -----------------------------
role_names = ["Admin", "Pharmacist", "Cashier", "Manager"]
for i, role_name in enumerate(role_names, start=1):
    roles.append((i, role_name))

# -----------------------------
# GENERATE USERS
# -----------------------------
for user_id in range(1, NUM_USERS + 1):
    username = fake.unique.user_name()[:50]
    password_hash = fake.sha256()
    role_id = random.choice(roles)[0]
    created_at = fake.date_time_between(start_date="-2y", end_date="now")
    users.append((user_id, username, password_hash, role_id, created_at))

# -----------------------------
# GENERATE PRODUCTS + STOCK
# -----------------------------
product_words = [
    "Paracetamol", "Ibuprofen", "Vitamin C", "Cough Syrup", "Bandage",
    "Antiseptic Cream", "Thermometer", "Nasal Spray", "Allergy Relief",
    "Pain Relief Gel", "Multivitamins", "First Aid Kit", "Face Mask",
    "Hand Sanitiser", "Calcium Tablets", "Fish Oil", "Eye Drops",
    "Throat Lozenges", "Blood Pressure Monitor", "Plasters"
]

for product_id in range(1, NUM_PRODUCTS + 1):
    product_name = f"{random.choice(product_words)} {fake.random_uppercase_letter()}{random.randint(1, 999)}"
    price = money(1.50, 75.00)
    vat_rate = random.choice([0.00, 5.00, 20.00])
    description = fake.sentence(nb_words=10)
    products.append((product_id, product_name, price, vat_rate, description))

    quantity = random.randint(0, 250)
    low_stock_threshold = random.randint(5, 30)
    stock_levels[product_id] = quantity

# -----------------------------
# GENERATE CUSTOMERS
# -----------------------------
for _ in range(NUM_CUSTOMERS):
    firstname = fake.first_name()
    surname = fake.last_name()
    dob = fake.date_of_birth(minimum_age=18, maximum_age=65)
    email = fake.email()
    phone = fake.phone_number()
    house_number = random.randint(1, 150)
    postcode = fake.postcode()

    account_holder = random.choice([True, False])

    if account_holder:
        credit_limit = random.choice([250, 500, 750, 1000, 1500])
        outstanding_balance = round(random.uniform(0, credit_limit * 0.8), 2)
    else:
        credit_limit = 0.00
        outstanding_balance = 0.00

    account_status = random.choices(
        ['ACTIVE', 'SUSPENDED', 'CLOSED'],
        weights=[85, 10, 5]
    )[0]

    customers.append((
        firstname, surname, dob, email, phone, house_number, postcode,
        account_holder, credit_limit, outstanding_balance, account_status
    ))

# Customer IDs will be 1..NUM_CUSTOMERS because AUTO_INCREMENT starts there
customer_ids = list(range(1, NUM_CUSTOMERS + 1))

# -----------------------------
# GENERATE CHECKOUTS + ITEMS + DISCOUNTS
# -----------------------------
checkout_item_id_counter = 1
discount_id_counter = 1

for checkout_id in range(1, NUM_CHECKOUTS + 1):
    customer_id = random.choice(customer_ids + [None, None])
    status = random.choice(["OPEN", "COMPLETED", "ABANDONED"])
    created_at = fake.date_time_between(start_date="-1y", end_date="now")
    checked_out_at = None if status == "OPEN" else fake.date_time_between(start_date=created_at, end_date="now")
    checkouts.append((checkout_id, customer_id, status, created_at, checked_out_at))

    num_items = random.randint(1, 5)
    selected_products = random.sample(products, num_items)

    for product in selected_products:
        product_id = product[0]
        base_price = Decimal(str(product[2]))
        quantity = random.randint(1, 4)

        deal_checked = random.choice([True, False])
        final_price = float(base_price)

        if deal_checked and random.random() < 0.35:
            discount_factor = random.choice([0.90, 0.85, 0.80])
            final_price = round(float(base_price) * discount_factor, 2)

        checkout_items.append((
            checkout_item_id_counter,
            checkout_id,
            product_id,
            quantity,
            float(base_price),
            final_price,
            deal_checked
        ))

        if deal_checked:
            deal_status = random.choice(["APPROVED", "REJECTED", "PENDING"])
            checked_price = final_price if deal_status == "APPROVED" else float(base_price)
            discounts.append((
                discount_id_counter,
                checkout_item_id_counter,
                customer_id,
                fake.bothify(text="EXT-#####"),
                fake.bothify(text="DEAL-??##"),
                deal_status,
                checked_price,
                fake.date_time_between(start_date=created_at, end_date="now")
            ))
            discount_id_counter += 1

        checkout_item_id_counter += 1

# -----------------------------
# GENERATE SALES + SALE ITEMS + PAYMENTS
# only from COMPLETED checkouts
# -----------------------------
sale_id_counter = 1
sale_item_id_counter = 1
payment_id_counter = 1

completed_checkouts = [c for c in checkouts if c[2] == "COMPLETED"]

for checkout in completed_checkouts[:NUM_SALES]:
    checkout_id, customer_id, _, _, checked_out_at = checkout
    items_for_checkout = [i for i in checkout_items if i[1] == checkout_id]

    total_amount = round(sum(item[3] * item[5] for item in items_for_checkout), 2)
    payment_deferred = bool(customer_id and random.random() < 0.3)
    sale_source = random.choice(["IN_STORE", "ONLINE"])

    sales.append((
        sale_id_counter,
        checkout_id,
        customer_id,
        checked_out_at or fake.date_time_between(start_date="-1y", end_date="now"),
        total_amount,
        payment_deferred,
        sale_source
    ))

    for item in items_for_checkout:
        _, _, product_id, quantity, _, final_unit_price, _ = item
        sale_items.append((
            sale_item_id_counter,
            sale_id_counter,
            product_id,
            quantity,
            final_unit_price
        ))

        stock_levels[product_id] = max(0, stock_levels[product_id] - quantity)
        sale_item_id_counter += 1

    if not payment_deferred or random.random() < 0.7:
        payments.append((
            payment_id_counter,
            customer_id,
            sale_id_counter,
            random.choice(["CARD", "CASH", "BANK_TRANSFER"]),
            total_amount,
            fake.date_time_between(start_date=checked_out_at or "-1y", end_date="now")
        ))
        payment_id_counter += 1

    sale_id_counter += 1

# -----------------------------
# GENERATE SUPPLIER ORDERS + ITEMS + INVOICES
# -----------------------------
supplier_order_item_id_counter = 1

for i in range(1, NUM_SUPPLIER_ORDERS + 1):
    order_id = f"SO-{1000 + i}"
    sa_order_ref = fake.bothify(text="SA-#####")
    status = random.choice(["CREATED", "SUBMITTED", "SHIPPED", "DELIVERED"])
    created_at = fake.date_time_between(start_date="-1y", end_date="now")
    submitted_at = fake.date_time_between(start_date=created_at, end_date="now") if status in ["SUBMITTED", "SHIPPED", "DELIVERED"] else None
    last_status_at = fake.date_time_between(start_date=submitted_at or created_at, end_date="now")

    supplier_orders.append((order_id, sa_order_ref, status, created_at, submitted_at, last_status_at))

    num_items = random.randint(1, 4)
    selected_products = random.sample(products, num_items)
    total_invoice = 0

    for product in selected_products:
        product_id = product[0]
        quantity = random.randint(5, 50)
        supplier_order_items.append((
            supplier_order_item_id_counter,
            order_id,
            product_id,
            quantity
        ))
        total_invoice += quantity * float(product[2]) * 0.8
        supplier_order_item_id_counter += 1

    supplier_invoices.append((
        f"INV-{1000 + i}",
        order_id,
        round(total_invoice, 2),
        fake.date_between(start_date="today", end_date="+90d"),
        fake.date_time_between(start_date=created_at, end_date="now")
    ))

# -----------------------------
# GENERATE DELIVERIES + DELIVERY ITEMS
# -----------------------------
delivery_item_id_counter = 1
deliverable_orders = [o for o in supplier_orders if o[2] in ["SHIPPED", "DELIVERED"]]

for i, order in enumerate(deliverable_orders, start=1):
    delivery_id = f"DEL-{1000 + i}"
    order_id = order[0]
    received_at = fake.date_time_between(start_date=order[3], end_date="now")
    notes = fake.sentence(nb_words=6)
    deliveries.append((delivery_id, order_id, received_at, notes))

    items = [item for item in supplier_order_items if item[1] == order_id]
    for item in items:
        _, _, product_id, qty = item
        received_qty = max(1, qty - random.randint(0, 3))
        delivery_items.append((
            delivery_item_id_counter,
            delivery_id,
            product_id,
            received_qty
        ))
        stock_levels[product_id] += received_qty
        delivery_item_id_counter += 1

# -----------------------------
# GENERATE ONLINE ORDERS + ITEMS
# -----------------------------
online_order_item_id_counter = 1

for i in range(1, NUM_ONLINE_ORDERS + 1):
    online_order_id = f"ONL-{1000 + i}"
    pu_order_ref = fake.bothify(text="PU-#####")
    received_at = fake.date_time_between(start_date="-1y", end_date="now")
    processed = random.choice([True, False])

    online_orders.append((online_order_id, pu_order_ref, received_at, processed))

    num_items = random.randint(1, 4)
    selected_products = random.sample(products, num_items)

    for product in selected_products:
        online_order_items.append((
            online_order_item_id_counter,
            online_order_id,
            product[0],
            random.randint(1, 3)
        ))
        online_order_item_id_counter += 1

# -----------------------------
# GENERATE STATEMENTS + REMINDERS
# -----------------------------
for statement_id in range(1, NUM_STATEMENTS + 1):
    customer_id = random.choice(customer_ids)
    start_date = fake.date_between(start_date="-1y", end_date="-30d")
    end_date = fake.date_between(start_date=start_date, end_date="today")
    generated_at = fake.date_time_between(start_date="-1y", end_date="now")
    statements.append((statement_id, customer_id, start_date, end_date, generated_at))

for reminder_id in range(1, NUM_REMINDERS + 1):
    customer_id = random.choice(customer_ids)
    reminder_type = random.choice(["EMAIL", "SMS", "LETTER"])
    generated_at = fake.date_time_between(start_date="-1y", end_date="now")
    status = random.choice(["GENERATED", "SENT", "FAILED"])
    reminders.append((reminder_id, customer_id, reminder_type, generated_at, status))

# -----------------------------
# GENERATE FINAL STOCK TABLE + STOCK MOVEMENTS
# -----------------------------
movement_id_counter = 1

for product_id, quantity in stock_levels.items():
    # Initial stock movement
    stock_movements.append((
        movement_id_counter,
        product_id,
        quantity,
        "INITIAL_STOCK",
        f"INIT-{product_id}",
        fake.date_time_between(start_date="-2y", end_date="-1y")
    ))
    movement_id_counter += 1

# Extra random adjustments
for _ in range(NUM_STOCK_MOVEMENTS):
    product_id = random.choice(products)[0]
    change_amount = random.randint(-10, 20)
    movement_type = random.choice(["ADJUSTMENT", "RETURN", "DAMAGE", "RESTOCK"])
    reference_id = fake.bothify(text="REF-#####")
    created_at = fake.date_time_between(start_date="-1y", end_date="now")
    stock_movements.append((
        movement_id_counter,
        product_id,
        change_amount,
        movement_type,
        reference_id,
        created_at
    ))
    movement_id_counter += 1

# -----------------------------
# WRITE SQL FILE
# -----------------------------
with open(output_file, "w", encoding="utf-8") as f:
    f.write("-- ==========================================\n")
    f.write("-- FAKE DATA FOR CA_db\n")
    f.write("-- Generated using Python + Faker\n")
    f.write("-- ==========================================\n\n")
    f.write("USE CA_db;\n\n")

    # Roles
    f.write("-- ROLES\n")
    for row in roles:
        f.write(
            f"INSERT INTO ca_roles (role_id, role_name) VALUES "
            f"({row[0]}, {sql_string(row[1])});\n"
        )
    f.write("\n")

    # Users
    f.write("-- USERS\n")
    for row in users:
        f.write(
            "INSERT INTO ca_users (user_id, username, password_hash, role_id, created_at) VALUES "
            f"({row[0]}, {sql_string(row[1])}, {sql_string(row[2])}, {row[3]}, {sql_timestamp(row[4])});\n"
        )
    f.write("\n")

    # Products
    f.write("-- PRODUCTS\n")
    for row in products:
        f.write(
            "INSERT INTO ca_products (product_id, product_name, price, vat_rate, description) VALUES "
            f"({row[0]}, {sql_string(row[1])}, {row[2]:.2f}, {row[3]:.2f}, {sql_string(row[4])});\n"
        )
    f.write("\n")

    # Stock
    f.write("-- STOCK\n")
    for product_id, quantity in stock_levels.items():
        low_stock_threshold = random.randint(5, 30)
        f.write(
            "INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES "
            f"({product_id}, {quantity}, {low_stock_threshold});\n"
        )
    f.write("\n")

    # Customers
    f.write("-- CUSTOMERS\n")
    for row in customers:
        f.write(
            "INSERT INTO ca_customers "
            "(firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES "
            f"({sql_string(row[0])}, {sql_string(row[1])}, {sql_date(row[2])}, {sql_string(row[3])}, "
            f"{sql_string(row[4])}, {row[5]}, {sql_string(row[6])}, {sql_bool(row[7])}, "
            f"{row[8]:.2f}, {row[9]:.2f}, {sql_string(row[10])});\n"
        )
    f.write("\n")

    # Checkouts
    f.write("-- CHECKOUTS\n")
    for row in checkouts:
        f.write(
            "INSERT INTO ca_checkouts (checkout_id, customer_id, checkout_status, created_at, checked_out_at) VALUES "
            f"({row[0]}, {row[1] if row[1] is not None else 'NULL'}, {sql_string(row[2])}, "
            f"{sql_timestamp(row[3])}, {sql_timestamp(row[4])});\n"
        )
    f.write("\n")

    # Checkout items
    f.write("-- CHECKOUT ITEMS\n")
    for row in checkout_items:
        f.write(
            "INSERT INTO ca_checkout_items "
            "(checkout_item_id, checkout_id, product_id, quantity, base_unit_price, final_unit_price, deal_checked) VALUES "
            f"({row[0]}, {row[1]}, {row[2]}, {row[3]}, {row[4]:.2f}, {row[5]:.2f}, {sql_bool(row[6])});\n"
        )
    f.write("\n")

    # Discounts
    f.write("-- DISCOUNTS\n")
    for row in discounts:
        f.write(
            "INSERT INTO discounts "
            "(discount_check_id, checkout_item_id, customer_id, external_discount_ref, deal_code, deal_status, checked_price, checked_at) VALUES "
            f"({row[0]}, {row[1]}, {row[2] if row[2] is not None else 'NULL'}, {sql_string(row[3])}, "
            f"{sql_string(row[4])}, {sql_string(row[5])}, {row[6]:.2f}, {sql_timestamp(row[7])});\n"
        )
    f.write("\n")

    # Sales
    f.write("-- SALES\n")
    for row in sales:
        f.write(
            "INSERT INTO ca_sales "
            "(sale_id, checkout_id, customer_id, sale_date, total_amount, payment_deferred, sale_source) VALUES "
            f"({row[0]}, {row[1]}, {row[2] if row[2] is not None else 'NULL'}, {sql_timestamp(row[3])}, "
            f"{row[4]:.2f}, {sql_bool(row[5])}, {sql_string(row[6])});\n"
        )
    f.write("\n")

    # Sale items
    f.write("-- SALE ITEMS\n")
    for row in sale_items:
        f.write(
            "INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES "
            f"({row[0]}, {row[1]}, {row[2]}, {row[3]}, {row[4]:.2f});\n"
        )
    f.write("\n")

    # Payments
    f.write("-- PAYMENTS\n")
    for row in payments:
        f.write(
            "INSERT INTO ca_payments "
            "(payment_id, customer_id, sale_id, payment_method, amount, payment_date) VALUES "
            f"({row[0]}, {row[1] if row[1] is not None else 'NULL'}, {row[2]}, {sql_string(row[3])}, "
            f"{row[4]:.2f}, {sql_timestamp(row[5])});\n"
        )
    f.write("\n")

    # Supplier orders
    f.write("-- SUPPLIER ORDERS\n")
    for row in supplier_orders:
        f.write(
            "INSERT INTO supplier_orders "
            "(order_id, sa_order_ref, status, created_at, submitted_at, last_status_at) VALUES "
            f"({sql_string(row[0])}, {sql_string(row[1])}, {sql_string(row[2])}, {sql_timestamp(row[3])}, "
            f"{sql_timestamp(row[4])}, {sql_timestamp(row[5])});\n"
        )
    f.write("\n")

    # Supplier order items
    f.write("-- SUPPLIER ORDER ITEMS\n")
    for row in supplier_order_items:
        f.write(
            "INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES "
            f"({row[0]}, {sql_string(row[1])}, {row[2]}, {row[3]});\n"
        )
    f.write("\n")

    # Supplier invoices
    f.write("-- SUPPLIER INVOICES\n")
    for row in supplier_invoices:
        f.write(
            "INSERT INTO supplier_invoices (invoice_id, order_id, total_amount, due_date, received_at) VALUES "
            f"({sql_string(row[0])}, {sql_string(row[1])}, {row[2]:.2f}, {sql_date(row[3])}, {sql_timestamp(row[4])});\n"
        )
    f.write("\n")

    # Deliveries
    f.write("-- DELIVERIES\n")
    for row in deliveries:
        f.write(
            "INSERT INTO deliveries (delivery_id, order_id, received_at, notes) VALUES "
            f"({sql_string(row[0])}, {sql_string(row[1])}, {sql_timestamp(row[2])}, {sql_string(row[3])});\n"
        )
    f.write("\n")

    # Delivery items
    f.write("-- DELIVERY ITEMS\n")
    for row in delivery_items:
        f.write(
            "INSERT INTO delivery_items (delivery_item_id, delivery_id, product_id, quantity_received) VALUES "
            f"({row[0]}, {sql_string(row[1])}, {row[2]}, {row[3]});\n"
        )
    f.write("\n")

    # Online orders
    f.write("-- ONLINE ORDERS\n")
    for row in online_orders:
        f.write(
            "INSERT INTO ca_online_orders (online_order_id, pu_order_ref, received_at, processed) VALUES "
            f"({sql_string(row[0])}, {sql_string(row[1])}, {sql_timestamp(row[2])}, {sql_bool(row[3])});\n"
        )
    f.write("\n")

    # Online order items
    f.write("-- ONLINE ORDER ITEMS\n")
    for row in online_order_items:
        f.write(
            "INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES "
            f"({row[0]}, {sql_string(row[1])}, {row[2]}, {row[3]});\n"
        )
    f.write("\n")

    # Statements
    f.write("-- STATEMENTS\n")
    for row in statements:
        f.write(
            "INSERT INTO ca_statements (statement_id, customer_id, period_start, period_end, generated_at) VALUES "
            f"({row[0]}, {row[1]}, {sql_date(row[2])}, {sql_date(row[3])}, {sql_timestamp(row[4])});\n"
        )
    f.write("\n")

    # Reminders
    f.write("-- PAYMENT REMINDERS\n")
    for row in reminders:
        f.write(
            "INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, generated_at, status) VALUES "
            f"({row[0]}, {row[1]}, {sql_string(row[2])}, {sql_timestamp(row[3])}, {sql_string(row[4])});\n"
        )
    f.write("\n")

    # Stock movements
    f.write("-- STOCK MOVEMENTS\n")
    for row in stock_movements:
        f.write(
            "INSERT INTO stock_movements "
            "(movement_id, product_id, change_amount, movement_type, reference_id, created_at) VALUES "
            f"({row[0]}, {row[1]}, {row[2]}, {sql_string(row[3])}, {sql_string(row[4])}, {sql_timestamp(row[5])});\n"
        )
    f.write("\n")

print(f"Fake data SQL file generated: {output_file}")