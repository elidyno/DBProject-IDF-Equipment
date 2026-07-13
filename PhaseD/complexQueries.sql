-- ============================================================
-- complexQueries.sql
-- Phase D refactor - Complex queries on the integrated database
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- Query D1:
-- Active equipment assignments by real recipient group and equipment type.
-- Recipient type and name are derived from Soldier / MilitaryUnit,
-- not from duplicated text fields.
-- ============================================================

SELECT
    CASE
        WHEN recipient_soldier.entity_id IS NOT NULL THEN 'Soldier'
        WHEN recipient_unit.entity_id IS NOT NULL THEN 'MilitaryUnit'
        ELSE 'Unknown'
    END AS recipient_real_group,
    COALESCE(
        recipient_soldier.first_name || ' ' || recipient_soldier.last_name,
        recipient_unit.unit_name
    ) AS recipient_name,
    recipient_unit.unit_level AS recipient_unit_level,
    COALESCE(soldier_unit.unit_name, 'Not a soldier recipient') AS soldier_unit_name,
    et.type_name AS equipment_type_name,
    COUNT(ea.assignment_id) AS active_assignment_count,
    SUM(ea.assigned_quantity) AS total_assigned_quantity
FROM EquipmentAssignment ea
JOIN Recipient r
    ON ea.recipient_id = r.recipient_id
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
JOIN EquipmentType et
    ON asset.type_id = et.type_id
LEFT JOIN Soldier recipient_soldier
    ON r.entity_id = recipient_soldier.entity_id
LEFT JOIN MilitaryUnit recipient_unit
    ON r.entity_id = recipient_unit.entity_id
LEFT JOIN MilitaryUnit soldier_unit
    ON recipient_soldier.unit_entity_id = soldier_unit.entity_id
WHERE ea.assignment_status = 'פעילה'
GROUP BY
    recipient_soldier.entity_id,
    recipient_soldier.first_name,
    recipient_soldier.last_name,
    recipient_unit.entity_id,
    recipient_unit.unit_name,
    recipient_unit.unit_level,
    soldier_unit.unit_name,
    et.type_name
ORDER BY
    total_assigned_quantity DESC,
    active_assignment_count DESC;

-- ============================================================
-- Query D2:
-- Monthly activity across the integrated database:
-- equipment assignments, weapon assignments, and ammunition issues.
-- ============================================================

WITH monthly_activity AS (
    SELECT
        DATE_TRUNC('month', ea.assignment_date)::DATE AS activity_month,
        'Equipment Assignment' AS activity_type,
        COUNT(ea.assignment_id) AS event_count,
        SUM(ea.assigned_quantity) AS quantity_count
    FROM EquipmentAssignment ea
    WHERE ea.assignment_status <> 'בוטלה'
    GROUP BY
        DATE_TRUNC('month', ea.assignment_date)::DATE

    UNION ALL

    SELECT
        DATE_TRUNC('month', wa.assignment_date)::DATE AS activity_month,
        'Weapon Assignment' AS activity_type,
        COUNT(wa.assignment_id) AS event_count,
        COUNT(wa.assignment_id) AS quantity_count
    FROM WeaponAssignment wa
    GROUP BY
        DATE_TRUNC('month', wa.assignment_date)::DATE

    UNION ALL

    SELECT
        DATE_TRUNC('month', ai.issue_date)::DATE AS activity_month,
        'Ammo Issue' AS activity_type,
        COUNT(ai.issue_id) AS event_count,
        SUM(ai.quantity) AS quantity_count
    FROM AmmoIssue ai
    GROUP BY
        DATE_TRUNC('month', ai.issue_date)::DATE
)
SELECT
    activity_month,
    SUM(CASE WHEN activity_type = 'Equipment Assignment' THEN event_count ELSE 0 END) AS equipment_assignment_count,
    SUM(CASE WHEN activity_type = 'Equipment Assignment' THEN quantity_count ELSE 0 END) AS equipment_quantity,
    SUM(CASE WHEN activity_type = 'Weapon Assignment' THEN event_count ELSE 0 END) AS weapon_assignment_count,
    SUM(CASE WHEN activity_type = 'Ammo Issue' THEN event_count ELSE 0 END) AS ammo_issue_count,
    SUM(CASE WHEN activity_type = 'Ammo Issue' THEN quantity_count ELSE 0 END) AS ammo_quantity
FROM monthly_activity
GROUP BY
    activity_month
ORDER BY
    activity_month;

-- ============================================================
-- Query D3:
-- Soldiers who currently have both active logistics equipment
-- and an active weapon assignment.
-- ============================================================

WITH active_soldier_equipment AS (
    SELECT
        s.entity_id AS soldier_entity_id,
        COUNT(DISTINCT ea.assignment_id) AS active_equipment_assignment_count,
        SUM(ea.assigned_quantity) AS active_equipment_quantity
    FROM Soldier s
    JOIN Recipient r
        ON s.entity_id = r.entity_id
    JOIN EquipmentAssignment ea
        ON r.recipient_id = ea.recipient_id
    WHERE ea.assignment_status = 'פעילה'
    GROUP BY
        s.entity_id
),
active_soldier_weapons AS (
    SELECT
        wa.soldier_entity_id,
        COUNT(DISTINCT wa.assignment_id) AS active_weapon_count
    FROM WeaponAssignment wa
    WHERE wa.return_date IS NULL
    GROUP BY
        wa.soldier_entity_id
)
SELECT
    s.entity_id AS soldier_entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    rk.rank_name,
    mu.unit_name,
    mu.unit_level,
    ase.active_equipment_assignment_count,
    ase.active_equipment_quantity,
    asw.active_weapon_count
FROM Soldier s
JOIN Rank rk
    ON s.rank_id = rk.rank_id
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
JOIN active_soldier_equipment ase
    ON s.entity_id = ase.soldier_entity_id
JOIN active_soldier_weapons asw
    ON s.entity_id = asw.soldier_entity_id
ORDER BY
    ase.active_equipment_quantity DESC,
    asw.active_weapon_count DESC,
    s.entity_id;

-- ============================================================
-- Query D4:
-- Soldiers who received ammunition but do not currently have
-- an active weapon assignment.
-- ============================================================

SELECT
    s.entity_id AS soldier_entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    rk.rank_name,
    mu.unit_name,
    mu.unit_level,
    COUNT(ai.issue_id) AS ammo_issue_count,
    SUM(ai.quantity) AS total_ammo_quantity,
    MAX(ai.issue_date) AS last_ammo_issue_date
FROM Soldier s
JOIN Rank rk
    ON s.rank_id = rk.rank_id
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
JOIN AmmoIssue ai
    ON s.entity_id = ai.soldier_entity_id
LEFT JOIN WeaponAssignment wa
    ON s.entity_id = wa.soldier_entity_id
   AND wa.return_date IS NULL
WHERE wa.assignment_id IS NULL
GROUP BY
    s.entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    rk.rank_name,
    mu.unit_name,
    mu.unit_level
ORDER BY
    total_ammo_quantity DESC,
    last_ammo_issue_date DESC;

-- ============================================================
-- Query D5:
-- Unit summary based on the Phase D unit resource view.
-- ============================================================

SELECT
    unit_entity_id,
    unit_id,
    unit_name,
    unit_level,
    company,
    soldier_count,
    soldier_active_equipment_assignment_count,
    soldier_active_equipment_quantity,
    direct_unit_equipment_assignment_count,
    direct_unit_equipment_quantity,
    active_weapon_count,
    ammo_issue_count,
    total_ammo_quantity
FROM v_unit_resource_summary
ORDER BY
    total_ammo_quantity DESC,
    active_weapon_count DESC,
    soldier_active_equipment_quantity DESC;

-- ============================================================
-- Query D6:
-- Maintenance workload by technician unit, weapon type,
-- and maintenance type.
-- ============================================================

SELECT
    tech_unit.unit_name AS technician_unit_name,
    tech_unit.unit_level AS technician_unit_level,
    tech.entity_id AS technician_entity_id,
    tech.soldier_id AS technician_soldier_id,
    tech.first_name AS technician_first_name,
    tech.last_name AS technician_last_name,
    wt.type_name AS weapon_type_name,
    mt.type_name AS maintenance_type_name,
    COUNT(m.maintenance_id) AS maintenance_count,
    MIN(m.maintenance_date) AS first_maintenance_date,
    MAX(m.maintenance_date) AS last_maintenance_date
FROM Maintenance m
JOIN Soldier tech
    ON m.technician_entity_id = tech.entity_id
JOIN MilitaryUnit tech_unit
    ON tech.unit_entity_id = tech_unit.entity_id
JOIN Weapon w
    ON m.serial_number = w.serial_number
JOIN WeaponType wt
    ON w.type_id = wt.type_id
JOIN MaintenanceType mt
    ON m.maint_type_id = mt.maint_type_id
GROUP BY
    tech_unit.unit_name,
    tech_unit.unit_level,
    tech.entity_id,
    tech.soldier_id,
    tech.first_name,
    tech.last_name,
    wt.type_name,
    mt.type_name
ORDER BY
    maintenance_count DESC,
    last_maintenance_date DESC;

-- ============================================================
-- Query D7:
-- High resource load soldiers, based on the Phase D soldier view.
-- ============================================================

SELECT
    soldier_entity_id,
    soldier_id,
    first_name,
    last_name,
    rank_name,
    unit_name,
    unit_level,
    active_equipment_assignment_count,
    active_equipment_quantity,
    active_weapon_count,
    ammo_issue_count,
    total_ammo_quantity,
    maintenance_action_count,
    resource_load_score
FROM v_soldier_resource_overview
WHERE resource_load_score > 0
ORDER BY
    resource_load_score DESC,
    total_ammo_quantity DESC,
    active_equipment_quantity DESC
LIMIT 20;