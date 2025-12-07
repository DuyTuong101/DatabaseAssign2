USE LOGISTICSDATABASE;
GO

PRINT '>>> KHOI TAO MODULE: ORDER FLOW COMPLETE...';
GO
-- ======================================================================================
-- PHẦN 1: CÁC HÀM HỖ TRỢ HIỂN THỊ (VIEW HELPERS)
-- Dùng cho giao diện chọn Nhà hàng và Món ăn
-- ======================================================================================

-- 1. Lấy danh sách tất cả Nhà hàng (Cho Bước 2: Chọn Quán)
CREATE OR ALTER PROCEDURE sp_GetListRestaurants
AS
BEGIN
    SELECT RestaurantID, Name, Location, Open_Time, Close_Time 
    FROM Restaurant 
    ORDER BY Name;
END;
GO

-- 2. Lấy Menu theo Nhà hàng (Cho Bước 3: Chọn Món)
CREATE OR ALTER PROCEDURE sp_GetFoodsByRestaurant
    @RestaurantID INT
AS
BEGIN
    SELECT 
        MI.Food_ID, 
        MI.Food_Name, 
        MI.Price, 
        MI.Description,
        M.Name AS Menu_Category
    FROM Menu_Item MI
    JOIN Menu M ON MI.MenuID = M.MenuID
    WHERE M.RestaurantID = @RestaurantID 
      AND MI.Available_Flag = 1
    ORDER BY MI.Food_Name;
END;
GO

-- ======================================================================================
-- PHẦN 2: XỬ LÝ ĐẶT HÀNG (CONFIRM ORDER)
-- Xử lý toàn bộ: Tạo đơn -> Thêm món -> Áp mã Coupon -> Tính tiền (Trong 1 Transaction)
-- ======================================================================================

CREATE OR ALTER PROCEDURE sp_CreateFullOrder
    @CustomerID INT,
    @PickupAddr NVARCHAR(255),
    @DeliveryAddr NVARCHAR(255),
    @CouponCode VARCHAR(20) = NULL,
    @JsonItems NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
        THROW 50001, 'Lỗi: Khách hàng không tồn tại.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- A. Random 1 Tài xế đang ONLINE (Nếu không có ai thì để NULL)
        DECLARE @RandomDriverID INT;
        SELECT TOP 1 @RandomDriverID = DriverID 
        FROM Driver 
        WHERE Status = 'ONLINE' -- Chỉ chọn tài xế đang làm việc
        ORDER BY NEWID(); -- Random

        -- B. Tạo đơn hàng (Gán luôn DriverID vừa random được)
        INSERT INTO Orders (Order_Date, Order_Status, Total_Amount, Delivery_Address, CustomerID, DriverID, CouponID)
        VALUES (GETDATE(), 'PENDING', 0, @DeliveryAddr, @CustomerID, @RandomDriverID, NULL);

        DECLARE @NewOrderID INT = SCOPE_IDENTITY();

        -- C. Chèn món ăn
        INSERT INTO Order_Item (OrderID, Food_ID, Num_Item, Price_At_Order)
        SELECT @NewOrderID, J.FoodID, J.Quantity, MI.Price
        FROM OPENJSON(@JsonItems) WITH (FoodID INT '$.FoodID', Quantity INT '$.Quantity') AS J
        JOIN Menu_Item MI ON J.FoodID = MI.Food_ID;

        -- D. Tính tiền & Coupon
        DECLARE @SubTotal DECIMAL(10, 2);
        SELECT @SubTotal = SUM(Num_Item * Price_At_Order) FROM Order_Item WHERE OrderID = @NewOrderID;
        IF @SubTotal IS NULL SET @SubTotal = 0;

        DECLARE @DiscountAmount DECIMAL(10, 2) = 0;
        DECLARE @FinalCouponID INT = NULL;

        IF @CouponCode IS NOT NULL AND @CouponCode <> ''
        BEGIN
            DECLARE @C_ID INT, @C_MinVal DECIMAL(10,2), @C_End DATE, @C_Percent DECIMAL(5,2), @C_MaxDisc DECIMAL(10,2);
            SELECT @C_ID=CouponID, @C_Percent=Discount_Percent, @C_MinVal=Min_Order_Value, @C_MaxDisc=Max_Discount_Amount, @C_End=End_Date
            FROM Coupon WHERE Code = @CouponCode;

            IF @C_ID IS NOT NULL AND GETDATE() <= @C_End AND @SubTotal >= @C_MinVal
            BEGIN
                SET @DiscountAmount = (@SubTotal * @C_Percent) / 100;
                IF @C_MaxDisc IS NOT NULL AND @DiscountAmount > @C_MaxDisc SET @DiscountAmount = @C_MaxDisc;
                SET @FinalCouponID = @C_ID;
            END
        END

        -- Update lại tiền và Coupon
        UPDATE Orders 
        SET Total_Amount = @SubTotal - @DiscountAmount,
            CouponID = @FinalCouponID
        WHERE OrderID = @NewOrderID;

        COMMIT TRANSACTION;
        
        -- Trả kết quả (Kèm ID tài xế để biết)
        SELECT 
            @NewOrderID AS OrderID, 
            (@SubTotal - @DiscountAmount) AS FinalTotal,
            @RandomDriverID AS AssignedDriverID;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ======================================================================================
-- PHẦN 3: QUẢN LÝ ĐƠN HÀNG (UPDATE & DELETE - GIỮ NGUYÊN LOGIC CŨ)
-- ======================================================================================

CREATE OR ALTER PROCEDURE sp_UpdateOrderInfo
    @OrderID INT,
    @NewAddress VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
        THROW 50001, 'Lỗi: Đơn hàng không tồn tại.', 1;

    -- Kiểm tra trạng thái (Chỉ cho sửa khi chưa giao xong)
    DECLARE @Status VARCHAR(20);
    SELECT @Status = Order_Status FROM Orders WHERE OrderID = @OrderID;
    
    IF @Status IN ('COMPLETED', 'CANCELED')
        THROW 50002, 'Lỗi: Không thể sửa địa chỉ đơn hàng đã kết thúc.', 1;

    -- Cập nhật
    UPDATE Orders SET Delivery_Address = @NewAddress WHERE OrderID = @OrderID;
END;
GO

-- 5. Hủy đơn hàng (Delete)
CREATE OR ALTER PROCEDURE sp_Order_Delete
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status VARCHAR(20);
    SELECT @Status = Order_Status FROM Orders WHERE OrderID = @OrderID;

    IF @Status NOT IN ('PENDING', 'CANCELED')
        THROW 50009, 'Lỗi: Chỉ được xóa đơn hàng PENDING hoặc đã Hủy.', 1;

    -- Xóa thủ công (Nếu không có Cascade DB)
    DELETE FROM Order_Item WHERE OrderID = @OrderID;
    DELETE FROM Payment WHERE OrderID = @OrderID;
    DELETE FROM Orders WHERE OrderID = @OrderID;

    PRINT 'Xóa đơn hàng thành công!';
END;
GO

-- ======================================================================================
-- THỦ TỤC: XEM TRƯỚC HÓA ĐƠN (PREVIEW BILL)
-- Nhiệm vụ: Tính tổng tiền món ăn, kiểm tra Coupon và trả về số tiền được giảm (không tạo đơn)
-- ======================================================================================
CREATE OR ALTER PROCEDURE sp_PreviewOrderBill
    @CouponCode VARCHAR(20) = NULL,
    @JsonItems NVARCHAR(MAX) -- Danh sách món: '[{"FoodID":1, "Quantity":2}, ...]'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SubTotal DECIMAL(10, 2) = 0;
    DECLARE @DiscountAmount DECIMAL(10, 2) = 0;
    DECLARE @Message NVARCHAR(255) = N'';

    -- 1. Tính Tổng tiền hàng (Subtotal) dựa trên giá hiện tại
    SELECT @SubTotal = SUM(J.Quantity * MI.Price)
    FROM OPENJSON(@JsonItems) WITH (FoodID INT '$.FoodID', Quantity INT '$.Quantity') AS J
    JOIN Menu_Item MI ON J.FoodID = MI.Food_ID;

    IF @SubTotal IS NULL SET @SubTotal = 0;

    -- 2. Kiểm tra và Tính Coupon (Nếu có)
    IF @CouponCode IS NOT NULL AND @CouponCode <> ''
    BEGIN
        DECLARE @C_ID INT, @C_Percent DECIMAL(5,2), @C_MinVal DECIMAL(10,2), @C_MaxDisc DECIMAL(10,2), @C_End DATE;
        
        SELECT 
            @C_ID = CouponID, 
            @C_Percent = Discount_Percent,
            @C_MinVal = Min_Order_Value,
            @C_MaxDisc = Max_Discount_Amount,
            @C_End = End_Date
        FROM Coupon WHERE Code = @CouponCode;

        -- Validate Coupon
        IF @C_ID IS NULL
            SET @Message = N'Mã giảm giá không tồn tại.';
        ELSE IF GETDATE() > @C_End
            SET @Message = N'Mã giảm giá đã hết hạn.';
        ELSE IF @SubTotal < @C_MinVal
            SET @Message = N'Đơn hàng chưa đạt giá trị tối thiểu (' + CAST(CAST(@C_MinVal AS INT) AS NVARCHAR) + N') để dùng mã này.';
        ELSE
        BEGIN
            -- Tính tiền giảm
            SET @DiscountAmount = (@SubTotal * @C_Percent) / 100;
            -- Áp trần giảm giá
            IF @C_MaxDisc IS NOT NULL AND @DiscountAmount > @C_MaxDisc 
                SET @DiscountAmount = @C_MaxDisc;
            
            SET @Message = N'Áp dụng mã thành công! Giảm ' + CAST(CAST(@C_Percent AS INT) AS NVARCHAR) + N'%';
        END
    END

    -- 3. Trả kết quả
    SELECT 
        @SubTotal AS SubTotal,
        @DiscountAmount AS Discount,
        (@SubTotal - @DiscountAmount) AS FinalTotal,
        @Message AS Message,
        CASE WHEN @DiscountAmount > 0 THEN 1 ELSE 0 END AS IsValid
END;
GO

PRINT '✅ ĐÃ CẬP NHẬT MODULE ORDER FLOW THÀNH CÔNG!';