terraform {
  required_version = ">= 1.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 将来的にS3バックエンドに移行する場合は、以下のコメントを外して設定
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "snowflake-sandbox/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# デフォルトプロバイダー（使用しない、エイリアスを明示的に使用）
provider "snowflake" {
  alias = "default"
  # 環境変数から読み込み（推奨形式）:
  # SNOWFLAKE_ORGANIZATION_NAME (組織名)
  # SNOWFLAKE_ACCOUNT_NAME (アカウント名)
  # SNOWFLAKE_USER
  # SNOWFLAKE_PASSWORD
}

# SYSADMIN用プロバイダー: Database, Schema, Warehouse作成
provider "snowflake" {
  alias = "sysadmin"
  role  = "SYSADMIN"
  # 環境変数から読み込み:
  # SNOWFLAKE_ORGANIZATION_NAME
  # SNOWFLAKE_ACCOUNT_NAME
  # SNOWFLAKE_USER
  # SNOWFLAKE_PASSWORD

  # v2.13.0 でプレビュー機能として扱われるリソースを明示的に有効化
  preview_features_enabled = [
    "snowflake_stage_resource",              # 外部ステージ
    "snowflake_file_format_resource",        # ファイルフォーマット
    "snowflake_table_resource",              # テーブル
    "snowflake_external_table_resource",     # 外部テーブル
    "snowflake_materialized_view_resource",  # マテリアライズドビュー
    "snowflake_semantic_view_resource",      # セマンティックビュー（Cortex Agent用）
  ]
}

# SECURITYADMIN用プロバイダー: Role作成と権限付与
provider "snowflake" {
  alias = "securityadmin"
  role  = "SECURITYADMIN"
  # 環境変数から読み込み:
  # SNOWFLAKE_ORGANIZATION_NAME
  # SNOWFLAKE_ACCOUNT_NAME
  # SNOWFLAKE_USER
  # SNOWFLAKE_PASSWORD
}

# USERADMIN用プロバイダー: User作成
provider "snowflake" {
  alias = "useradmin"
  role  = "USERADMIN"
  # 環境変数から読み込み:
  # SNOWFLAKE_ORGANIZATION_NAME
  # SNOWFLAKE_ACCOUNT_NAME
  # SNOWFLAKE_USER
  # SNOWFLAKE_PASSWORD
}

# ACCOUNTADMIN用プロバイダー: Storage Integration作成・Cortex DBロール付与・アカウントパラメータ管理
provider "snowflake" {
  alias = "accountadmin"
  role  = "ACCOUNTADMIN"
  # 環境変数から読み込み:
  # SNOWFLAKE_ORGANIZATION_NAME
  # SNOWFLAKE_ACCOUNT_NAME
  # SNOWFLAKE_USER
  # SNOWFLAKE_PASSWORD

  # v2.13.0 で snowflake_storage_integration の内部実装がプレビュー機能に移行したため明示的に有効化
  preview_features_enabled = [
    "snowflake_storage_integration_resource",
    "snowflake_current_account_resource",  # アカウントパラメータ管理
  ]
}

# =============================================================================
# AWS プロバイダー
# =============================================================================
# AWS プロバイダー: S3・IAM リソース管理
provider "aws" {
  region = "ap-northeast-1"
  # 環境変数から読み込み:
  # AWS_ACCESS_KEY_ID
  # AWS_SECRET_ACCESS_KEY
}
