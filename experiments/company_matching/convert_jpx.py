"""
JPX 上場銘柄一覧 XLS → CSV 変換スクリプト

使い方:
  python3 convert_jpx.py

入力: ~/Downloads/data_j.xls
出力: ~/Downloads/data_j.csv  (UTF-8 BOMなし)

変換後は S3 の company-matching/jpx/ にアップロードしてください。
"""

import xlrd
import csv
import os

INPUT  = os.path.expanduser("~/Downloads/data_j.xls")
OUTPUT = os.path.expanduser("~/Downloads/data_j.csv")

wb = xlrd.open_workbook(INPUT)
sh = wb.sheet_by_index(0)

def cell_value(cell):
    """数値セルが整数値の場合(例: 1301.0)、intとして返す。それ以外はそのまま。"""
    if cell.ctype == xlrd.XL_CELL_NUMBER and cell.value == int(cell.value):
        return int(cell.value)
    return cell.value

with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    for row in range(sh.nrows):
        writer.writerow([cell_value(sh.cell(row, col)) for col in range(sh.ncols)])

print(f"変換完了: {sh.nrows}行 × {sh.ncols}列")
print(f"出力先: {OUTPUT}")
