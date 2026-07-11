-- ============================================================
-- selectAll.sql
-- Phase C - Basic data checks for the integrated database
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- 1. Row counts for all tables
-- ============================================================

SELECT 'MilitaryEntity' AS table_name, COUNT(*) AS row_count FROM MilitaryEntity
UNION ALL
SELECT 'Rank', COUNT(*) FROM Rank
UNION ALL
SELECT 'MilitaryUnit', COUNT(*) FROM MilitaryUnit
UNION ALL
SELECT 'Soldier', COUNT(*) FROM Soldier
UNION ALL
SELECT 'EquipmentCategory', COUNT(*) FROM EquipmentCategory
UNION ALL
SELECT 'EquipmentType', COUNT(*) FROM EquipmentType
UNION ALL
SELECT 'CategoryType', COUNT(*) FROM CategoryType
UNION ALL
SELECT 'StorageLocation', COUNT(*) FROM StorageLocation
UNION ALL
SELECT 'EquipmentAsset', COUNT(*) FROM EquipmentAsset
UNION ALL
SELECT 'EquipmentItem', COUNT(*) FROM EquipmentItem
UNION ALL
SELECT 'EquipmentStock', COUNT(*) FROM EquipmentStock
UNION ALL
SELECT 'Recipient', COUNT(*) FROM Recipient
UNION ALL
SELECT 'EquipmentAssignment', COUNT(*) FROM EquipmentAssignment
UNION ALL
SELECT 'WeaponType', COUNT(*) FROM WeaponType
UNION ALL
SELECT 'WeaponStatus', COUNT(*) FROM WeaponStatus
UNION ALL
SELECT 'Weapon', COUNT(*) FROM Weapon
UNION ALL
SELECT 'WeaponAssignment', COUNT(*) FROM WeaponAssignment
UNION ALL
SELECT 'AmmoType', COUNT(*) FROM AmmoType
UNION ALL
SELECT 'Ammunition', COUNT(*) FROM Ammunition
UNION ALL
SELECT 'AmmoIssue', COUNT(*) FROM AmmoIssue
UNION ALL
SELECT 'MaintenanceType', COUNT(*) FROM MaintenanceType
UNION ALL
SELECT 'Maintenance', COUNT(*) FROM Maintenance
ORDER BY table_name;

-- ============================================================
-- 2. Core integration layer samples
-- ============================================================

SELECT *
FROM MilitaryEntity
ORDER BY entity_id
LIMIT 20;

SELECT *
FROM Rank
ORDER BY rank_id;

SELECT
    mu.entity_id,
    me.entity_name AS unit_entity_name,
    mu.unit_id,
    mu.unit_name,
    mu.company,
    mu.commander_entity_id,
    commander.first_name AS commander_first_name,
    commander.last_name AS commander_last_name
FROM MilitaryUnit mu
JOIN MilitaryEntity me
ON mu.entity_id = me.entity_id
LEFT JOIN Soldier commander
ON mu.commander_entity_id = commander.entity_id
ORDER BY mu.entity_id
LIMIT 20;

SELECT
    s.entity_id,
    me.entity_name,
    s.soldier_id,
    s.first_name,
    s.last_name,
    r.rank_name,
    unit_me.entity_name AS unit_name,
    s.enlistment_date,
    s.phone
FROM Soldier s
JOIN MilitaryEntity me
ON s.entity_id = me.entity_id
JOIN Rank r
ON s.rank_id = r.rank_id
JOIN MilitaryUnit mu
ON s.unit_entity_id = mu.entity_id
JOIN MilitaryEntity unit_me
ON mu.entity_id = unit_me.entity_id
ORDER BY s.entity_id
LIMIT 20;

-- ============================================================
-- 3. Logistics system samples
-- ============================================================

SELECT *
FROM EquipmentCategory
ORDER BY category_id;

SELECT *
FROM EquipmentType
ORDER BY type_id;

SELECT
    ec.category_name,
    et.type_name,
    et.requires_serial_number
FROM CategoryType ct
JOIN EquipmentCategory ec
ON ct.category_id = ec.category_id
JOIN EquipmentType et
ON ct.type_id = et.type_id
ORDER BY ec.category_name, et.type_name;

SELECT *
FROM StorageLocation
ORDER BY location_id;

SELECT
    ea.asset_id,
    et.type_name,
    sl.location_name,
    ea.condition_status,
    ea.intake_date,
    ea.availability_status
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
JOIN StorageLocation sl
ON ea.location_id = sl.location_id
ORDER BY ea.asset_id
LIMIT 30;

SELECT
    ei.asset_id,
    et.type_name,
    ei.serial_number,
    ea.condition_status,
    ea.availability_status
FROM EquipmentItem ei
JOIN EquipmentAsset ea
ON ei.asset_id = ea.asset_id
JOIN EquipmentType et
ON ea.type_id = et.type_id
ORDER BY ei.asset_id
LIMIT 20;

SELECT
    es.asset_id,
    et.type_name,
    es.quantity,
    sl.location_name
FROM EquipmentStock es
JOIN EquipmentAsset ea
ON es.asset_id = ea.asset_id
JOIN EquipmentType et
ON ea.type_id = et.type_id
JOIN StorageLocation sl
ON ea.location_id = sl.location_id
ORDER BY es.asset_id
LIMIT 20;

SELECT
    r.recipient_id,
    r.recipient_type,
    r.entity_id,
    me.entity_name
FROM Recipient r
JOIN MilitaryEntity me
ON r.entity_id = me.entity_id
ORDER BY r.recipient_id
LIMIT 30;

SELECT
    ea.assignment_id,
    et.type_name,
    r.recipient_type,
    me.entity_name AS recipient_name,
    ea.assignment_date,
    ea.return_date,
    ea.assigned_quantity,
    ea.assignment_status
FROM EquipmentAssignment ea
JOIN EquipmentAsset asset
ON ea.asset_id = asset.asset_id
JOIN EquipmentType et
ON asset.type_id = et.type_id
JOIN Recipient r
ON ea.recipient_id = r.recipient_id
JOIN MilitaryEntity me
ON r.entity_id = me.entity_id
ORDER BY ea.assignment_id
LIMIT 30;

-- ============================================================
-- 4. Armory system samples
-- ============================================================

SELECT *
FROM WeaponType
ORDER BY type_id;

SELECT *
FROM WeaponStatus
ORDER BY status_id;

SELECT
    w.serial_number,
    wt.type_name,
    ws.status_name,
    w.model,
    w.manufacture_year,
    w.entry_date
FROM Weapon w
JOIN WeaponType wt
ON w.type_id = wt.type_id
JOIN WeaponStatus ws
ON w.status_id = ws.status_id
ORDER BY w.serial_number
LIMIT 30;

SELECT
    wa.assignment_id,
    wa.serial_number,
    wt.type_name,
    s.soldier_id,
    s.first_name,
    s.last_name,
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
ORDER BY wa.assignment_id
LIMIT 30;

SELECT *
FROM AmmoType
ORDER BY ammo_type_id;

SELECT
    a.ammo_id,
    at.type_name,
    a.caliber,
    a.stock_quantity,
    a.minimum_stock
FROM Ammunition a
JOIN AmmoType at
ON a.ammo_type_id = at.ammo_type_id
ORDER BY a.ammo_id;

SELECT
    ai.issue_id,
    at.type_name AS ammo_type,
    a.caliber,
    s.soldier_id,
    s.first_name,
    s.last_name,
    ai.quantity,
    ai.issue_date,
    ai.purpose
FROM AmmoIssue ai
JOIN Ammunition a
ON ai.ammo_id = a.ammo_id
JOIN AmmoType at
ON a.ammo_type_id = at.ammo_type_id
JOIN Soldier s
ON ai.soldier_entity_id = s.entity_id
ORDER BY ai.issue_id
LIMIT 30;

SELECT *
FROM MaintenanceType
ORDER BY maint_type_id;

SELECT
    m.maintenance_id,
    m.serial_number,
    wt.type_name AS weapon_type,
    s.soldier_id AS technician_soldier_id,
    s.first_name AS technician_first_name,
    s.last_name AS technician_last_name,
    mt.type_name AS maintenance_type,
    m.maintenance_date,
    m.description,
    m.status_after
FROM Maintenance m
JOIN Weapon w
ON m.serial_number = w.serial_number
JOIN WeaponType wt
ON w.type_id = wt.type_id
JOIN Soldier s
ON m.technician_entity_id = s.entity_id
JOIN MaintenanceType mt
ON m.maint_type_id = mt.maint_type_id
ORDER BY m.maintenance_id
LIMIT 30;