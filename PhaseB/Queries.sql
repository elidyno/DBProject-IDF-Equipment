-- =========================================================
-- Queries.sql
-- Phase B - First Queries
-- Military Equipment Management System
-- =========================================================


-- =========================================================
-- Query 1:
-- Equipment quantity by category
-- This query shows, for each equipment category:
-- how many equipment types are linked to it,
-- and how many actual equipment assets exist under this category.
-- =========================================================

SELECT
    ec.category_name,
    COUNT(DISTINCT et.type_id) AS equipment_type_count,
    COUNT(DISTINCT ea.asset_id) AS asset_count
FROM EquipmentCategory ec
JOIN CategoryType ct
    ON ec.category_id = ct.category_id
JOIN EquipmentType et
    ON ct.type_id = et.type_id
JOIN EquipmentAsset ea
    ON et.type_id = ea.type_id
GROUP BY
    ec.category_name
ORDER BY
    asset_count DESC;


-- =========================================================
-- Query 2:
-- Equipment quantity by storage location and condition
-- This query shows how many equipment assets exist in each storage
-- location, grouped by equipment condition.
-- =========================================================

SELECT
    sl.location_name,
    sl.location_type,
    ea.condition_status,
    COUNT(ea.asset_id) AS asset_count
FROM StorageLocation sl
JOIN EquipmentAsset ea
    ON sl.location_id = ea.location_id
GROUP BY
    sl.location_name,
    sl.location_type,
    ea.condition_status
ORDER BY
    sl.location_name,
    asset_count DESC;


-- =========================================================
-- Query 3:
-- Active assignments by recipient type and equipment type
-- This query shows which equipment types are currently assigned
-- to each recipient type.
-- =========================================================

SELECT
    r.recipient_type,
    et.type_name,
    COUNT(a.assignment_id) AS assignment_count,
    SUM(a.assigned_quantity) AS total_assigned_quantity
FROM EquipmentAssignment a
JOIN Recipient r
    ON a.recipient_id = r.recipient_id
JOIN EquipmentAsset ea
    ON a.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE
    a.assignment_status = $$פעילה$$
GROUP BY
    r.recipient_type,
    et.type_name
ORDER BY
    total_assigned_quantity DESC;


-- =========================================================
-- Query 4:
-- Equipment that has not been returned
-- This query shows active assignments where the equipment has not
-- been returned yet.
-- It uses the return_date field and the assignment date.
-- =========================================================

SELECT
    a.assignment_id,
    ea.asset_id,
    et.type_name,
    r.recipient_type,
    a.assignment_date,
    a.return_date,
    a.assigned_quantity,
    a.assignment_status
FROM EquipmentAssignment a
JOIN EquipmentAsset ea
    ON a.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
JOIN Recipient r
    ON a.recipient_id = r.recipient_id
WHERE
    a.return_date IS NULL
    AND a.assignment_status = $$פעילה$$
ORDER BY
    a.assignment_date;


-- =========================================================
-- Query 5:
-- Assignment summary by year and month
-- This query shows how many assignments were created in each month,
-- and the total quantity assigned in that month.
-- =========================================================

SELECT
    EXTRACT(YEAR FROM a.assignment_date) AS assignment_year,
    EXTRACT(MONTH FROM a.assignment_date) AS assignment_month,
    COUNT(a.assignment_id) AS assignment_count,
    SUM(a.assigned_quantity) AS total_assigned_quantity
FROM EquipmentAssignment a
GROUP BY
    EXTRACT(YEAR FROM a.assignment_date),
    EXTRACT(MONTH FROM a.assignment_date)
ORDER BY
    assignment_year,
    assignment_month;


-- =========================================================
-- Query 6:
-- Stock quantity by storage location and equipment type
-- This query focuses only on stock-managed equipment.
-- It shows the total stock quantity for each storage location
-- and equipment type.
-- =========================================================

SELECT
    sl.location_name,
    sl.location_type,
    et.type_name,
    COUNT(es.asset_id) AS stock_record_count,
    SUM(es.quantity) AS total_quantity,
    ROUND(AVG(es.quantity), 2) AS average_quantity
FROM EquipmentStock es
JOIN EquipmentAsset ea
    ON es.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
JOIN StorageLocation sl
    ON ea.location_id = sl.location_id
GROUP BY
    sl.location_name,
    sl.location_type,
    et.type_name
ORDER BY
    total_quantity DESC;


-- =========================================================
-- Query 7:
-- Serialized equipment by storage location and condition
-- This query focuses only on equipment managed as individual items.
-- It shows how many serialized items exist in each storage location,
-- grouped by condition and availability status.
-- =========================================================

SELECT
    sl.location_name,
    sl.location_type,
    ea.condition_status,
    ea.availability_status,
    COUNT(ei.asset_id) AS serialized_item_count
FROM EquipmentItem ei
JOIN EquipmentAsset ea
    ON ei.asset_id = ea.asset_id
JOIN StorageLocation sl
    ON ea.location_id = sl.location_id
GROUP BY
    sl.location_name,
    sl.location_type,
    ea.condition_status,
    ea.availability_status
ORDER BY
    serialized_item_count DESC;


-- =========================================================
-- Query 8:
-- Most assigned equipment types
-- This query shows which equipment types were assigned the most.
-- Canceled assignments are not included because the purpose is to
-- analyze actual equipment usage.
-- =========================================================

SELECT
    et.type_name,
    COUNT(a.assignment_id) AS assignment_count,
    SUM(a.assigned_quantity) AS total_assigned_quantity,
    MIN(a.assignment_date) AS first_assignment_date,
    MAX(a.assignment_date) AS last_assignment_date
FROM EquipmentAssignment a
JOIN EquipmentAsset ea
    ON a.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE
    a.assignment_status <> $$בוטלה$$
GROUP BY
    et.type_name
ORDER BY
    total_assigned_quantity DESC,
    assignment_count DESC;
