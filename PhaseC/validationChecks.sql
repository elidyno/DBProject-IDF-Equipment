-- ============================================================
-- validationChecks.sql
-- Phase D refactor - Data consistency checks
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- 1. Integration layer checks
-- ============================================================

SELECT
    'Soldier without MilitaryEntity' AS check_name,
    COUNT(*) AS issue_count
FROM Soldier s
LEFT JOIN MilitaryEntity me
    ON s.entity_id = me.entity_id
WHERE me.entity_id IS NULL

UNION ALL

SELECT
    'MilitaryUnit without MilitaryEntity' AS check_name,
    COUNT(*) AS issue_count
FROM MilitaryUnit mu
LEFT JOIN MilitaryEntity me
    ON mu.entity_id = me.entity_id
WHERE me.entity_id IS NULL

UNION ALL

SELECT
    'MilitaryEntity that is neither Soldier nor MilitaryUnit' AS check_name,
    COUNT(*) AS issue_count
FROM MilitaryEntity me
LEFT JOIN Soldier s
    ON me.entity_id = s.entity_id
LEFT JOIN MilitaryUnit mu
    ON me.entity_id = mu.entity_id
WHERE s.entity_id IS NULL
  AND mu.entity_id IS NULL

UNION ALL

SELECT
    'MilitaryEntity that is both Soldier and MilitaryUnit' AS check_name,
    COUNT(*) AS issue_count
FROM MilitaryEntity me
JOIN Soldier s
    ON me.entity_id = s.entity_id
JOIN MilitaryUnit mu
    ON me.entity_id = mu.entity_id

UNION ALL

SELECT
    'Soldier assigned to missing MilitaryUnit' AS check_name,
    COUNT(*) AS issue_count
FROM Soldier s
LEFT JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
WHERE mu.entity_id IS NULL

UNION ALL

SELECT
    'MilitaryUnit commander is not a Soldier' AS check_name,
    COUNT(*) AS issue_count
FROM MilitaryUnit mu
LEFT JOIN Soldier commander
    ON mu.commander_entity_id = commander.entity_id
WHERE mu.commander_entity_id IS NOT NULL
  AND commander.entity_id IS NULL;

-- ============================================================
-- 2. Recipient checks after refactor
-- ============================================================

SELECT
    'Recipient without MilitaryEntity' AS check_name,
    COUNT(*) AS issue_count
FROM Recipient r
LEFT JOIN MilitaryEntity me
    ON r.entity_id = me.entity_id
WHERE me.entity_id IS NULL

UNION ALL

SELECT
    'Recipient entity is neither Soldier nor MilitaryUnit' AS check_name,
    COUNT(*) AS issue_count
FROM Recipient r
LEFT JOIN Soldier s
    ON r.entity_id = s.entity_id
LEFT JOIN MilitaryUnit mu
    ON r.entity_id = mu.entity_id
WHERE s.entity_id IS NULL
  AND mu.entity_id IS NULL

UNION ALL

SELECT
    'Recipient entity is both Soldier and MilitaryUnit' AS check_name,
    COUNT(*) AS issue_count
FROM Recipient r
JOIN Soldier s
    ON r.entity_id = s.entity_id
JOIN MilitaryUnit mu
    ON r.entity_id = mu.entity_id

UNION ALL

SELECT
    'Duplicate Recipient for same MilitaryEntity' AS check_name,
    COUNT(*) AS issue_count
FROM (
    SELECT
        entity_id
    FROM Recipient
    GROUP BY
        entity_id
    HAVING COUNT(*) > 1
) duplicate_recipients;

-- ============================================================
-- 3. Equipment structure checks
-- ============================================================

SELECT
    'Serialized equipment asset without EquipmentItem row' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
LEFT JOIN EquipmentItem ei
    ON ea.asset_id = ei.asset_id
WHERE et.requires_serial_number = TRUE
  AND ei.asset_id IS NULL

UNION ALL

SELECT
    'Stock equipment asset without EquipmentStock row' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
LEFT JOIN EquipmentStock es
    ON ea.asset_id = es.asset_id
WHERE et.requires_serial_number = FALSE
  AND es.asset_id IS NULL

UNION ALL

SELECT
    'Serialized equipment asset also appears in EquipmentStock' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
JOIN EquipmentStock es
    ON ea.asset_id = es.asset_id
WHERE et.requires_serial_number = TRUE

UNION ALL

SELECT
    'Stock equipment asset also appears in EquipmentItem' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
JOIN EquipmentItem ei
    ON ea.asset_id = ei.asset_id
WHERE et.requires_serial_number = FALSE;

-- ============================================================
-- 4. Equipment assignment checks
-- ============================================================

SELECT
    'Serialized equipment assignment quantity is not 1' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
JOIN EquipmentType et
    ON asset.type_id = et.type_id
WHERE et.requires_serial_number = TRUE
  AND ea.assigned_quantity <> 1

UNION ALL

SELECT
    'Active equipment assignment for non-valid equipment condition' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
WHERE ea.assignment_status = 'פעילה'
  AND asset.condition_status <> 'תקין'

UNION ALL

SELECT
    'Active equipment assignment but asset is not marked allocated' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
WHERE ea.assignment_status = 'פעילה'
  AND asset.availability_status <> 'מוקצה'

UNION ALL

SELECT
    'Available asset has active equipment assignment' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAsset asset
JOIN EquipmentAssignment ea
    ON asset.asset_id = ea.asset_id
WHERE asset.availability_status = 'זמין'
  AND ea.assignment_status = 'פעילה'

UNION ALL

SELECT
    'Returned equipment assignment without return date' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
WHERE ea.assignment_status = 'הוחזרה'
  AND ea.return_date IS NULL

UNION ALL

SELECT
    'Active equipment assignment with return date' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
WHERE ea.assignment_status = 'פעילה'
  AND ea.return_date IS NOT NULL

UNION ALL

SELECT
    'Canceled equipment assignment with return date' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
WHERE ea.assignment_status = 'בוטלה'
  AND ea.return_date IS NOT NULL

UNION ALL

SELECT
    'Equipment assignment quantity exceeds stock quantity' AS check_name,
    COUNT(*) AS issue_count
FROM EquipmentAssignment ea
JOIN EquipmentStock es
    ON ea.asset_id = es.asset_id
WHERE ea.assigned_quantity > es.quantity;

-- ============================================================
-- 5. Weapon assignment checks
-- ============================================================

SELECT
    'Weapon with more than one active assignment' AS check_name,
    COUNT(*) AS issue_count
FROM (
    SELECT
        serial_number
    FROM WeaponAssignment
    WHERE return_date IS NULL
    GROUP BY
        serial_number
    HAVING COUNT(*) > 1
) active_weapon_duplicates

UNION ALL

SELECT
    'Active weapon assignment but weapon status is not allocated' AS check_name,
    COUNT(*) AS issue_count
FROM WeaponAssignment wa
JOIN Weapon w
    ON wa.serial_number = w.serial_number
JOIN WeaponStatus ws
    ON w.status_id = ws.status_id
WHERE wa.return_date IS NULL
  AND ws.status_name <> 'מוקצה'

UNION ALL

SELECT
    'Weapon marked allocated without active assignment' AS check_name,
    COUNT(*) AS issue_count
FROM Weapon w
JOIN WeaponStatus ws
    ON w.status_id = ws.status_id
LEFT JOIN WeaponAssignment wa
    ON w.serial_number = wa.serial_number
   AND wa.return_date IS NULL
WHERE ws.status_name = 'מוקצה'
  AND wa.assignment_id IS NULL

UNION ALL

SELECT
    'Returned weapon assignment without return reason' AS check_name,
    COUNT(*) AS issue_count
FROM WeaponAssignment wa
WHERE wa.return_date IS NOT NULL
  AND wa.return_reason IS NULL

UNION ALL

SELECT
    'Active weapon assignment with return reason' AS check_name,
    COUNT(*) AS issue_count
FROM WeaponAssignment wa
WHERE wa.return_date IS NULL
  AND wa.return_reason IS NOT NULL;

-- ============================================================
-- 6. Ammunition checks
-- ============================================================

SELECT
    'Ammunition stock below minimum stock' AS check_name,
    COUNT(*) AS issue_count
FROM Ammunition a
WHERE a.stock_quantity < a.minimum_stock

UNION ALL

SELECT
    'AmmoIssue points to missing Soldier' AS check_name,
    COUNT(*) AS issue_count
FROM AmmoIssue ai
LEFT JOIN Soldier s
    ON ai.soldier_entity_id = s.entity_id
WHERE s.entity_id IS NULL

UNION ALL

SELECT
    'AmmoIssue points to missing Ammunition row' AS check_name,
    COUNT(*) AS issue_count
FROM AmmoIssue ai
LEFT JOIN Ammunition a
    ON ai.ammo_id = a.ammo_id
WHERE a.ammo_id IS NULL;

-- ============================================================
-- 7. Maintenance checks
-- ============================================================

SELECT
    'Maintenance points to missing Weapon' AS check_name,
    COUNT(*) AS issue_count
FROM Maintenance m
LEFT JOIN Weapon w
    ON m.serial_number = w.serial_number
WHERE w.serial_number IS NULL

UNION ALL

SELECT
    'Maintenance technician is not a Soldier' AS check_name,
    COUNT(*) AS issue_count
FROM Maintenance m
LEFT JOIN Soldier s
    ON m.technician_entity_id = s.entity_id
WHERE s.entity_id IS NULL

UNION ALL

SELECT
    'Maintenance action on currently assigned weapon' AS check_name,
    COUNT(*) AS issue_count
FROM Maintenance m
JOIN WeaponAssignment wa
    ON m.serial_number = wa.serial_number
WHERE wa.return_date IS NULL

UNION ALL

SELECT
    'Maintenance points to missing MaintenanceType' AS check_name,
    COUNT(*) AS issue_count
FROM Maintenance m
LEFT JOIN MaintenanceType mt
    ON m.maint_type_id = mt.maint_type_id
WHERE mt.maint_type_id IS NULL;