🏨 Hospitality ETL & Reporting System
📌 Overview
This project builds an ETL pipeline using Informatica IICS and Oracle PL/SQL to process hotel data and generate daily reports on occupancy and revenue.

📂 Data Sources
Guest_Master.csv → Guest details
Room_Master.csv → Room details
Checkin_Checkout.csv → Stay details

⚙️ Workflow
Load CSV data
Transform data in IICS
Store in staging table (STG_GUEST_STAY)
Run PL/SQL procedure to generate reports

🧠 Features
Daily check-in & check-out tracking
Room occupancy calculation
Revenue calculation
Audit logging using triggers

🛠️ Tech Stack
Informatica IICS
Oracle SQL & PL/SQL
