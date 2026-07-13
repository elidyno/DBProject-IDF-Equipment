-- ============================================================
-- selectAll.sql
-- Phase D refactor - Data overview for the integrated database
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- 1. Row count for all tables
-- ============================================================

SELECT 'AmmoIssue' AS table_name, COUNT(*) AS row_count FROM AmmoIssue
UNION ALL
SELECT 'AmmoType', COUNT(*) FROM AmmoType
UNION ALL
SELECT 'Ammunition', COUNT(*) FROM Ammunition
UNION ALL
SELECT 'CategoryType', COUNT(*) FROM CategoryType
UNION ALL
SELECT 'EquipmentAsset', COUNT(*) FROM EquipmentAsset
UNION ALL
SELECT 'EquipmentAssignment', COUNT(*) FROM EquipmentAssignment
UNION ALL
SELECT 'EquipmentCategory', COUNT(*) FROM EquipmentCategory
UNION ALL
SELECT 'EquipmentItem', COUNT(*) FROM EquipmentItem
UNION ALL
SELECT 'EquipmentStock', COUNT(*) FROM EquipmentStock
UNION ALL
SELECT 'EquipmentType', COUNT(*) FROM EquipmentType
UNION ALL
SELECT 'Maintenance', COUNT(*) FROM Maintenance
UNION ALL
SELECT 'MaintenanceType', COUNT(*) FROM MaintenanceType
UNION ALL
SELECT 'MilitaryEntity', COUNT(*) FROM MilitaryEntity
UNION ALL
SELECT 'MilitaryUnit', COUNT(*) FROM MilitaryUnit
UNION ALL
SELECT 'Rank', COUNT(*) FROM Rank
UNION ALL
SELECT 'Recipient', COUNT(*) FROM Recipient
UNION ALL
SELECT 'Soldier', COUNT(*) FROM Soldier
UNION ALL
SELECT 'StorageLocation', COUNT(*) FROM StorageLocation
UNION ALL
SELECT 'Weapon', COUNT(*) FROM Weapon
UNION ALL
SELECT 'WeaponAssignment', COUNT(*) FROM WeaponAssignment
UNION ALL
SELECT 'WeaponStatus', COUNT(*) FROM WeaponStatus
UNION ALL
SELECT 'WeaponType', COUNT(*) FROM WeaponType
ORDER BY table_name;

-- ============================================================
-- 2. Integrated military entities overview
-- ============================================================

SELECT
    me.entity_id,
    CASE
        WHEN s.entity_id IS NOT NULL THEN 'Soldier'
        WHEN mu.entity_id IS NOT NULL THEN 'MilitaryUnit'
        ELSE 'Unknown'
    END AS entity_real_group,
    COALESCE(
        s.first_name || ' ' || s.last_name,
        mu.unit_name
    ) AS entity_display_name,
    mu.unit_level,
    mu.company
FROM MilitaryEntity me
LEFT JOIN Soldier s
    ON me.entity_id = s.entity_id
LEFT JOIN MilitaryUnit mu
    ON me.entity_id = mu.entity_id
ORDER BY
    me.entity_id
LIMIT 40;

-- ============================================================
-- 3. Soldiers with rank and unit
-- ============================================================

SELECT
    s.entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    r.rank_name,
    s.enlistment_date,
    s.phone,
    mu.unit_name,
    mu.unit_level
FROM Soldier s
JOIN Rank r
    ON s.rank_id = r.rank_id
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
ORDER BY
    s.entity_id
LIMIT 40;

-- ============================================================
-- 4. Military units with commanders
-- ============================================================

SELECT
    mu.entity_id,
    mu.unit_id,
    mu.unit_name,
    mu.unit_level,
    mu.company,
    commander.soldier_id AS commander_soldier_id,
    commander.first_name || ' ' || commander.last_name AS commander_name
FROM MilitaryUnit mu
LEFT JOIN Soldier commander
    ON mu.commander_entity_id = commander.entity_id
ORDER BY
    mu.entity_id
LIMIT 50;

-- ============================================================
-- 5. Recipients with derived real type and name
-- ============================================================

SELECT
    r.recipient_id,
    r.entity_id,
    CASE
        WHEN s.entity_id IS NOT NULL THEN 'Soldier'
        WHEN mu.entity_id IS NOT NULL THEN 'MilitaryUnit'
        ELSE 'Unknown'
    END AS recipient_real_group,
    COALESCE(
        s.first_name || ' ' || s.last_name,
        mu.unit_name
    ) AS recipient_name,
    mu.unit_level
FROM Recipient r
LEFT JOIN Soldier s
    ON r.entity_id = s.entity_id
LEFT JOIN MilitaryUnit mu
    ON r.entity_id = mu.entity_id
ORDER BY
    r.recipient_id
LIMIT 60;

-- ============================================================
-- 6. Equipment categories and equipment types
-- ============================================================

SELECT
    ec.category_name,
    et.type_name,
    et.requires_serial_number
FROM CategoryType ct
JOIN EquipmentCategory ec
    ON ct.category_id = ec.category_id
JOIN EquipmentType et
    ON ct.type_id = et.type_id
ORDER BY
    ec.category_name,
    et.type_name;

-- ============================================================
-- 7. Equipment assets with type and storage location
-- ============================================================

SELECT
    ea.asset_id,
    et.type_name,
    et.requires_serial_number,
    sl.location_name,
    sl.location_type,
    ea.condition_status,
    ea.availability_status,
    ea.intake_date
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
JOIN StorageLocation sl
    ON ea.location_id = sl.location_id
ORDER BY
    ea.asset_id
LIMIT 60;

-- ============================================================
-- 8. Serialized equipment items
-- ============================================================

SELECT
    ei.asset_id,
    ei.serial_number,
    et.type_name,
    ea.condition_status,
    ea.availability_status
FROM EquipmentItem ei
JOIN EquipmentAsset ea
    ON ei.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
ORDER BY
    ei.asset_id
LIMIT 60;

-- ============================================================
-- 9. Stock-based equipment assets
-- ============================================================

SELECT
    es.asset_id,
    et.type_name,
    es.quantity,
    ea.condition_status,
    ea.availability_status
FROM EquipmentStock es
JOIN EquipmentAsset ea
    ON es.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
ORDER BY
    es.asset_id
LIMIT 60;

-- ============================================================
-- 10. Equipment assignments with derived recipient details
-- ============================================================

SELECT
    ea.assignment_id,
    ea.asset_id,
    et.type_name AS equipment_type_name,
    ea.assigned_quantity,
    ea.assignment_date,
    ea.return_date,
    ea.assignment_status,
    r.recipient_id,
    CASE
        WHEN s.entity_id IS NOT NULL THEN 'Soldier'
        WHEN mu.entity_id IS NOT NULL THEN 'MilitaryUnit'
        ELSE 'Unknown'
    END AS recipient_real_group,
    COALESCE(
        s.first_name || ' ' || s.last_name,
        mu.unit_name
    ) AS recipient_name,
    mu.unit_level
FROM EquipmentAssignment ea
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
JOIN EquipmentType et
    ON asset.type_id = et.type_id
JOIN Recipient r
    ON ea.recipient_id = r.recipient_id
LEFT JOIN Soldier s
    ON r.entity_id = s.entity_id
LEFT JOIN MilitaryUnit mu
    ON r.entity_id = mu.entity_id
ORDER BY
    ea.assignment_id
LIMIT 80;

-- ============================================================
-- 11. Weapons with type and status
-- ============================================================

SELECT
    w.serial_number,
    wt.type_name AS weapon_type_name,
    ws.status_name AS weapon_status_name,
    w.model,
    w.manufacture_year,
    w.entry_date
FROM Weapon w
JOIN WeaponType wt
    ON w.type_id = wt.type_id
JOIN WeaponStatus ws
    ON w.status_id = ws.status_id
ORDER BY
    w.serial_number
LIMIT 60;

-- ============================================================
-- 12. Weapon assignments with soldier and unit
-- ============================================================

SELECT
    wa.assignment_id,
    wa.serial_number,
    wt.type_name AS weapon_type_name,
    s.soldier_id,
    s.first_name,
    s.last_name,
    mu.unit_name,
    wa.assignment_date,
    wa.return_date,
    wa.return_reason
FROM WeaponAssignment wa
JOIN Weapon w
    ON wa.serial_number = w.serial_number
JOIN WeaponType wt
    ON w.type_id = wt.type_id
JOIN Soldier s
    ON wa.soldier_entity_id = s.entity_id
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
ORDER BY
    wa.assignment_id
LIMIT 80;

-- ============================================================
-- 13. Ammunition inventory
-- ============================================================

SELECT
    a.ammo_id,
    at.type_name AS ammo_type_name,
    a.caliber,
    a.stock_quantity,
    a.minimum_stock
FROM Ammunition a
JOIN AmmoType at
    ON a.ammo_type_id = at.ammo_type_id
ORDER BY
    a.ammo_id;

-- ============================================================
-- 14. Ammunition issues with soldier and unit
-- ============================================================

SELECT
    ai.issue_id,
    at.type_name AS ammo_type_name,
    a.caliber,
    ai.quantity,
    ai.issue_date,
    ai.purpose,
    s.soldier_id,
    s.first_name,
    s.last_name,
    mu.unit_name
FROM AmmoIssue ai
JOIN Ammunition a
    ON ai.ammo_id = a.ammo_id
JOIN AmmoType at
    ON a.ammo_type_id = at.ammo_type_id
JOIN Soldier s
    ON ai.soldier_entity_id = s.entity_id
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
ORDER BY
    ai.issue_id
LIMIT 80;

-- ============================================================
-- 15. Maintenance actions with technician, weapon, and maintenance type
-- ============================================================

SELECT
    m.maintenance_id,
    m.serial_number,
    wt.type_name AS weapon_type_name,
    mt.type_name AS maintenance_type_name,
    m.maintenance_date,
    m.status_after,
    tech.soldier_id AS technician_soldier_id,
    tech.first_name AS technician_first_name,
    tech.last_name AS technician_last_name,
    tech_unit.unit_name AS technician_unit_name
FROM Maintenance m
JOIN Weapon w
    ON m.serial_number = w.serial_number
JOIN WeaponType wt
    ON w.type_id = wt.type_id
JOIN MaintenanceType mt
    ON m.maint_type_id = mt.maint_type_id
JOIN Soldier tech
    ON m.technician_entity_id = tech.entity_id
JOIN MilitaryUnit tech_unit
    ON tech.unit_entity_id = tech_unit.entity_id
ORDER BY
    m.maintenance_id
LIMIT 80;