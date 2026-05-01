DUCKDBの学習計画メモ
本PJで新たにDUCKDBの学習を始めたい。
前提
- リソースは /duckdb または　/docs/duckdb 配下に作成
- ローカルのみ。
- ユーザーがDUCK DBを理解できるようにClaudeがガイドしながら開発する

開発第１弾
- サンプルcsv生成してDuckDB化し、クエリしてDUCK DBの挙動、実体を学ぶ

開発第２弾
- CSV → Parquet 変換・直接クエリ・列指向の恩恵・複数ファイルワイルドカードクエリ
- Notebook: duckdb/notebooks/02_parquet.ipynb

開発第３弾（候補）
- A. DuckDB × S3（Parquetを直接クエリ）
- B. DuckDB vs Snowflake 同一SQLで比較
- C. 大量データ処理とメモリ効率