-- ==============================================================
-- FILE: InsertData.sql
-- PURPOSE: Populate Mock Data for LogisticsDB
-- COMPATIBILITY: Works with the provided PreData.sql (No IDENTITY columns)
-- ==============================================================

USE LOGISTICSDATABASE;
GO

-- ==============================================================
-- 1. INSERT USERS (Base Class)
-- IDs 1-10: 1 Admin, 5 Customers, 4 Drivers
-- ==============================================================
INSERT INTO Users (UserID, SSN, FName, MName, LName, Email, Password, Date_of_Birth, Account_Status) VALUES 
-- Admin
(1, '001', 'Quan', 'Van', 'Ly', 'admin@hcmut.edu.vn', 'pass123', '1990-01-01', 'ACTIVE'),

-- Customers
(2, '002', 'An', 'Van', 'Nguyen', 'an.nguyen@hcmut.edu.vn', 'pass123', '2000-05-15', 'ACTIVE'),
(3, '003', 'Binh', 'Thi', 'Tran', 'binh.tran@hcmut.edu.vn', 'pass123', '2001-08-20', 'ACTIVE'),
(4, '004', 'Cuong', 'Minh', 'Le', 'cuong.le@hcmut.edu.vn', 'pass123', '2002-02-02', 'ACTIVE'),
(5, '005', 'Dung', 'Tuan', 'Pham', 'dung.pham@hcmut.edu.vn', 'pass123', '1999-11-11', 'ACTIVE'),
(6, '006', 'Mai', 'Thi', 'Hoang', 'mai.hoang@hcmut.edu.vn', 'pass123', '2003-03-03', 'ACTIVE'),

-- Drivers
(7, '007', 'Tai', 'Hoang', 'Le', 'tai.le@driver.com', 'pass123', '1995-12-12', 'ACTIVE'),
(8, '008', 'Hung', 'Minh', 'Pham', 'hung.pham@driver.com', 'pass123', '1998-03-10', 'ACTIVE'),
(9, '009', 'Nam', 'Van', 'Vo', 'nam.vo@driver.com', 'pass123', '1996-07-07', 'ACTIVE'),
(10, '010', 'Tuyet', 'Thi', 'Nguyen', 'tuyet.nguyen@driver.com', 'pass123', '1994-09-09', 'INACTIVE');

-- Insert Phone Numbers
INSERT INTO User_Phone (UserID, Phone_Number) VALUES
(1, '0901111111'), 
(2, '0902222222'), (3, '0903333333'), (4, '0904444444'), (5, '0905555555'), (6, '0906666666'),
(7, '0907777777'), (8, '0908888888'), (9, '0909999999'), (10, '0910000000');

-- ==============================================================
-- 2. INSERT ROLES (Subclasses)
-- ==============================================================

-- Admin
INSERT INTO Admin (AdminID, Admin_Name) VALUES (1, 'Super Admin');

-- Customer
INSERT INTO Customer (CustomerID, Membership_Level, Invited_By_ID) VALUES 
(2, 'Gold', NULL),   
(3, 'Silver', 2),   -- Binh invited by An
(4, 'Platinum', NULL),
(5, 'Silver', 4),   -- Dung invited by Cuong
(6, 'Gold', 2);     -- Mai invited by An

-- Driver
-- Status Logic:
-- Driver 7: DELIVERING (Busy with Order 10)
-- Driver 8: DELIVERING (Busy with Order 9)
-- Driver 9: RECEIVED_ORDER (Busy with Order 😎
-- Driver 10: OFFLINE (Not working)
INSERT INTO Driver (DriverID, Driver_License, Current_Location, Rating, Status, Order_Approval, Verified, Managed_By_Admin, Assign_Date) VALUES 
(7, 'B2-007', 'Cong KTX Khu A', 4.8, 'DELIVERING', 150, 1, 1, '2025-01-01'),
(8, 'B2-008', 'Nga Tu Thu Duc', 4.5, 'DELIVERING', 80, 1, 1, '2025-02-01'),
(9, 'B2-009', 'Suoi Tien', 4.9, 'RECEIVED_ORDER', 220, 1, 1, '2025-03-01'),
(10, 'B2-010', 'Landmark 81', 4.0, 'DELIVERING', 10, 1, 1, '2025-04-01');

-- Vehicle
INSERT INTO Vehicle (VehicleID, Plate_Number, Vehicle_ID_Number, Vehicle_Type, Registration_Date, DriverID) VALUES 
(1, '59-X1 111.11', 'VIN001', 'Honda Wave', '2023-01-01', 7),
(2, '59-X2 222.22', 'VIN002', 'Yamaha Exciter', '2023-05-15',8),
(3, '59-X3 333.33', 'VIN003', 'Honda Winner', '2024-01-01', 9),
(4, '59-X4 444.44', 'VIN004', 'Vision', '2024-02-20', 10);

-- ==============================================================
-- 3. INSERT RESTAURANTS & MENUS
-- ==============================================================
INSERT INTO Restaurant (RestaurantID, Name, Open_Time, Close_Time, Location, Contact_Info, Certification, Created_By_Admin, Approval_Date) VALUES 
(1, 'Com Tam Cali', '07:00:00', '21:00:00', 'Vo Van Ngan, Thu Duc', '02838383838', 'CERT-001', 1, '2025-01-10'),
(2, 'Phuc Long Tea', '08:00:00', '22:00:00', 'Vincom Thu Duc', '02844444444', 'CERT-002', 1, '2025-01-15'),
(3, 'Pho Hung', '06:00:00', '23:00:00', 'Xa Lo Ha Noi, Q9', '02855555555', 'CERT-003', 1, '2025-02-01');

INSERT INTO Menu (MenuID, Name, Status, Create_Date, Update_Date, RestaurantID) VALUES 
(1, 'Com Tam Menu', 'ACTIVE', '2025-01-10', '2025-01-10', 1),
(2, 'Drinks Menu', 'ACTIVE', '2025-01-15', '2025-01-15', 2),
(3, 'Pho Menu', 'ACTIVE', '2025-02-01', '2025-02-01', 3);

INSERT INTO Menu_Item (Food_ID, Food_Name, Price, Description, Available_Flag, Category_ID, MenuID) VALUES 
-- Com Tam (Menu 1)
(1, 'Com Suon Bi', 50000, 'Suon nuong, bi, mo hanh', 1, 'FOOD', 1),
(2, 'Com Ga Nuong', 55000, 'Ga nuong mat ong', 1, 'FOOD', 1),
-- GongCha(Menu 2)
(3, 'Tra Dao', 60000, 'Size L, 50% duong', 1, 'DRINK', 2),
(4, 'Tra Sua Oolong', 65000, 'Tran chau trang', 1, 'DRINK', 2),
-- Pho Hung (Menu 3)
(5, 'Pho Dac Biet', 75000, 'Tai, Nam, Gau, Gan', 1, 'FOOD', 3),
(6, 'Pho Tai', 65000, 'Tai mem', 1, 'FOOD', 3);

-- ==============================================================
-- 4. INSERT COUPONS
-- ==============================================================
INSERT INTO Coupon (CouponID, Code, Discount_Percent, Discount_Amount, Min_Order_Value, Max_Discount_Amount, Start_Date, End_Date, Created_By_Admin) VALUES 
(1, 'WELCOME', 20.00, NULL, 50000, 50000, '2025-01-01', '2025-12-31', 1),
(2, 'FREESHIP', 0.00, 15000, 150000, 15000, '2025-06-01', '2025-06-30', 1),
(3, 'TET2025', 10.00, NULL, 200000, 100000, '2025-01-01', '2025-02-28', 1);

-- ==============================================================
-- 5. INSERT ORDERS & DETAILS
-- ==============================================================
SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderID, Order_Date, Order_Status, Total_Amount, Delivery_Address, Estimated_Time, RestaurantID, CustomerID, DriverID, CouponID) VALUES
-- PAST ORDERS (Completed - Historical Data)
(1, '2025-10-01 11:30:00', 'COMPLETED', 105000, 'KTX Khu A', '2025-10-01 12:00:00', 1, 2, 7, NULL),
(2, '2025-10-02 14:00:00', 'COMPLETED', 125000, 'KTX Khu B', '2025-10-02 14:30:00', 2, 3, 8, 1),
(3, '2025-10-03 19:00:00', 'COMPLETED', 75000, 'Quan 9', '2025-10-03 19:40:00', 3, 4, 9, NULL),

-- CANCELED ORDERS
(4, '2025-10-04 10:00:00', 'CANCELED', 60000, 'Thu Duc', NULL, 2, 5, NULL, NULL), -- Refunded
(5, '2025-10-05 08:00:00', 'CANCELED', 50000, 'KTX Khu A', NULL, 1, 6, NULL, NULL), -- No Refund (Unpaid)

-- ACTIVE ORDERS (The "Right Now" Scenario)
(6, '2025-10-24 18:00:00', 'PENDING', 130000, 'KTX Khu A', NULL, 3, 2, NULL, NULL),  -- No Driver
(7, '2025-10-24 18:05:00', 'PENDING', 65000, 'KTX Khu B', NULL, 2, 3, NULL, NULL),  -- No Driver
(8, '2025-10-24 18:10:00', 'CONFIRMED', 150000, 'Quan 9', '2025-10-24 19:00:00', 1, 4, 9, 3), -- Driver 9
(9, '2025-10-24 18:15:00', 'DELIVERING', 60000, 'Thu Duc', '2025-10-24 18:45:00', 2, 5, 8, NULL), -- Driver 8

-- NEW ACTIVE ORDER (Max out drivers)
(10, '2025-10-24 18:20:00', 'DELIVERING', 200000, 'Quan 2', '2025-10-24 19:00:00', 3, 6, 7, NULL), -- Driver 7

-- MORE HISTORICAL DATA (For Monthly Revenue Reports)
(11, '2025-09-15 12:00:00', 'COMPLETED', 50000, 'KTX Khu A', '2025-09-15 12:30:00', 1, 2, 7, NULL),
(12, '2025-09-20 18:00:00', 'COMPLETED', 140000, 'Thu Duc', '2025-09-20 18:45:00', 3, 3, 8, NULL),
(13, '2025-09-25 09:00:00', 'COMPLETED', 55000, 'Quan 9', '2025-09-25 09:30:00', 1, 4, 9, NULL),
(14, '2025-08-10 10:00:00', 'COMPLETED', 60000, 'KTX Khu B', '2025-08-10 10:30:00', 2, 5, 7, NULL),
(15, '2025-08-15 11:00:00', 'COMPLETED', 75000, 'Thu Duc', '2025-08-15 11:45:00', 3, 6, 8, NULL);

-- Order Items
INSERT INTO Order_Item (OrderID, Food_ID, Num_Item, Price_At_Order) VALUES 
-- Old Orders
(1, 1, 1, 50000), (1, 2, 1, 55000),
(2, 3, 1, 60000), (2, 4, 1, 65000),
(3, 5, 1, 75000),
(4, 3, 1, 60000),
(5, 1, 1, 50000),
(6, 5, 1, 75000), (6, 2, 1, 55000),
(7, 4, 1, 65000),
(8, 1, 3, 50000),
(9, 3, 1, 60000),
-- New Orders
(10, 5, 2, 75000), (10, 1, 1, 50000), -- Order 10 (2 Pho, 1 Com)
(11, 1, 1, 50000),
(12, 5, 1, 75000), (12, 4, 1, 65000),
(13, 2, 1, 55000),
(14, 3, 1, 60000),
(15, 6, 1, 75000);

-- ==============================================================
-- 6. INSERT PAYMENTS & REFUNDS
-- ==============================================================
INSERT INTO Payment (PaymentID, Payment_Date, Payment_Status, Payment_method, OrderID) VALUES 
-- Payments for Orders 1-9
(1, '2025-10-01 11:35:00', 'SUCCESS', 'Cash', 1),
(2, '2025-10-02 14:05:00', 'SUCCESS', 'Cash', 2),
(3, '2025-10-03 19:05:00', 'SUCCESS', 'Cash', 3),
(4, '2025-10-04 10:05:00', 'SUCCESS', 'Cashless', 4), -- Paid then Cancelled
(5, '2025-10-24 18:12:00', 'SUCCESS', 'Cashless', 8),
(6, '2025-10-24 18:17:00', 'SUCCESS', 'Cash', 9),

-- Payments for New Orders 10-15
(7, '2025-10-24 18:22:00', 'SUCCESS', 'Cashless', 10),
(8, '2025-09-15 12:05:00', 'SUCCESS', 'Cash', 11),
(9, '2025-09-20 18:05:00', 'SUCCESS', 'Cashless', 12),
(10, '2025-09-25 09:05:00', 'SUCCESS', 'Cash', 13),
(11, '2025-08-10 10:05:00', 'SUCCESS', 'Cash', 14),
(12, '2025-08-15 11:05:00', 'SUCCESS', 'Cash', 15);

-- Refund
INSERT INTO Refund (RefundID, PaymentID, Amount, Reason) VALUES 
(1, 4, 60000, 'Driver crashed, order canceled');
GO