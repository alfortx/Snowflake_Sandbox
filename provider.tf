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

provider "snowflake" {
  # 環境変数から読み込み（推奨形式）:
  # SNOWFLAKE_ORGANIZATION_NAME (組織名)
  # SNOWFLAKE_ACCOUNT_NAME (アカウント名)
  # SNOWFLAKE_USER
  # SNOWFLAKE_PASSWORD
}
