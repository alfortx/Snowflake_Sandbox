"""
サンプルCSVデータ生成スクリプト
実行: python duckdb/data/generate_sample.py
"""

import csv
import random
from datetime import date, timedelta

# ---- 顧客マスタ (customers.csv) ----
customers = [
    {"customer_id": 1, "name": "山田 太郎", "region": "東京"},
    {"customer_id": 2, "name": "佐藤 花子", "region": "大阪"},
    {"customer_id": 3, "name": "鈴木 一郎", "region": "名古屋"},
    {"customer_id": 4, "name": "田中 美咲", "region": "福岡"},
    {"customer_id": 5, "name": "伊藤 健二", "region": "東京"},
]

with open("duckdb/data/customers.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["customer_id", "name", "region"])
    writer.writeheader()
    writer.writerows(customers)

print("customers.csv を生成しました")

# ---- 商品マスタ (products.csv) ----
products = [
    {"product_id": 101, "product_name": "ノートPC", "category": "電子機器", "unit_price": 120000},
    {"product_id": 102, "product_name": "マウス", "category": "電子機器", "unit_price": 3500},
    {"product_id": 103, "product_name": "キーボード", "category": "電子機器", "unit_price": 8000},
    {"product_id": 104, "product_name": "モニター", "category": "電子機器", "unit_price": 45000},
    {"product_id": 105, "product_name": "デスクチェア", "category": "家具", "unit_price": 35000},
    {"product_id": 106, "product_name": "デスク", "category": "家具", "unit_price": 28000},
]

with open("duckdb/data/products.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["product_id", "product_name", "category", "unit_price"])
    writer.writeheader()
    writer.writerows(products)

print("products.csv を生成しました")

# ---- 売上データ (sales.csv) ----
random.seed(42)
start_date = date(2024, 1, 1)
sales = []

for sale_id in range(1, 101):  # 100件
    sale_date = start_date + timedelta(days=random.randint(0, 364))
    customer_id = random.choice([c["customer_id"] for c in customers])
    product = random.choice(products)
    quantity = random.randint(1, 5)
    amount = product["unit_price"] * quantity

    sales.append({
        "sale_id": sale_id,
        "sale_date": sale_date.isoformat(),
        "customer_id": customer_id,
        "product_id": product["product_id"],
        "quantity": quantity,
        "amount": amount,
    })

with open("duckdb/data/sales.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["sale_id", "sale_date", "customer_id", "product_id", "quantity", "amount"])
    writer.writeheader()
    writer.writerows(sales)

print("sales.csv を生成しました（100件）")
print("\n完了！ duckdb/data/ を確認してください。")
