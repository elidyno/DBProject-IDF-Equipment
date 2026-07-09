-- ============================================================
-- validationChecks.sql
-- Phase C - Logical validation checks
-- Each query should return issue_count = 0
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- 1. Core integration layer checks
-- ============================================================

SELECT
    'Soldier without matching MilitaryEntity' AS check_name,
    COUNT(*) AS issue_count
FROM Soldier s
LEFT JOIN MilitaryEntity me
ON s.entity_id = me.entity_id
WHERE me.entity_id IS NULL

UNION ALL

SELECT
    'Soldier entity type is not soldier',
    COUNT(*)
FROM Soldier s
JOIN MilitaryEntity me
ON s.entity_id = me.entity_id
WHERE me.entity_type <> 'חייל'

UNION ALL

SELECT
    'MilitaryUnit without matching MilitaryEntity',
    COUNT(*)
FROM MilitaryUnit mu
LEFT JOIN MilitaryEntity me
ON mu.entity_id = me.entity_id
WHERE me.entity_id IS NULL

UNION ALL

SELECT
    'MilitaryUnit entity type is soldier',
    COUNT(*)
FROM MilitaryUnit mu
JOIN MilitaryEntity me
ON mu.entity_id = me.entity_id
WHERE me.entity_type = 'חייל'

UNION ALL

SELECT
    'Recipient without matching MilitaryEntity',
    COUNT(*)
FROM Recipient r
LEFT JOIN MilitaryEntity me
ON r.entity_id = me.entity_id
WHERE me.entity_id IS NULL

UNION ALL

SELECT
    'Duplicate MilitaryEntity used by more than one Recipient',
    COUNT(*)
FROM (
    SELECT entity_id
    FROM Recipient
    GROUP BY entity_id
    HAVING COUNT(*) > 1
) dup_recipients

UNION ALL

SELECT
    'Recipient type differs from MilitaryEntity type',
    COUNT(*)
FROM Recipient r
JOIN MilitaryEntity me
ON r.entity_id = me.entity_id
WHERE r.recipient_type <> me.entity_type

UNION ALL

SELECT
    'Soldier without valid unit',
    COUNT(*)
FROM Soldier s
LEFT JOIN MilitaryUnit mu
ON s.unit_entity_id = mu.entity_id
WHERE mu.entity_id IS NULL

UNION ALL

SELECT
    'MilitaryUnit commander is not a Soldier',
    COUNT(*)
FROM MilitaryUnit mu
LEFT JOIN Soldier s
ON mu.commander_entity_id = s.entity_id
WHERE mu.commander_entity_id IS NOT NULL
  AND s.entity_id IS NULL

-- ============================================================
-- 2. Logistics system checks
-- ============================================================

UNION ALL

SELECT
    'EquipmentAsset without matching EquipmentType',
    COUNT(*)
FROM EquipmentAsset ea
LEFT JOIN EquipmentType et
ON ea.type_id = et.type_id
WHERE et.type_id IS NULL

UNION ALL

SELECT
    'EquipmentAsset without matching StorageLocation',
    COUNT(*)
FROM EquipmentAsset ea
LEFT JOIN StorageLocation sl
ON ea.location_id = sl.location_id
WHERE sl.location_id IS NULL

UNION ALL

SELECT
    'Serialized equipment asset missing from EquipmentItem',
    COUNT(*)
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
LEFT JOIN EquipmentItem ei
ON ea.asset_id = ei.asset_id
WHERE et.requires_serial_number = TRUE
  AND ei.asset_id IS NULL

UNION ALL

SELECT
    'Non-serialized equipment asset missing from EquipmentStock',
    COUNT(*)
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
LEFT JOIN EquipmentStock es
ON ea.asset_id = es.asset_id
WHERE et.requires_serial_number = FALSE
  AND es.asset_id IS NULL

UNION ALL

SELECT
    'Serialized equipment also appears in EquipmentStock',
    COUNT(*)
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
JOIN EquipmentStock es
ON ea.asset_id = es.asset_id
WHERE et.requires_serial_number = TRUE

UNION ALL

SELECT
    'Stock equipment also appears in EquipmentItem',
    COUNT(*)
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
JOIN EquipmentItem ei
ON ea.asset_id = ei.asset_id
WHERE et.requires_serial_number = FALSE

UNION ALL

SELECT
    'Equipment assignment points to non-existing asset',
    COUNT(*)
FROM EquipmentAssignment assignment
LEFT JOIN EquipmentAsset ea
ON assignment.asset_id = ea.asset_id
WHERE ea.asset_id IS NULL

UNION ALL

SELECT
    'Equipment assignment points to non-existing recipient',
    COUNT(*)
FROM EquipmentAssignment assignment
LEFT JOIN Recipient r
ON assignment.recipient_id = r.recipient_id
WHERE r.recipient_id IS NULL

UNION ALL

SELECT
    'Active equipment assignment for non-valid equipment',
    COUNT(*)
FROM EquipmentAssignment assignment
JOIN EquipmentAsset ea
ON assignment.asset_id = ea.asset_id
WHERE assignment.assignment_status = 'פעילה'
  AND ea.condition_status <> 'תקין'

UNION ALL

SELECT
    'Active equipment assignment with return date',
    COUNT(*)
FROM EquipmentAssignment assignment
WHERE assignment.assignment_status = 'פעילה'
  AND assignment.return_date IS NOT NULL

UNION ALL

SELECT
    'Returned equipment assignment without return date',
    COUNT(*)
FROM EquipmentAssignment assignment
WHERE assignment.assignment_status = 'הוחזרה'
  AND assignment.return_date IS NULL

UNION ALL

SELECT
    'Equipment assignment return date before assignment date',
    COUNT(*)
FROM EquipmentAssignment assignment
WHERE assignment.return_date IS NOT NULL
  AND assignment.return_date < assignment.assignment_date

UNION ALL

SELECT
    'Serialized equipment assignment with quantity different from 1',
    COUNT(*)
FROM EquipmentAssignment assignment
JOIN EquipmentItem ei
ON assignment.asset_id = ei.asset_id
WHERE assignment.assigned_quantity <> 1

UNION ALL

SELECT
    'Active assigned equipment is not marked as allocated',
    COUNT(*)
FROM EquipmentAssignment assignment
JOIN EquipmentAsset ea
ON assignment.asset_id = ea.asset_id
WHERE assignment.assignment_status = 'פעילה'
  AND ea.availability_status <> 'מוקצה'

UNION ALL

SELECT
    'Non-valid equipment is not marked unavailable',
    COUNT(*)
FROM EquipmentAsset ea
WHERE ea.condition_status <> 'תקין'
  AND ea.availability_status <> 'לא זמין'

-- ============================================================
-- 3. Armory system checks
-- ============================================================

UNION ALL

SELECT
    'Weapon without matching WeaponType',
    COUNT(*)
FROM Weapon w
LEFT JOIN WeaponType wt
ON w.type_id = wt.type_id
WHERE wt.type_id IS NULL

UNION ALL

SELECT
    'Weapon without matching WeaponStatus',
    COUNT(*)
FROM Weapon w
LEFT JOIN WeaponStatus ws
ON w.status_id = ws.status_id
WHERE ws.status_id IS NULL

UNION ALL

SELECT
    'Weapon assignment points to non-existing weapon',
    COUNT(*)
FROM WeaponAssignment wa
LEFT JOIN Weapon w
ON wa.serial_number = w.serial_number
WHERE w.serial_number IS NULL

UNION ALL

SELECT
    'Weapon assignment points to non-existing soldier',
    COUNT(*)
FROM WeaponAssignment wa
LEFT JOIN Soldier s
ON wa.soldier_entity_id = s.entity_id
WHERE s.entity_id IS NULL

UNION ALL

SELECT
    'Active weapon assignment with return date',
    COUNT(*)
FROM WeaponAssignment wa
WHERE wa.return_date IS NULL
  AND wa.return_reason IS NOT NULL

UNION ALL

SELECT
    'Weapon assignment return date before assignment date',
    COUNT(*)
FROM WeaponAssignment wa
WHERE wa.return_date IS NOT NULL
  AND wa.return_date < wa.assignment_date

UNION ALL

SELECT
    'Weapon has more than one active assignment',
    COUNT(*)
FROM (
    SELECT serial_number
    FROM WeaponAssignment
    WHERE return_date IS NULL
    GROUP BY serial_number
    HAVING COUNT(*) > 1
) active_weapon_duplicates

UNION ALL

SELECT
    'Active assigned weapon is not marked as allocated',
    COUNT(*)
FROM WeaponAssignment wa
JOIN Weapon w
ON wa.serial_number = w.serial_number
WHERE wa.return_date IS NULL
  AND w.status_id <> 2

UNION ALL

SELECT
    'Allocated weapon without active assignment',
    COUNT(*)
FROM Weapon w
LEFT JOIN WeaponAssignment wa
ON w.serial_number = wa.serial_number
AND wa.return_date IS NULL
WHERE w.status_id = 2
  AND wa.assignment_id IS NULL

UNION ALL

SELECT
    'Maintenance points to active assigned weapon',
    COUNT(*)
FROM Maintenance m
JOIN WeaponAssignment wa
ON m.serial_number = wa.serial_number
WHERE wa.return_date IS NULL

UNION ALL

SELECT
    'Maintenance points to non-existing weapon',
    COUNT(*)
FROM Maintenance m
LEFT JOIN Weapon w
ON m.serial_number = w.serial_number
WHERE w.serial_number IS NULL

UNION ALL

SELECT
    'Maintenance technician is not a soldier',
    COUNT(*)
FROM Maintenance m
LEFT JOIN Soldier s
ON m.technician_entity_id = s.entity_id
WHERE s.entity_id IS NULL

UNION ALL

SELECT
    'Maintenance points to non-existing maintenance type',
    COUNT(*)
FROM Maintenance m
LEFT JOIN MaintenanceType mt
ON m.maint_type_id = mt.maint_type_id
WHERE mt.maint_type_id IS NULL

UNION ALL

SELECT
    'Ammo issue points to non-existing ammunition',
    COUNT(*)
FROM AmmoIssue ai
LEFT JOIN Ammunition a
ON ai.ammo_id = a.ammo_id
WHERE a.ammo_id IS NULL

UNION ALL

SELECT
    'Ammo issue points to non-existing soldier',
    COUNT(*)
FROM AmmoIssue ai
LEFT JOIN Soldier s
ON ai.soldier_entity_id = s.entity_id
WHERE s.entity_id IS NULL

UNION ALL

SELECT
    'Ammunition without matching AmmoType',
    COUNT(*)
FROM Ammunition a
LEFT JOIN AmmoType at
ON a.ammo_type_id = at.ammo_type_id
WHERE at.ammo_type_id IS NULL

UNION ALL

SELECT
    'Ammunition stock below minimum stock',
    COUNT(*)
FROM Ammunition a
WHERE a.stock_quantity < a.minimum_stock

ORDER BY check_name;