USE LOGISTICSDATABASE;
GO

-- =============================================
-- FUNCTION 1: TÍNH TỔNG TIỀN CUỐI CÙNG (Sau khi giảm giá)
-- =============================================
CREATE OR ALTER FUNCTION fn_CalcOrderFinalAmount (@OrderID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @FinalAmount DECIMAL(10, 2);
    DECLARE @RawTotal DECIMAL(10, 2);
    
    -- 1. Tính tổng tiền gốc từ bảng Order_Item (Số lượng * Giá lúc mua)
    SELECT @RawTotal = SUM(Num_Item * Price_At_Order)
    FROM Order_Item
    WHERE OrderID = @OrderID;

    -- Nếu không có món nào, trả về 0
    IF @RawTotal IS NULL SET @RawTotal = 0;

    -- 2. Lấy thông tin Coupon áp dụng cho đơn hàng này (nếu có)
    DECLARE @DiscountPercent DECIMAL(5, 2);
    DECLARE @MaxDiscount DECIMAL(10, 2);
    DECLARE @MinOrderValue DECIMAL(10, 2);
    DECLARE @CouponCode VARCHAR(20);

    SELECT 
        @DiscountPercent = C.Discount_Percent,
        @MaxDiscount = C.Max_Discount_Amount,
        @MinOrderValue = C.Min_Order_Value,
        @CouponCode = C.Code
    FROM Orders O
    JOIN Coupon C ON O.CouponID = C.CouponID
    WHERE O.OrderID = @OrderID;

    -- 3. Tính toán giảm giá
    DECLARE @DiscountAmount DECIMAL(10, 2) = 0;

    -- Chỉ giảm giá nếu có Coupon và Đơn hàng đạt giá trị tối thiểu
    IF @CouponCode IS NOT NULL AND @RawTotal >= @MinOrderValue
    BEGIN
        -- Tính số tiền được giảm theo %
        SET @DiscountAmount = @RawTotal * (@DiscountPercent / 100);

        -- Nếu số tiền giảm vượt quá mức tối đa cho phép, lấy mức tối đa
        IF @DiscountAmount > @MaxDiscount
        BEGIN
            SET @DiscountAmount = @MaxDiscount;
        END
    END

    -- 4. Tính tổng cuối
    SET @FinalAmount = @RawTotal - @DiscountAmount;

    RETURN @FinalAmount;
END;
GO

-- =============================================
-- PROCEDURE 2: TÍNH DOANH THU NHÀ HÀNG (Dùng Cursor như ý bạn)
-- =============================================
CREATE OR ALTER PROCEDURE sp_CalculateRestaurantRevenue
    @RestaurantID INT,
    @FromDate DATE,
    @ToDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validation (Kiểm tra dữ liệu đầu vào)
    IF @RestaurantID IS NULL OR @RestaurantID <= 0
    BEGIN
        RAISERROR('Lỗi: RestaurantID phải là số dương.', 16, 1);
        RETURN;
    END

    IF @FromDate IS NULL OR @ToDate IS NULL
    BEGIN
        RAISERROR('Lỗi: Khoảng thời gian không được để trống.', 16, 1);
        RETURN;
    END

    IF @FromDate > @ToDate
    BEGIN
        RAISERROR('Lỗi: Ngày bắt đầu phải trước ngày kết thúc.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Restaurant WHERE RestaurantID = @RestaurantID)
    BEGIN
        RAISERROR('Lỗi: Nhà hàng không tồn tại.', 16, 1);
        RETURN;
    END

    -- 2. Khai báo biến để cộng dồn
    DECLARE @TotalRevenue DECIMAL(18, 2) = 0;
    DECLARE @CurrentAmount DECIMAL(10, 2);

    -- 3. Khai báo CURSOR (Con trỏ) để duyệt từng đơn hàng đã thanh toán
    DECLARE cur_revenue CURSOR FOR
        SELECT P.Amount
        FROM Payment P
        JOIN Orders O ON P.OrderID = O.OrderID
        WHERE O.RestaurantID = @RestaurantID
          AND P.Payment_Status = 'SUCCESS' -- Chỉ tính đơn đã thanh toán thành công
          AND CAST(P.Payment_Date AS DATE) BETWEEN @FromDate AND @ToDate;

    -- 4. Mở và Duyệt Cursor
    OPEN cur_revenue;
    FETCH NEXT FROM cur_revenue INTO @CurrentAmount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Cộng dồn doanh thu
        SET @TotalRevenue = @TotalRevenue + @CurrentAmount;

        -- Đọc dòng tiếp theo
        FETCH NEXT FROM cur_revenue INTO @CurrentAmount;
    END

    -- 5. Đóng và giải phóng Cursor
    CLOSE cur_revenue;
    DEALLOCATE cur_revenue;

    -- 6. Trả về kết quả
    SELECT 
        @RestaurantID AS RestaurantID,
        (SELECT Name FROM Restaurant WHERE RestaurantID = @RestaurantID) AS RestaurantName,
        @FromDate AS FromDate,
        @ToDate AS ToDate,
        @TotalRevenue AS TotalRevenue;
END;
GO