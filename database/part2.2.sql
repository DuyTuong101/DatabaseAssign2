USE LogisticsDB;
GO

-- =======================================================================================
-- FUNCTION 1: Calculate Final Order Amount
-- Logic: Sum(Item Price * Qty) - Discount
-- Converted from MySQL to T-SQL (Set-based, No Cursors)
-- =======================================================================================
CREATE OR ALTER FUNCTION fn_calc_order_final_amount(@p_order_id INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @v_total_items DECIMAL(10,2) = 0;
    DECLARE @v_final DECIMAL(10,2) = 0;

    -- Coupon Variables
    DECLARE @v_coupon_id INT;
    DECLARE @v_discount_percent DECIMAL(5,2);
    DECLARE @v_discount_amount DECIMAL(10,2);
    DECLARE @v_min_order_value DECIMAL(10,2);
    DECLARE @v_max_discount_amount DECIMAL(10,2);
    DECLARE @v_start_date DATE;
    DECLARE @v_end_date DATE;
    
    DECLARE @v_applied_discount DECIMAL(10,2) = 0;
    DECLARE @v_percent_discount DECIMAL(10,2) = 0;

    -- 1. Validate Order Exists
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @p_order_id)
        RETURN 0;

    -- 2. Calculate Total Item Cost (Set-based SUM)
    -- Uses Price_At_Order if available, otherwise current Menu Price
    SELECT @v_total_items = SUM(oi.Num_Item * ISNULL(oi.Price_At_Order, mi.Price))
    FROM Order_Item oi
    JOIN Menu_Item mi ON oi.Food_ID = mi.Food_ID
    WHERE oi.OrderID = @p_order_id;

    SET @v_total_items = ISNULL(@v_total_items, 0);

    -- 3. Get Coupon Info
    SELECT @v_coupon_id = CouponID
    FROM Orders
    WHERE OrderID = @p_order_id;

    -- 4. Apply Coupon Logic
    IF @v_coupon_id IS NOT NULL
    BEGIN
        SELECT 
            @v_discount_percent = Discount_Percent,
            @v_discount_amount = Discount_Amount,
            @v_min_order_value = Min_Order_Value,
            @v_max_discount_amount = Max_Discount_Amount,
            @v_start_date = Start_Date,
            @v_end_date = End_Date
        FROM Coupon
        WHERE CouponID = @v_coupon_id;

        -- Check Validity (Min Value & Dates)
        IF @v_total_items >= ISNULL(@v_min_order_value, 0)
           AND (@v_start_date IS NULL OR @v_start_date <= CAST(GETDATE() AS DATE))
           AND (@v_end_date   IS NULL OR @v_end_date   >= CAST(GETDATE() AS DATE))
        BEGIN
            -- Calculate Percentage Discount
            IF @v_discount_percent IS NOT NULL AND @v_discount_percent > 0
            BEGIN
                SET @v_percent_discount = @v_total_items * @v_discount_percent / 100.0;
            END

            -- Total Discount (Percent + Fixed Amount)
            SET @v_applied_discount = @v_percent_discount + ISNULL(@v_discount_amount, 0);

            -- Apply Max Cap
            IF @v_max_discount_amount IS NOT NULL AND @v_applied_discount > @v_max_discount_amount
            BEGIN
                SET @v_applied_discount = @v_max_discount_amount;
            END
        END
    END

    -- 5. Final Result
    SET @v_final = @v_total_items - @v_applied_discount;
    IF @v_final < 0 SET @v_final = 0;

    RETURN @v_final;
END
GO

-- =======================================================================================
-- FUNCTION 2: Calculate Restaurant Revenue
-- Logic: Sum of Orders.Total_Amount for Successful Payments in Date Range
-- Fix: Uses Orders.Total_Amount (Payment.Amount was deleted)
-- =======================================================================================
CREATE OR ALTER FUNCTION fn_calc_restaurant_revenue(
    @p_restaurant_id INT,
    @p_from_date DATE,
    @p_to_date DATE
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @v_revenue DECIMAL(18,2) = 0;

    -- Basic Validation
    IF @p_from_date > @p_to_date RETURN 0;

    -- Calculate Revenue (Set-based SUM)
    SELECT @v_revenue = SUM(o.Total_Amount)
    FROM Payment p
    JOIN Orders o ON p.OrderID = o.OrderID
    WHERE o.RestaurantID = @p_restaurant_id
      AND p.Payment_Status = 'SUCCESS' -- Only count successful payments
      AND CAST(p.Payment_Date AS DATE) BETWEEN @p_from_date AND @p_to_date;

    RETURN ISNULL(@v_revenue, 0);
END
GO
