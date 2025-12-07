-- CODE TẠO BẢNG (Chuẩn SQL Server & Đã tối ưu hóa)
USE LOGISTICSDATABASE;
GO

-- ==========================================
-- 1. XÓA BẢNG CŨ (Cập nhật: Bỏ bảng Coupon_Applied_Menu)
-- ==========================================
DROP TABLE IF EXISTS Refund;
DROP TABLE IF EXISTS Bank;
DROP TABLE IF EXISTS E_Wallet;
DROP TABLE IF EXISTS Cashless;
DROP TABLE IF EXISTS Cash;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Order_Item;
DROP TABLE IF EXISTS Orders;
-- DROP TABLE IF EXISTS Coupon_Applied_Menu; -- ĐÃ XÓA DÒNG NÀY
DROP TABLE IF EXISTS Coupon;
DROP TABLE IF EXISTS Menu_Item;
DROP TABLE IF EXISTS Menu;
DROP TABLE IF EXISTS Restaurant;
DROP TABLE IF EXISTS Vehicle;
DROP TABLE IF EXISTS Driver;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Admin;
DROP TABLE IF EXISTS User_Phone;
DROP TABLE IF EXISTS Users;
GO
-- ==========================================
-- TẠO BẢNG
-- ==========================================

-- Bảng gốc USERS
CREATE TABLE Users (
    UserID INT PRIMARY KEY, 
    SSN VARCHAR(20) UNIQUE NOT NULL,
    FName VARCHAR(50) NOT NULL,
    MName VARCHAR(50),
    LName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL, 
    Date_of_Birth DATE,             
    Account_Status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (Account_Status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);

CREATE TABLE User_Phone (
    UserID INT,
    Phone_Number VARCHAR(15),
    PRIMARY KEY (UserID, Phone_Number),
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

CREATE TABLE Admin (
    AdminID INT PRIMARY KEY,
    Admin_Name VARCHAR(50),
    FOREIGN KEY (AdminID) REFERENCES Users(UserID) ON DELETE CASCADE
);

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    Membership_Level VARCHAR(20) DEFAULT 'Silver',
    Invited_By_ID INT, -- Thay thế cho bảng INVITE
    FOREIGN KEY (CustomerID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (Invited_By_ID) REFERENCES Customer(CustomerID)
);

CREATE TABLE Driver (
    DriverID INT PRIMARY KEY,
    Driver_License VARCHAR(50) UNIQUE NOT NULL,
    Current_Location VARCHAR(100),
    Rating DECIMAL(3, 2) DEFAULT 5.00 CHECK (Rating BETWEEN 0 AND 5),
    Status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (Status IN ('AVAILABLE', 'RECEIVED_ORDER', 'DELIVERING')),
    Order_Approval INT DEFAULT 0,
    Verified BIT DEFAULT 0, 
    -- Thay thế bảng MANAGE: Dùng khóa ngoại Managed_By_Admin
    Managed_By_Admin INT,
    Assign_Date DATETIME,
    FOREIGN KEY (DriverID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (Managed_By_Admin) REFERENCES Admin(AdminID)
);

CREATE TABLE Vehicle (
    VehicleID INT PRIMARY KEY,
    Plate_Number VARCHAR(20) UNIQUE NOT NULL,
    Vehicle_ID_Number VARCHAR(50), -- Mã số khung/số máy
    Vehicle_Type VARCHAR(50),
    Registration_Date DATE,
    DriverID INT UNIQUE NOT NULL, -- Thay thế quan hệ OWN: Mỗi xe thuộc về 1 tài xế
    FOREIGN KEY (DriverID) REFERENCES Driver(DriverID)
);

CREATE TABLE Restaurant (
    RestaurantID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Open_Time TIME,
    Close_Time TIME,
    Location VARCHAR(255),
    Contact_Info VARCHAR(100),
    Certification VARCHAR(255), 
    Update_Date DATE,

    -- Thay thế bảng KEEP_TRACK_INFORMATION
    Created_By_Admin INT,
    Approval_Date DATETIME,
    FOREIGN KEY (Created_By_Admin) REFERENCES Admin(AdminID),
    CHECK (Close_Time > Open_Time)
);

CREATE TABLE Menu (
    MenuID INT PRIMARY KEY,
    Name VARCHAR(50),
    Status VARCHAR(20),
    Create_Date DATE,
    Update_Date DATE,
    RestaurantID INT NOT NULL,
    FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID)
);

CREATE TABLE Menu_Item (
    Food_ID INT PRIMARY KEY,
    Food_Name VARCHAR(100),
    Price DECIMAL(10, 2) CHECK (Price >= 0),
    Description TEXT,
    Available_Flag BIT DEFAULT 1,
    Category_ID VARCHAR(50),
    MenuID INT NOT NULL,

    
    FOREIGN KEY (MenuID) REFERENCES Menu(MenuID)
);

-- Bảng CREATE_COUPON được gộp vào đây (thông qua Created_By_Admin)
CREATE TABLE Coupon (
    CouponID INT PRIMARY KEY,
    Code VARCHAR(20) UNIQUE NOT NULL, -- Mã code không được trùng
    Discount_Percent DECIMAL(5, 2) CHECK (Discount_Percent BETWEEN 0 AND 100),
    Discount_Amount DECIMAL(10, 2),   -- Thêm: Giảm giá theo số tiền cố định (nếu cần)
    Min_Order_Value DECIMAL(10, 2),   -- Điều kiện: Giá trị đơn hàng tối thiểu để dùng
    Max_Discount_Amount DECIMAL(10,2),-- Thêm: Giảm tối đa bao nhiêu (ví dụ: giảm 10% nhưng tối đa 50k)
    Start_Date DATE,
    End_Date DATE,
    Created_By_Admin INT,
    FOREIGN KEY (Created_By_Admin) REFERENCES Admin(AdminID),
    CHECK (Start_Date <= End_Date)
);


-- Các bảng GENERATE, DELIVERS, RECEIVE_ORDER, USE_COUPON
-- Đều được tối ưu hóa thành các Khóa Ngoại (Foreign Key) trong bảng Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    Order_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Order_Status VARCHAR(20) CHECK (Order_Status IN ('PENDING', 'CONFIRMED', 'DELIVERING', 'COMPLETED', 'CANCELED')),
    Total_Amount DECIMAL(10, 2),
    Delivery_Address VARCHAR(255),
    Estimated_Time DATETIME, 
    
    RestaurantID INT,
    CustomerID INT NOT NULL, 
    DriverID INT,            
    CouponID INT, -- Foreign Key này tạo mối quan hệ N:1 (Nhiều Order dùng 1 Coupon)
    
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    FOREIGN KEY (CouponID) REFERENCES Coupon(CouponID),
    FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID)
);

CREATE TABLE Order_Item (
    OrderID INT,
    Food_ID INT,       
    Num_Item INT CHECK (Num_Item > 0),
    Price_At_Order DECIMAL(10, 2),
    PRIMARY KEY (OrderID, Food_ID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (Food_ID) REFERENCES Menu_Item(Food_ID)
);

-- Bảng SETTLED_BY được gộp vào đây
CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY,
    Payment_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Payment_Status VARCHAR(20) CHECK (Payment_Status IN ('SUCCESS', 'FAILED', 'REFUNDED')),
    Payment_method VARCHAR(50) CHECK (Payment_method IN ('Cash', 'Cashless')),
    OrderID INT UNIQUE,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

CREATE TABLE Refund (
    RefundID INT PRIMARY KEY,
    PaymentID INT NOT NULL,
    Amount DECIMAL(10, 2),
    Reason VARCHAR(255),

    FOREIGN KEY (PaymentID) REFERENCES Payment(PaymentID) ON DELETE CASCADE
);
GO