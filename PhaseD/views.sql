-- ============================================================
-- views.sql
-- Phase D - Views for the integrated database
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

DROP VIEW IF EXISTS v_unit_resource_summary;
DROP VIEW IF EXISTS v_soldier_resource_overview;

-- ============================================================
-- View 1:
-- Soldier resource overview.
-- This view shows an integrated resource summary for each soldier.
-- ============================================================

CREATE OR REPLACE VIEW v_soldier_resource_overview AS
WITH active_equipment AS (
    SELECT
        s.entity_id AS soldier_entity_id,
        COUNT(DISTINCT ea.assignment_id) AS active_equipment_assignment_count,
        COALESCE(SUM(ea.assigned_quantity), 0) AS active_equipment_quantity
    FROM Soldier s
    JOIN Recipient r
        ON s.entity_id = r.entity_id
    JOIN EquipmentAssignment ea
        ON r.recipient_id = ea.recipient_id
    WHERE ea.assignment_status = 'פעילה'
    GROUP BY
        s.entity_id
),
active_weapons AS (
    SELECT
        wa.soldier_entity_id,
        COUNT(DISTINCT wa.assignment_id) AS active_weapon_count
    FROM WeaponAssignment wa
    WHERE wa.return_date IS NULL
    GROUP BY
        wa.soldier_entity_id
),
ammo_summary AS (
    SELECT
        ai.soldier_entity_id,
        COUNT(ai.issue_id) AS ammo_issue_count,
        COALESCE(SUM(ai.quantity), 0) AS total_ammo_quantity
    FROM AmmoIssue ai
    GROUP BY
        ai.soldier_entity_id
),
maintenance_work AS (
    SELECT
        m.technician_entity_id AS soldier_entity_id,
        COUNT(m.maintenance_id) AS maintenance_action_count
    FROM Maintenance m
    GROUP BY
        m.technician_entity_id
)
SELECT
    s.entity_id AS soldier_entity_id,
    s.soldier_id,
    s.first_name,
    s.last_name,
    rk.rank_name,
    s.unit_entity_id,
    unit_entity.entity_name AS unit_name,
    COALESCE(ae.active_equipment_assignment_count, 0) AS active_equipment_assignment_count,
    COALESCE(ae.active_equipment_quantity, 0) AS active_equipment_quantity,
    COALESCE(aw.active_weapon_count, 0) AS active_weapon_count,
    COALESCE(am.ammo_issue_count, 0) AS ammo_issue_count,
    COALESCE(am.total_ammo_quantity, 0) AS total_ammo_quantity,
    COALESCE(mw.maintenance_action_count, 0) AS maintenance_action_count,
    (
        COALESCE(ae.active_equipment_assignment_count, 0)
        + COALESCE(aw.active_weapon_count, 0) * 2
        + COALESCE(am.ammo_issue_count, 0)
    ) AS resource_load_score
FROM Soldier s
JOIN Rank rk
    ON s.rank_id = rk.rank_id
JOIN MilitaryUnit mu
    ON s.unit_entity_id = mu.entity_id
JOIN MilitaryEntity unit_entity
    ON mu.entity_id = unit_entity.entity_id
LEFT JOIN active_equipment ae
    ON s.entity_id = ae.soldier_entity_id
LEFT JOIN active_weapons aw
    ON s.entity_id = aw.soldier_entity_id
LEFT JOIN ammo_summary am
    ON s.entity_id = am.soldier_entity_id
LEFT JOIN maintenance_work mw
    ON s.entity_id = mw.soldier_entity_id;

-- ============================================================
-- View 2:
-- Unit resource summary.
-- This view shows an integrated resource summary for each unit.
-- ============================================================

CREATE OR REPLACE VIEW v_unit_resource_summary AS
WITH soldier_count AS (
    SELECT
        s.unit_entity_id,
        COUNT(s.entity_id) AS soldier_count
    FROM Soldier s
    GROUP BY
        s.unit_entity_id
),
soldier_equipment AS (
    SELECT
        s.unit_entity_id,
        COUNT(DISTINCT ea.assignment_id) AS soldier_active_equipment_assignment_count,
        COALESCE(SUM(ea.assigned_quantity), 0) AS soldier_active_equipment_quantity
    FROM Soldier s
    JOIN Recipient r
        ON s.entity_id = r.entity_id
    JOIN EquipmentAssignment ea
        ON r.recipient_id = ea.recipient_id
    WHERE ea.assignment_status = 'פעילה'
    GROUP BY
        s.unit_entity_id
),
direct_unit_equipment AS (
    SELECT
        mu.entity_id AS unit_entity_id,
        COUNT(DISTINCT ea.assignment_id) AS direct_unit_equipment_assignment_count,
        COALESCE(SUM(ea.assigned_quantity), 0) AS direct_unit_equipment_quantity
    FROM MilitaryUnit mu
    JOIN Recipient r
        ON mu.entity_id = r.entity_id
    JOIN EquipmentAssignment ea
        ON r.recipient_id = ea.recipient_id
    WHERE ea.assignment_status = 'פעילה'
    GROUP BY
        mu.entity_id
),
unit_weapons AS (
    SELECT
        s.unit_entity_id,
        COUNT(DISTINCT wa.assignment_id) AS active_weapon_count
    FROM Soldier s
    JOIN WeaponAssignment wa
        ON s.entity_id = wa.soldier_entity_id
    WHERE wa.return_date IS NULL
    GROUP BY
        s.unit_entity_id
),
unit_ammo AS (
    SELECT
        s.unit_entity_id,
        COUNT(ai.issue_id) AS ammo_issue_count,
        COALESCE(SUM(ai.quantity), 0) AS total_ammo_quantity
    FROM Soldier s
    JOIN AmmoIssue ai
        ON s.entity_id = ai.soldier_entity_id
    GROUP BY
        s.unit_entity_id
)
SELECT
    mu.entity_id AS unit_entity_id,
    mu.unit_id,
    mu.unit_name,
    unit_entity.entity_name,
    mu.company,
    COALESCE(sc.soldier_count, 0) AS soldier_count,
    COALESCE(se.soldier_active_equipment_assignment_count, 0) AS soldier_active_equipment_assignment_count,
    COALESCE(se.soldier_active_equipment_quantity, 0) AS soldier_active_equipment_quantity,
    COALESCE(due.direct_unit_equipment_assignment_count, 0) AS direct_unit_equipment_assignment_count,
    COALESCE(due.direct_unit_equipment_quantity, 0) AS direct_unit_equipment_quantity,
    COALESCE(uw.active_weapon_count, 0) AS active_weapon_count,
    COALESCE(ua.ammo_issue_count, 0) AS ammo_issue_count,
    COALESCE(ua.total_ammo_quantity, 0) AS total_ammo_quantity
FROM MilitaryUnit mu
JOIN MilitaryEntity unit_entity
    ON mu.entity_id = unit_entity.entity_id
LEFT JOIN soldier_count sc
    ON mu.entity_id = sc.unit_entity_id
LEFT JOIN soldier_equipment se
    ON mu.entity_id = se.unit_entity_id
LEFT JOIN direct_unit_equipment due
    ON mu.entity_id = due.unit_entity_id
LEFT JOIN unit_weapons uw
    ON mu.entity_id = uw.unit_entity_id
LEFT JOIN unit_ammo ua
    ON mu.entity_id = ua.unit_entity_id;