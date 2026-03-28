# coding=utf-8
from faker import Faker
import random

fake = Faker('en_GB')

rows = []

for i in range(1000):
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

    row = f"('{firstname}','{surname}','{dob}','{email}','{phone}',{house_number},'{postcode}',{str(account_holder).upper()},{credit_limit},{outstanding_balance},'{account_status}')"
    rows.append(row)

sql = "INSERT INTO ca_customers (firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status)\nVALUES\n"
sql += ",\n".join(rows) + ";"

with open("customers_insert.sql", "w") as f:
    f.write(sql)

print("✅ Generated 100 realistic customers into customers_insert.sql")