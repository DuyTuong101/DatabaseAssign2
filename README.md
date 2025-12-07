# DatabaseAssign2
## ⚙️ Installation & Running Guide

Follow these steps to set up and run the **Food Journey** system on your local machine.

### Prerequisites (Yêu cầu trước khi cài đặt)
* **Node.js**: Version 16+
* **SQL Server**: 2019 or later (Standard/Developer/Express edition)
* **SQL Server Management Studio (SSMS)**: For running SQL scripts.
* **Git**: To clone the repository.

---

### Step 1: Database Setup (SQL Server)

1.  Open **SSMS** and connect to your SQL Server instance using **Windows Authentication** (Admin privileges).
2.  Open a **New Query** window.
3.  **Create Database & Users:**
    Run the setup script to create the `LOGISTICSDATABASE` and the `trace_user` account.
    > *Note: Ensure the password for `trace_user` matches the one in `backend/config.env`.*

    ```sql
    USE master;
    GO
    IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'LOGISTICSDATABASE')
        CREATE DATABASE LOGISTICSDATABASE;
    GO
    -- Run the "PreData.sql" script here to create tables
    ```

4.  **Execute SQL Scripts in Order:**
    Navigate to the `database/` folder and run these files sequentially:
    1.  `PreData.sql` (Creates Tables & Constraints).
    2.  `DataLogistics.sql` (Inserts Sample Data - 10 rows/table).
    3.  `Feature_Order_Processing.sql` (Creates Stored Procedures for Order Flow).

---

### Step 2: Backend Setup (NestJS)

1.  Open a terminal and navigate to the `backend` folder:
    ```bash
    cd backend
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Configure Environment Variables:
    * Create a file named `config.env` inside the `config` folder (or check `backend/config/config.env`).
    * Ensure the database credentials match your SQL Server setup:
        ```ini
        PORT=5000
        DB_HOST=localhost
        DB_PORT=1433
        DB_USERNAME=trace_user
        DB_PASSWORD=Trace@12345678
        DB_NAME=LOGISTICSDATABASE
        ```

4.  Start the Backend Server:
    ```bash
    npm run start:dev
    ```
    * *Success Indicator:* You should see `[NestApplication] Nest application successfully started` in the terminal.
    * *API URL:* `http://localhost:5000/api/logistics`

---

### Step 3: Frontend Setup (React + Vite)

1.  Open a **new** terminal window and navigate to the `frontend` folder:
    ```bash
    cd frontend
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Start the Frontend Application:
    ```bash
    npm run dev
    ```

4.  Access the Web App:
    * Open your browser and go to: **http://localhost:5173** (or the port shown in your terminal).

---

### 🚀 Usage Flow (Test Case)

Once everything is running, try the **"Smart Order Flow"**:

1.  **Login:** Enter Customer ID `41` at the Welcome screen.
2.  **Select Restaurant:** Choose **"Pho Hung"** from the list.
3.  **Order Items:**
    * Click **"+ Add"** on "Pho Bo" (Price: 50,000 VND).
    * Enter Coupon Code: `WELCOME` (Optional) to see the discount.
    * Enter Delivery Address.
4.  **Confirm:** Click **"PLACE ORDER"**.
5.  **Track:** The system will automatically redirect you to the **Tracking Tab** to see your new order status (`PENDING`) and assigned Driver.
