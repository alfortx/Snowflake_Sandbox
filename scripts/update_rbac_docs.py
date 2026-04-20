#!/usr/bin/env python3
"""
RBAC継承ツリーを Terraform コードから自動生成するスクリプト。
terraform/modules/rbac/ を解析して docs/rbac_tree.md を更新する。

使い方:
    python3 scripts/update_rbac_docs.py
"""

import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

import hcl2

REPO_ROOT = Path(__file__).resolve().parent.parent
FUNCTIONAL_ROLES_TF = REPO_ROOT / "terraform/modules/rbac/functional_roles.tf"
MAIN_TF = REPO_ROOT / "terraform/modules/rbac/main.tf"
VARIABLES_TF = REPO_ROOT / "terraform/variables.tf"
RBAC_VARIABLES_TF = REPO_ROOT / "terraform/modules/rbac/variables.tf"
OUTPUT_FILE = REPO_ROOT / "docs/rbac_tree.md"

# 役割ロールの判定キーワード
ROLE_KEYWORDS = {
    "developer_role": "DEVELOPER_ROLE",
    "viewer_role": "VIEWER_ROLE",
}


# =============================================================================
# ユーティリティ
# =============================================================================

def strip_quotes(value: str) -> str:
    """余分なダブルクォートを除去する"""
    return value.strip('"').replace('\\"', '')


def resolve_vars(value: str, variables: dict) -> str:
    """${var.xxx} を実際のリソース名に置換する"""
    def replace(m):
        var_name = m.group(1)
        return infer_resource_name(var_name, variables)
    return re.sub(r'\$\{var\.([^}]+)\}', replace, value)


def clean_resource_name(value: str, variables: dict) -> str:
    """
    Terraform のリソース名文字列を人が読める形に変換する。
    例: "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\""
      → RAW_DB.COVID19
    """
    resolved = resolve_vars(value, variables)
    # エスケープされたクォートと余分な記号を除去
    cleaned = resolved.replace('\\"', '').replace('"', '').replace('\\', '')
    cleaned = cleaned.strip('. ')
    return cleaned


def extract_fr_role_name(ref: str) -> str:
    """
    ${snowflake_account_role.fr_xxx.name} → FR_XXX
    """
    m = re.search(r'snowflake_account_role\.(\w+)\.name', ref)
    if m:
        return m.group(1).upper()
    return ref


def extract_privileges(raw_list: list) -> list:
    """["\"USAGE\"", "\"SELECT\""] → ["USAGE", "SELECT"]"""
    return [p.strip('"') for p in raw_list]


# =============================================================================
# 変数のデフォルト値を読み込む
# =============================================================================

def load_variables() -> dict:
    """全 Terraform ファイルから変数のデフォルト値を収集する"""
    variables = {}
    for tf_file in REPO_ROOT.rglob("variables.tf"):
        if "venv" in str(tf_file):
            continue
        try:
            with open(tf_file) as f:
                data = hcl2.load(f)
            for var_block in data.get("variable", []):
                for var_name, var_def in var_block.items():
                    name = var_name.strip('"')
                    default = var_def.get("default")
                    if default is not None and name not in variables:
                        variables[name] = str(default).strip('"')
        except Exception:
            pass
    return variables



# モジュール間の追跡が必要な特殊変数のマッピング（変数名 → 対応する変数名）
VARIABLE_REDIRECT = {
    "semantic_model_stage_database": "cortex_db_name",
    "semantic_model_stage_schema":   "semantic_models_schema_name",
}


def infer_resource_name(var_name: str, variables: dict) -> str:
    """
    変数名からリソース名を推測する。
    デフォルト値がある場合はそれを使い、ない場合は変数名のパターンから変換。

    例:
        sandbox_wh_name -> SANDBOX_WH
        raw_db_name     -> RAW_DB
        work_schema_name -> WORK
        covid19_schema_name -> COVID19
    """
    # 特殊ケース：モジュール間の参照が必要な変数
    if var_name in VARIABLE_REDIRECT:
        actual_var = VARIABLE_REDIRECT[var_name]
        return infer_resource_name(actual_var, variables)
    if var_name in variables:
        return variables[var_name].strip('"')
    # _schema_name → スキーマ部分だけ大文字化
    if var_name.endswith("_schema_name"):
        return var_name[: -len("_schema_name")].upper()
    # _name → 末尾削除して大文字化
    if var_name.endswith("_name"):
        return var_name[: -len("_name")].upper()
    return var_name.upper()


# =============================================================================
# main.tf から役割ロール → FR ロールの継承関係を解析
# =============================================================================

def parse_inheritance(variables: dict) -> dict:
    """
    Returns:
        { "DEVELOPER_ROLE": ["FR_WH_SANDBOX_OPERATE", ...], "VIEWER_ROLE": [...] }
    """
    inheritance = defaultdict(list)

    with open(MAIN_TF) as f:
        data = hcl2.load(f)

    for res_block in data.get("resource", []):
        for res_type, resources in res_block.items():
            res_type_clean = res_type.strip('"')
            if res_type_clean != "snowflake_grant_account_role":
                continue
            for _, body in resources.items():
                role_ref = body.get("role_name", "")
                parent_ref = body.get("parent_role_name", "")

                fr_role = extract_fr_role_name(role_ref)
                parent_resolved = resolve_vars(parent_ref, variables)

                # SYSADMIN への継承はスキップ
                if "SYSADMIN" in parent_resolved.upper():
                    continue

                # 役割ロール名を判定
                parent_lower = parent_resolved.lower()
                matched_role = None
                for keyword, role_name in ROLE_KEYWORDS.items():
                    if keyword in parent_lower:
                        matched_role = role_name
                        break

                if matched_role:
                    inheritance[matched_role].append(fr_role)

    return dict(inheritance)


# =============================================================================
# functional_roles.tf から FR ロール → リソース権限を解析
# =============================================================================

def parse_fr_resources(variables: dict) -> dict:
    """
    Returns:
        {
          "FR_XXX": [
            {"resource": "SANDBOX_WH", "type": "WAREHOUSE", "privileges": ["USAGE"]},
            ...
          ]
        }
    """
    fr_resources = defaultdict(list)

    with open(FUNCTIONAL_ROLES_TF) as f:
        data = hcl2.load(f)

    for res_block in data.get("resource", []):
        for res_type, resources in res_block.items():
            res_type_clean = res_type.strip('"')

            # FR ロールへの権限付与
            if res_type_clean == "snowflake_grant_privileges_to_account_role":
                for _, body in resources.items():
                    fr_role = extract_fr_role_name(body.get("account_role_name", ""))
                    privileges = extract_privileges(body.get("privileges", []))

                    entry = None

                    # on_account_object（DB, WAREHOUSE など）
                    if "on_account_object" in body:
                        obj = body["on_account_object"][0]
                        obj_type = obj.get("object_type", "").strip('"')
                        obj_name = clean_resource_name(
                            resolve_vars(obj.get("object_name", ""), variables),
                            variables
                        )
                        entry = {"resource": obj_name, "type": obj_type, "privileges": privileges}

                    # on_schema（スキーマへの権限）
                    elif "on_schema" in body:
                        schema = body["on_schema"][0]
                        schema_name = clean_resource_name(
                            resolve_vars(schema.get("schema_name", ""), variables),
                            variables
                        )
                        entry = {"resource": schema_name, "type": "SCHEMA", "privileges": privileges}

                    # on_schema_object（テーブル、ステージ等）
                    elif "on_schema_object" in body:
                        obj_block = body["on_schema_object"][0]

                        if "future" in obj_block:
                            # future tables
                            future = obj_block["future"][0]
                            obj_type = future.get("object_type_plural", "TABLES").strip('"')
                            in_schema = clean_resource_name(
                                resolve_vars(future.get("in_schema", ""), variables),
                                variables
                            )
                            entry = {
                                "resource": f"{in_schema}.*",
                                "type": f"FUTURE {obj_type}",
                                "privileges": privileges
                            }
                        else:
                            obj_type = obj_block.get("object_type", "").strip('"')
                            obj_name = clean_resource_name(
                                resolve_vars(obj_block.get("object_name", ""), variables),
                                variables
                            )
                            entry = {"resource": obj_name, "type": obj_type, "privileges": privileges}

                    if entry:
                        fr_resources[fr_role].append(entry)

            # DB ロール継承（SNOWFLAKE.CORTEX_USER など）
            elif res_type_clean == "snowflake_grant_database_role":
                for _, body in resources.items():
                    parent_ref = body.get("parent_role_name", "")
                    db_role_raw = body.get("database_role_name", "")
                    # "\"SNOWFLAKE\".\"CORTEX_USER\"" → SNOWFLAKE.CORTEX_USER
                    db_role = db_role_raw.replace('\\"', '').replace('"', '').replace('\\', '').strip()
                    fr_role = extract_fr_role_name(parent_ref)
                    if fr_role and db_role:
                        fr_resources[fr_role].append({
                            "resource": db_role,
                            "type": "DATABASE ROLE",
                            "privileges": ["inherited"]
                        })

    return dict(fr_resources)


# =============================================================================
# Markdown 生成
# =============================================================================

TYPE_ICON = {
    "WAREHOUSE": "WH",
    "DATABASE": "DB",
    "SCHEMA": "SCHEMA",
    "TABLE": "TABLE",
    "STAGE": "STAGE",
    "FILE FORMAT": "FORMAT",
    "EXTERNAL TABLE": "EXT TABLE",
    "MATERIALIZED VIEW": "MV",
    "DATABASE ROLE": "DB ROLE",
}


def type_label(obj_type: str) -> str:
    return TYPE_ICON.get(obj_type, obj_type)


def build_markdown(inheritance: dict, fr_resources: dict) -> str:
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines = [
        "# RBAC 継承ツリー",
        "",
        "> **自動生成ファイル** — 手動編集不可。",
        f"> `terraform/modules/rbac/` の変更時に `scripts/update_rbac_docs.py` が自動更新します。",
        f"> 最終更新: {now}",
        "",
        "---",
        "",
    ]

    # 役割ロールの表示順
    role_order = ["DEVELOPER_ROLE", "VIEWER_ROLE"]
    all_roles = role_order + [r for r in inheritance if r not in role_order]

    for role in all_roles:
        fr_list = inheritance.get(role, [])
        if not fr_list:
            continue

        lines.append(f"## {role}")
        lines.append("")

        for fr_role in fr_list:
            lines.append(f"- **{fr_role}**")
            resources = fr_resources.get(fr_role, [])
            for res in resources:
                privs = ", ".join(res["privileges"])
                label = type_label(res["type"])
                future_mark = " `[future]`" if "FUTURE" in res["type"] else ""
                lines.append(f"  - `{res['resource']}` ({label}) ← {privs}{future_mark}")
            lines.append("")

    return "\n".join(lines)


# =============================================================================
# エントリポイント
# =============================================================================

def main():
    print("RBAC ドキュメントを更新中...")

    variables = load_variables()
    inheritance = parse_inheritance(variables)
    fr_resources = parse_fr_resources(variables)
    markdown = build_markdown(inheritance, fr_resources)

    OUTPUT_FILE.write_text(markdown, encoding="utf-8")
    print(f"  -> {OUTPUT_FILE} を更新しました")


if __name__ == "__main__":
    main()
