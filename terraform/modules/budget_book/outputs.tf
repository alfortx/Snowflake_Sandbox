output "budget_book_schema_name" {
  value = snowflake_schema.budget_book.name
}

output "budget_book_transactions_name" {
  value = snowflake_table.budget_book_transactions.name
}

output "budget_book_stage_name" {
  value = snowflake_stage.budget_book_stage.name
}

output "budget_book_csv_format_name" {
  value = snowflake_file_format.budget_book_csv_format.name
}
