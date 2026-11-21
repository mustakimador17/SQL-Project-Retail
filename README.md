# Ador Retail Analytics | MySQL Business Intelligence Project

A comprehensive SQL analytics project designed to simulate a retail business environment, build a relational database, and solve practical business problems through structured data analysis.

The project demonstrates how SQL can transform interconnected retail data into meaningful business metrics, operational insights, and management-level reporting.

---

## Project Overview

**Project Name:** Ador Retail Analytics  
**Database Management System:** MySQL 8.0+  
**Language:** SQL  
**Project Type:** Retail Data Analytics & Business Intelligence  
**Focus:** Data Modeling, SQL Development, Business Analysis and Reporting

This project involves designing and implementing a retail database containing 16 interconnected relational tables, preparing structured seed data, and developing six analytical modules to investigate different aspects of retail business performance.

The primary objective is to demonstrate practical SQL capabilities while approaching analytical problems from a business and decision-making perspective.

## Business Objectives

The project addresses six major business areas:

### 1. Retail Sales Performance
- Monthly revenue and sales trends.
- Order volume and Average Order Value (AOV).
- Top-performing products.
- Regional sales comparisons.

### 2. Customer Analytics
- New versus returning customers.
- Customer acquisition and repeat purchase behavior.
- Customer Lifetime Value (LTV) proxy.
- RFM-style customer segmentation.
- Customer purchasing patterns.

### 3. Inventory & Supply Chain Analysis
- Inventory shortages across warehouses.
- Out-of-stock product identification.
- Slow-moving inventory analysis.
- Supplier performance comparisons.
- Product return-rate analysis.

### 4. Marketing Performance
- Campaign reach and engagement.
- Click-through rate (CTR).
- Click-to-purchase conversion.
- Campaign-attributed revenue.
- Return on Advertising Spend (ROAS).

### 5. Returns & Payment Reconciliation
- Order and payment status comparisons.
- Payment discrepancies.
- Refund exception identification.
- Return-rate analysis.
- Refund validation.

### 6. Executive KPI Reporting
- Monthly revenue reporting.
- Year-over-year revenue growth.
- Active and returning customer metrics.
- Top five products by revenue.
- Consolidated management-level performance indicators.

---

## Database Architecture

The database is designed around a relational structure with 16 interconnected tables.

| Business Area | Tables |
|---|---|
| Organization | departments, employees |
| Customer Management | customers, customer_addresses |
| Product Management | products, categories, suppliers |
| Sales | orders, order_items |
| Finance | payments, returns |
| Inventory & Logistics | warehouses, inventory, shipments |
| Marketing | marketing_campaigns, campaign_interactions |

### Database Design Features

- Primary key and foreign key relationships.
- Referential integrity.
- Unique constraints.
- CHECK constraints for data validation.
- Indexing for selected lookup and relationship columns.
- InnoDB storage engine.
- Structured table creation in foreign-key dependency order.

## SQL Skills Demonstrated

The project applies SQL techniques commonly used in data analytics and business intelligence.

**Database Development**
- CREATE DATABASE
- CREATE TABLE
- Primary and Foreign Keys
- Constraints
- Indexes
- Data Types

**Data Querying**
- SELECT and WHERE
- ORDER BY and GROUP BY
- Aggregate Functions
- INNER JOIN and LEFT JOIN
- Subqueries
- CASE WHEN
- NULL handling

**Advanced SQL**
- Common Table Expressions (CTEs)
- Multiple CTEs
- Window Functions
- ROW_NUMBER()
- RANK()
- LAG()
- Conditional Aggregation
- EXISTS and NOT EXISTS
- Date Functions
- Revenue and KPI Calculations

**Business Analytics**
- Revenue Analysis
- Customer Segmentation
- Cohort Analysis
- Inventory Analysis
- Marketing Attribution
- Payment Reconciliation
- Executive KPI Reporting

---

## Repository Structure

```text
SQL-Project-Retail/
│
├── MySQL_Ador_Retail_Analytics_Setup.sql
│
├── MySQL_Ador_Retail_Analytics_Seed_Data.sql
│
├── MySQL_Advanced_Business_Projects.sql
│
└── README.md
```

### File Descriptions

| File | Purpose |
|---|---|
| MySQL_Ador_Retail_Analytics_Setup.sql | Creates the database and relational tables. |
| MySQL_Ador_Retail_Analytics_Seed_Data.sql | Populates the database with seed data. |
| MySQL_Advanced_Business_Projects.sql | Contains six business-focused analytical modules. |
| README.md | Project documentation and execution instructions. |

---

## Installation & Execution

### Requirements

- MySQL Server 8.0+
- MySQL Workbench (recommended) or MySQL Command-Line Client.
- Access to the repository files.

### Step 1: Clone the Repository

```bash
git clone https://github.com/mustakimador17/SQL-Project-Retail.git
```

Navigate into the project directory:

```bash
cd SQL-Project-Retail
```

### Step 2: Create the Database and Tables

Execute:

```bash
mysql -u root -p < MySQL_Ador_Retail_Analytics_Setup.sql
```

### Step 3: Insert the Seed Data

Execute:

```bash
mysql -u root -p < MySQL_Ador_Retail_Analytics_Seed_Data.sql
```

### Step 4: Run the Analytical Queries

Execute:

```bash
mysql -u root -p < MySQL_Advanced_Business_Projects.sql
```

Alternatively, open each SQL file in MySQL Workbench and execute the scripts in the same order.

**Important Database Warning:** The setup script contains `DROP DATABASE IF EXISTS ador_retail`. It deletes and recreates the dedicated `ador_retail` database. Any existing data inside that database will be permanently lost. Do not execute this script against a database containing information you need to preserve.

---

## Analytical Methodology & Assumptions

To maintain consistency across the analytical modules, the project defines specific business metrics and assumptions.

- Net revenue is generally calculated using quantity, unit price and applicable discounts.
- Completed orders are used for the standard sales revenue calculations.
- Shipping fees are excluded from standard net item revenue unless a specific analysis defines otherwise.
- Cancelled and returned orders are treated separately.
- Customer segmentation uses predefined RFM-style rules.
- Time-dependent analytical logic uses December 31, 2025, as its reference date.
- Marketing attribution uses a 14-day lookback window for eligible campaign clicks.
- Customer lifetime value is presented as a historical revenue proxy, not a predictive forecast.

The analytical outputs are descriptive and should not be interpreted as proof of causation.

---

## Project Purpose

This project was developed to strengthen the practical application of SQL in business and data analytics.

Beyond writing queries, the emphasis is on understanding business requirements, defining meaningful metrics, structuring relational data, and translating analytical questions into SQL-based solutions.

It reflects the relationship between technical SQL proficiency and business-oriented analytical thinking.

---

## Author

**Siratal Mustakim Ador**

Data Analyst | Business Analyst

**Technical Focus:** SQL | MySQL | Python | Microsoft Excel | Power BI | Business Intelligence

GitHub: [github.com/mustakimador17](https://github.com/mustakimador17)

LinkedIn: [Connect on LinkedIn](https://www.linkedin.com/in/mustakimador/)

---

*Built with MySQL. Focused on data, analytical reasoning, and business decisions.*
