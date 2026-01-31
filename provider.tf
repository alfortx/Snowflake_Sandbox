terraform {
  required_version = ">= 1.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.92"
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
