-- ============================================================
-- parameterizedQueries.sql
-- Phase D refactor - Parameterized queries
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

DEALLOCATE ALL;

-- ============================================================
-- Parameterized Query P1:
-- Active equipment assignments for a specific soldier.
-- Parameter:
-- $1 = soldier entity_id
-- ============================================================

PREPARE p_active_equipment_for_soldier(INT) AS
SELECT
    s.entity_id AS soldier_entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    mu.unit_name,
    mu.unit_level,
    ea.assignment_id,
    et.type_name AS equipment_type_name,
    ea.assigned_quantity,
    ea.assignment_date,
    ea.assignment_status
FROM Soldier s
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
JOIN Recipient r
    ON s.entity_id = r.entity_id
JOIN EquipmentAssignment ea
    ON r.recipient_id = ea.recipient_id
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
JOIN EquipmentType et
    ON asset.type_id = et.type_id
WHERE s.entity_id = $1
  AND ea.assignment_status = 'פעילה'
ORDER BY
    ea.assignment_date DESC,
    ea.assignment_id;

EXECUTE p_active_equipment_for_soldier(1001);

-- ============================================================
-- Parameterized Query P2:
-- Unit resource summary for units of a specific level.
-- Parameter:
-- $1 = unit_level
-- ============================================================

PREPARE p_unit_summary_by_level(VARCHAR) AS
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
WHERE unit_level = $1
ORDER BY
    total_ammo_quantity DESC,
    active_weapon_count DESC,
    soldier_active_equipment_quantity DESC;

EXECUTE p_unit_summary_by_level('פלוגה');

-- ============================================================
-- Parameterized Query P3:
-- Ammunition issues for a specific unit within a date range.
-- Parameters:
-- $1 = unit entity_id
-- $2 = start date
-- $3 = end date
-- ============================================================

PREPARE p_ammo_issues_for_unit(INT, DATE, DATE) AS
SELECT
    mu.entity_id AS unit_entity_id,
    mu.unit_name,
    mu.unit_level,
    s.entity_id AS soldier_entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    at.type_name AS ammo_type_name,
    a.caliber,
    ai.quantity,
    ai.issue_date,
    ai.purpose
FROM MilitaryUnit mu
JOIN Soldier s
    ON mu.entity_id = s.unit_entity_id
JOIN AmmoIssue ai
    ON s.entity_id = ai.soldier_entity_id
JOIN Ammunition a
    ON ai.ammo_id = a.ammo_id
JOIN AmmoType at
    ON a.ammo_type_id = at.ammo_type_id
WHERE mu.entity_id = $1
  AND ai.issue_date BETWEEN $2 AND $3
ORDER BY
    ai.issue_date DESC,
    ai.issue_id;

EXECUTE p_ammo_issues_for_unit(4, DATE '2023-06-01', DATE '2024-12-31');

-- ============================================================
-- Parameterized Query P4:
-- Maintenance workload by weapon type within a date range.
-- Parameters:
-- $1 = weapon type name
-- $2 = start date
-- $3 = end date
-- ============================================================

PREPARE p_maintenance_by_weapon_type(VARCHAR, DATE, DATE) AS
SELECT
    wt.type_name AS weapon_type_name,
    mt.type_name AS maintenance_type_name,
    tech.entity_id AS technician_entity_id,
    tech.soldier_id AS technician_soldier_id,
    tech.first_name AS technician_first_name,
    tech.last_name AS technician_last_name,
    tech_unit.unit_name AS technician_unit_name,
    tech_unit.unit_level AS technician_unit_level,
    COUNT(m.maintenance_id) AS maintenance_count,
    MIN(m.maintenance_date) AS first_maintenance_date,
    MAX(m.maintenance_date) AS last_maintenance_date
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
WHERE wt.type_name = $1
  AND m.maintenance_date BETWEEN $2 AND $3
GROUP BY
    wt.type_name,
    mt.type_name,
    tech.entity_id,
    tech.soldier_id,
    tech.first_name,
    tech.last_name,
    tech_unit.unit_name,
    tech_unit.unit_level
ORDER BY
    maintenance_count DESC,
    last_maintenance_date DESC;

EXECUTE p_maintenance_by_weapon_type('רובה סער', DATE '2023-01-01', DATE '2024-12-31');

-- ============================================================
-- Parameterized Query P5:
-- High resource load soldiers above a selected threshold.
-- Parameter:
-- $1 = minimum resource load score
-- ============================================================

PREPARE p_high_resource_load_soldiers(INT) AS
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
WHERE resource_load_score >= $1
ORDER BY
    resource_load_score DESC,
    total_ammo_quantity DESC,
    active_equipment_quantity DESC;

EXECUTE p_high_resource_load_soldiers(5);