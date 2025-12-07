USE LOGISTICSDATABASE;
DELIMITER $$

-- ================================
-- 2.2.1 BUSINESS CONSTRAINT
-- Rule: Orders cannot be assigned to a driver who is
-- (1) not verified or (2) not in AVAILABLE status.
-- Enforced on: INSERT and UPDATE of Orders.DriverID
-- ================================

DROP TRIGGER IF EXISTS trg_CheckDriver_BeforeInsert $$
CREATE TRIGGER trg_CheckDriver_BeforeInsert
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE vVerified TINYINT;
    DECLARE vStatus VARCHAR(20);

    SET vVerified = NULL;
    SET vStatus = NULL;

    IF NEW.DriverID IS NOT NULL THEN
        SELECT Verified, Status
        INTO vVerified, vStatus
        FROM Driver
        WHERE DriverID = NEW.DriverID
        LIMIT 1;

        IF vVerified IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: DriverID does not exist.';
        END IF;

        IF vVerified = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Cannot assign order to UNVERIFIED driver.';
        END IF;

        IF UPPER(vStatus) <> 'AVAILABLE' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Driver is currently BUSY or OFFLINE.';
        END IF;
    END IF;
END $$

DROP TRIGGER IF EXISTS trg_CheckDriver_BeforeAssign $$
CREATE TRIGGER trg_CheckDriver_BeforeAssign
BEFORE UPDATE ON Orders
FOR EACH ROW
BEGIN
    DECLARE vVerified TINYINT;
    DECLARE vStatus VARCHAR(20);

    SET vVerified = NULL;
    SET vStatus = NULL;

    IF NEW.DriverID IS NOT NULL THEN
        SELECT Verified, Status
        INTO vVerified, vStatus
        FROM Driver
        WHERE DriverID = NEW.DriverID
        LIMIT 1;

        IF vVerified IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: DriverID does not exist.';
        END IF;

        IF vVerified = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Cannot assign order to UNVERIFIED driver.';
        END IF;

        IF NEW.DriverID <> OLD.DriverID THEN
            IF UPPER(vStatus) <> 'AVAILABLE' THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: New Driver is currently BUSY or OFFLINE.';
            END IF;
        END IF;
    END IF;
END $$

-- ================================
-- 2.2.2 DERIVED ATTRIBUTE
-- Attribute: Orders.Total_Amount
-- Formula: SUM(Order_Item.Num_Item * Order_Item.Price_At_Order)
-- Recalculated after INSERT, UPDATE, DELETE on Order_Item
-- ================================

DROP TRIGGER IF EXISTS trg_UpdateTotal_AfterInsertItem $$
CREATE TRIGGER trg_UpdateTotal_AfterInsertItem
AFTER INSERT ON Order_Item
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET Total_Amount = (
        SELECT COALESCE(SUM(Num_Item * Price_At_Order), 0)
        FROM Order_Item
        WHERE OrderID = NEW.OrderID
    )
    WHERE OrderID = NEW.OrderID;
END $$

DROP TRIGGER IF EXISTS trg_UpdateTotal_AfterUpdateItem $$
CREATE TRIGGER trg_UpdateTotal_AfterUpdateItem
AFTER UPDATE ON Order_Item
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET Total_Amount = (
        SELECT COALESCE(SUM(Num_Item * Price_At_Order), 0)
        FROM Order_Item
        WHERE OrderID = NEW.OrderID
    )
    WHERE OrderID = NEW.OrderID;

    IF OLD.OrderID <> NEW.OrderID THEN
        UPDATE Orders
        SET Total_Amount = (
            SELECT COALESCE(SUM(Num_Item * Price_At_Order), 0)
            FROM Order_Item
            WHERE OrderID = OLD.OrderID
        )
        WHERE OrderID = OLD.OrderID;
    END IF;
END $$

DROP TRIGGER IF EXISTS trg_UpdateTotal_AfterDeleteItem $$
CREATE TRIGGER trg_UpdateTotal_AfterDeleteItem
AFTER DELETE ON Order_Item
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET Total_Amount = (
        SELECT COALESCE(SUM(Num_Item * Price_At_Order), 0)
        FROM Order_Item
        WHERE OrderID = OLD.OrderID
    )
    WHERE OrderID = OLD.OrderID;
END $$

DELIMITER ;
