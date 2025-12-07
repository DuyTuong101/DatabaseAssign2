USE LOGISTICSDATABASE;
GO

-- ==============================================================
-- FILE: CleanData.sql
-- PURPOSE: Remove all mock data while keeping table structure
-- STRATEGY: Delete Child tables first, then Parents to avoid FK errors
-- ==============================================================

-- 1. DELETE TRANSACTION & OPERATIONAL DATA
-- These depend on Orders, which depend on Users/Restaurants
DELETE FROM Refund;
DELETE FROM Payment;
DELETE FROM Order_Item;
DELETE FROM Orders;

-- 2. DELETE ASSETS & MARKETING
DELETE FROM Vehicle;    -- Depends on Driver
DELETE FROM Coupon;     -- Depends on Admin
DELETE FROM Menu_Item;  -- Depends on Menu
DELETE FROM Menu;       -- Depends on Restaurant
DELETE FROM Restaurant; -- Depends on Admin

-- 3. DELETE USERS & ROLES
-- Note: Delete specific roles before the base 'Users' table

-- 3a. Handle Self-Referencing Constraint in Customer table
-- (Customers referring to other Customers via Invited_By_ID)
UPDATE Customer SET Invited_By_ID = NULL;

-- 3b. Delete Roles
DELETE FROM Customer;
DELETE FROM Driver;    -- Depends on Admin (Managed_By)
DELETE FROM Admin;     -- Parent of Driver/Restaurant/Coupon
DELETE FROM User_Phone;

-- 4. DELETE BASE USERS
-- Finally safe to delete the base User records
DELETE FROM Users;

GO