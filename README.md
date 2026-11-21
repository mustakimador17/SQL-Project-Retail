# 1. Create schema and tables
mysql -u root -p < MySQL_Ador_Retail_Analytics_Setup.sql

# 2. Load the seed data
mysql -u root -p < MySQL_Ador_Retail_Analytics_Seed_Data.sql
