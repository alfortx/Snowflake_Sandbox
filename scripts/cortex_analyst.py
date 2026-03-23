#!/usr/bin/env python3
"""
Cortex Analyst CLI
Claude Code から Snowflake Cortex Analyst REST API を呼び出すラッパー。

使い方:
  python scripts/cortex_analyst.py --question "質問文" --model COVID19_SEMANTIC --execute
"""

import argparse
import json
import os
import sys

import requests
import snowflake.connector
from dotenv import load_dotenv

# --- 設定 ---
DATABASE = "CORTEX_DB"
SCHEMA = "SEMANTIC_MODELS"
WAREHOUSE = "SANDBOX_WH"
ROLE = "DEVELOPER_ROLE"
MAX_ROWS = 100


def load_env() -> dict:
    """プロジェクトルートの .env を読み込んで接続情報を返す"""
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    load_dotenv(env_path)

    required = [
        "SNOWFLAKE_ORGANIZATION_NAME",
        "SNOWFLAKE_ACCOUNT_NAME",
        "SNOWFLAKE_USER",
        "SNOWFLAKE_PASSWORD",
    ]
    missing = [k for k in required if not os.getenv(k)]
    if missing:
        print(json.dumps({"error": f".env に未設定の変数があります: {missing}"}))
        sys.exit(1)

    return {
        "account": f"{os.getenv('SNOWFLAKE_ORGANIZATION_NAME')}-{os.getenv('SNOWFLAKE_ACCOUNT_NAME')}",
        "user": os.getenv("SNOWFLAKE_USER"),
        "password": os.getenv("SNOWFLAKE_PASSWORD"),
    }


def call_cortex_analyst(conn: snowflake.connector.SnowflakeConnection, account: str, question: str, model: str) -> dict:
    """Cortex Analyst REST API を呼び出して結果を返す。接続は呼び出し元が管理する"""
    url = f"https://{account}.snowflakecomputing.com/api/v2/cortex/analyst/message"
    headers = {
        "Authorization": f'Snowflake Token="{conn.rest.token}"',
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    body = {
        "messages": [{"role": "user", "content": [{"type": "text", "text": question}]}],
        "semantic_view": f"{DATABASE}.{SCHEMA}.{model}",
    }

    resp = requests.post(url, headers=headers, json=body, timeout=60)
    data = resp.json()

    # エラー判定: message が str ならAPIエラー
    if resp.status_code != 200 or isinstance(data.get("message"), str):
        msg = data.get("message", resp.text)
        return {"error": f"API エラー ({resp.status_code}): {msg}"}

    return data


def parse_response(api_result: dict) -> tuple[str, str]:
    """API レスポンスから SQL とテキスト説明を取り出す"""
    sql = ""
    text = ""
    for item in api_result.get("message", {}).get("content", []):
        if item.get("type") == "sql":
            sql = item.get("statement", "")
        elif item.get("type") == "text":
            text = item.get("text", "")
    return sql, text


def execute_sql(conn: snowflake.connector.SnowflakeConnection, sql: str) -> list:
    """SQL を既存の Snowflake 接続で実行してリストを返す"""
    cur = conn.cursor()
    cur.execute(sql)
    columns = [col[0] for col in cur.description]
    rows = cur.fetchmany(MAX_ROWS)
    return [dict(zip(columns, row)) for row in rows]


def main():
    parser = argparse.ArgumentParser(description="Cortex Analyst CLI")
    parser.add_argument("--question", required=True, help="自然言語の質問")
    parser.add_argument(
        "--model",
        default="COVID19_SEMANTIC",
        choices=["COVID19_SEMANTIC", "BUDGET_BOOK_SEMANTIC"],
        help="使用するセマンティックモデル名",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="生成された SQL を実行して結果も返す",
    )
    args = parser.parse_args()

    creds = load_env()

    # 接続を1本確立してすべての処理で共有する（閉じるとトークンが無効になるため）
    try:
        conn = snowflake.connector.connect(
            account=creds["account"],
            user=creds["user"],
            password=creds["password"],
            warehouse=WAREHOUSE,
            role=ROLE,
        )
    except Exception as e:
        print(json.dumps({"error": f"Snowflake 接続エラー: {e}"}))
        sys.exit(1)

    try:
        # 1. Cortex Analyst 呼び出し（接続を渡す）
        api_result = call_cortex_analyst(conn, creds["account"], args.question, args.model)
        if "error" in api_result:
            print(json.dumps(api_result))
            sys.exit(1)

        sql, analyst_text = parse_response(api_result)

        output = {
            "question": args.question,
            "model": args.model,
            "analyst_text": analyst_text,
            "sql": sql,
        }

        # 2. SQL 実行（--execute 指定時）
        if args.execute and sql:
            try:
                results = execute_sql(conn, sql)
                output["results"] = results
                output["row_count"] = len(results)
            except Exception as e:
                output["execute_error"] = str(e)

    finally:
        conn.close()

    print(json.dumps(output, ensure_ascii=False, indent=2, default=str))


if __name__ == "__main__":
    main()
