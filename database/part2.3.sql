USE LOGISTICSDATABASE;
GO

-- =======================================================================================
-- 2.3 REPORT FUNCTION: TRENDING FOOD ANALYSIS (Quantity Only)
-- Purpose: Find best-selling items using Aggregates (SUM), Group By, Having, Where, Order By, Joins
-- =======================================================================================
CREATE OR ALTER PROCEDURE sp_GetTrendingFoods
    @MinQuantitySold INT -- User input threshold
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        r.Name AS Restaurant_Name,
        mi.Food_Name,
        m.Name AS Menu_Category,
        -- [Requirement: Aggregate Function - Quantity Only]
        SUM(oi.Num_Item) AS Total_Quantity_Sold
    FROM 
        -- [Requirement: Joins 4 Tables]
        Menu_Item mi
        JOIN Order_Item oi ON mi.Food_ID = oi.Food_ID
        JOIN Orders o ON oi.OrderID = o.OrderID
        JOIN Menu m ON mi.MenuID = m.MenuID
        JOIN Restaurant r ON m.RestaurantID = r.RestaurantID
    WHERE 
        -- [Requirement: WHERE Clause]
        o.Order_Status = 'COMPLETED'
    GROUP BY 
        -- [Requirement: GROUP BY Clause]
        r.Name, 
        mi.Food_Name, 
        m.Name
    HAVING 
        -- [Requirement: HAVING Clause]
        SUM(oi.Num_Item) >= @MinQuantitySold
    ORDER BY 
        -- [Requirement: ORDER BY Clause]
        Total_Quantity_Sold DESC;
END
GO

-- =======================================================================================
-- 2.3 DRIVER ACTIVITY TRACKER
-- Purpose: View orders, transactions, and delivery status logic.
-- Input: DriverID (Optional), OrderStatus (Optional)
-- =======================================================================================
CREATE OR ALTER PROCEDURE sp_GetAllOrders
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        O.OrderID,
        O.Order_Date,
        O.Order_Status,
        O.Total_Amount,
        O.Delivery_Address,

        -- 1. Lấy tên Khách Hàng (Từ bảng Users qua CustomerID)
        ISNULL(C_User.FName + ' ' + C_User.LName, N'Khách ẩn danh') AS Customer_Name,

        -- 2. Lấy tên Tài Xế (Từ bảng Users qua DriverID)
        CASE 
            WHEN O.DriverID IS NULL THEN N'⏳ Chưa có tài xế'
            ELSE ISNULL(D_User.FName + ' ' + D_User.LName, N'Tài xế ẩn danh')
        END AS Driver_Name,

        -- 3. Lấy tên Nhà Hàng (Logic tìm ngược từ Món ăn -> Menu -> Quán)
        -- (Lấy quán của món ăn đầu tiên trong đơn)
        ISNULL((
            SELECT TOP 1 R.Name 
            FROM Order_Item OI 
            JOIN Menu_Item MI ON OI.Food_ID = MI.Food_ID
            JOIN Menu M ON MI.MenuID = M.MenuID
            JOIN Restaurant R ON M.RestaurantID = R.RestaurantID
            WHERE OI.OrderID = O.OrderID
        ), N'🛒 Chưa chọn món') AS Restaurant_Name

    FROM Orders O
    -- Join để lấy tên Khách
    LEFT JOIN Users C_User ON O.CustomerID = C_User.UserID
    -- Join để lấy tên Tài xế
    LEFT JOIN Users D_User ON O.DriverID = D_User.UserID
    WHERE O.CustomerID = @CustomerID
    ORDER BY O.Order_Date DESC; -- Đơn mới nhất lên đầu
END;
GO