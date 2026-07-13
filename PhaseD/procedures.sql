-- ============================================================
-- procedures.sql
-- Phase D refactor - Stored functions and stored procedures
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

DROP PROCEDURE IF EXISTS return_equipment_assignment(INT, DATE);
DROP PROCEDURE IF EXISTS return_weapon_assignment(INT, DATE, VARCHAR);

DROP FUNCTION IF EXISTS get_unit_readiness_summary(INT);
DROP FUNCTION IF EXISTS get_soldier_resource_snapshot(INT);

-- ============================================================
-- Function 1:
-- Returns an integrated resource snapshot for one soldier.
-- The function combines active equipment, active weapons,
-- and ammunition issues for the selected soldier.
-- ============================================================

CREATE OR REPLACE FUNCTION get_soldier_resource_snapshot(
    p_soldier_entity_id INT
)
RETURNS TABLE (
    resource_group VARCHAR(50),
    resource_name VARCHAR(150),
    quantity INT,
    status VARCHAR(100),
    event_date DATE,
    details VARCHAR(300)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Soldier s
        WHERE s.entity_id = p_soldier_entity_id
    ) THEN
        RAISE EXCEPTION 'Soldier entity id % does not exist', p_soldier_entity_id;
    END IF;

    RETURN QUERY
    SELECT
        'Equipment'::VARCHAR(50) AS resource_group,
        et.type_name::VARCHAR(150) AS resource_name,
        ea.assigned_quantity::INT AS quantity,
        ea.assignment_status::VARCHAR(100) AS status,
        ea.assignment_date::DATE AS event_date,
        ('asset_id=' || asset.asset_id)::VARCHAR(300) AS details
    FROM EquipmentAssignment ea
    JOIN Recipient r
        ON ea.recipient_id = r.recipient_id
    JOIN EquipmentAsset asset
        ON ea.asset_id = asset.asset_id
    JOIN EquipmentType et
        ON asset.type_id = et.type_id
    WHERE r.entity_id = p_soldier_entity_id
      AND ea.assignment_status = 'פעילה'

    UNION ALL

    SELECT
        'Weapon'::VARCHAR(50) AS resource_group,
        (wt.type_name || ' - ' || w.model)::VARCHAR(150) AS resource_name,
        1::INT AS quantity,
        'פעיל'::VARCHAR(100) AS status,
        wa.assignment_date::DATE AS event_date,
        ('serial_number=' || w.serial_number)::VARCHAR(300) AS details
    FROM WeaponAssignment wa
    JOIN Weapon w
        ON wa.serial_number = w.serial_number
    JOIN WeaponType wt
        ON w.type_id = wt.type_id
    WHERE wa.soldier_entity_id = p_soldier_entity_id
      AND wa.return_date IS NULL

    UNION ALL

    SELECT
        'Ammunition'::VARCHAR(50) AS resource_group,
        (at.type_name || ' - ' || ammo.caliber)::VARCHAR(150) AS resource_name,
        ai.quantity::INT AS quantity,
        COALESCE(ai.purpose, 'ללא פירוט')::VARCHAR(100) AS status,
        ai.issue_date::DATE AS event_date,
        ('ammo_id=' || ammo.ammo_id)::VARCHAR(300) AS details
    FROM AmmoIssue ai
    JOIN Ammunition ammo
        ON ai.ammo_id = ammo.ammo_id
    JOIN AmmoType at
        ON ammo.ammo_type_id = at.ammo_type_id
    WHERE ai.soldier_entity_id = p_soldier_entity_id;
END;
$$;

-- ============================================================
-- Function 2:
-- Returns an integrated readiness/resource summary for one unit.
-- The function uses the unit resource view from views.sql.
-- ============================================================

CREATE OR REPLACE FUNCTION get_unit_readiness_summary(
    p_unit_entity_id INT
)
RETURNS TABLE (
    unit_entity_id INT,
    unit_id VARCHAR(50),
    unit_name VARCHAR(150),
    unit_level VARCHAR(50),
    company VARCHAR(100),
    soldier_count INT,
    soldier_equipment_quantity INT,
    direct_unit_equipment_quantity INT,
    active_weapon_count INT,
    ammo_issue_count INT,
    total_ammo_quantity INT,
    readiness_score INT,
    readiness_level VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM MilitaryUnit mu
        WHERE mu.entity_id = p_unit_entity_id
    ) THEN
        RAISE EXCEPTION 'Unit entity id % does not exist', p_unit_entity_id;
    END IF;

    RETURN QUERY
    WITH unit_readiness AS (
        SELECT
            v.unit_entity_id::INT AS unit_entity_id,
            v.unit_id::VARCHAR(50) AS unit_id,
            v.unit_name::VARCHAR(150) AS unit_name,
            v.unit_level::VARCHAR(50) AS unit_level,
            v.company::VARCHAR(100) AS company,
            v.soldier_count::INT AS soldier_count,
            v.soldier_active_equipment_quantity::INT AS soldier_equipment_quantity,
            v.direct_unit_equipment_quantity::INT AS direct_unit_equipment_quantity,
            v.active_weapon_count::INT AS active_weapon_count,
            v.ammo_issue_count::INT AS ammo_issue_count,
            v.total_ammo_quantity::INT AS total_ammo_quantity,
            (
                v.soldier_count
                + v.soldier_active_equipment_assignment_count
                + v.direct_unit_equipment_assignment_count
                + v.active_weapon_count * 2
                + CASE
                    WHEN v.total_ammo_quantity > 0 THEN 5
                    ELSE 0
                  END
            )::INT AS readiness_score
        FROM v_unit_resource_summary v
        WHERE v.unit_entity_id = p_unit_entity_id
    )
    SELECT
        ur.unit_entity_id,
        ur.unit_id,
        ur.unit_name,
        ur.unit_level,
        ur.company,
        ur.soldier_count,
        ur.soldier_equipment_quantity,
        ur.direct_unit_equipment_quantity,
        ur.active_weapon_count,
        ur.ammo_issue_count,
        ur.total_ammo_quantity,
        ur.readiness_score,
        CASE
            WHEN ur.readiness_score >= 40 THEN 'גבוהה'
            WHEN ur.readiness_score >= 20 THEN 'בינונית'
            ELSE 'נמוכה'
        END::VARCHAR(50) AS readiness_level
    FROM unit_readiness ur;
END;
$$;

-- ============================================================
-- Procedure 1:
-- Closes an active weapon assignment.
-- The procedure updates only WeaponAssignment.
-- Weapon status is synchronized automatically by trigger.
-- ============================================================

CREATE OR REPLACE PROCEDURE return_weapon_assignment(
    p_assignment_id INT,
    p_return_date DATE,
    p_return_reason VARCHAR DEFAULT 'הוחזר'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_assignment_date DATE;
BEGIN
    SELECT
        wa.assignment_date
    INTO
        v_assignment_date
    FROM WeaponAssignment wa
    WHERE wa.assignment_id = p_assignment_id
      AND wa.return_date IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active weapon assignment id % was not found', p_assignment_id;
    END IF;

    IF p_return_date < v_assignment_date THEN
        RAISE EXCEPTION 'Return date cannot be earlier than assignment date';
    END IF;

    UPDATE WeaponAssignment
    SET
        return_date = p_return_date,
        return_reason = COALESCE(p_return_reason, 'הוחזר')
    WHERE assignment_id = p_assignment_id;

    RAISE NOTICE 'Weapon assignment % was returned successfully. Weapon status is synchronized by trigger.', p_assignment_id;
END;
$$;

-- ============================================================
-- Procedure 2:
-- Closes an active equipment assignment.
-- The procedure updates only EquipmentAssignment.
-- Equipment availability is synchronized automatically by trigger.
-- ============================================================

CREATE OR REPLACE PROCEDURE return_equipment_assignment(
    p_assignment_id INT,
    p_return_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_assignment_date DATE;
BEGIN
    SELECT
        ea.assignment_date
    INTO
        v_assignment_date
    FROM EquipmentAssignment ea
    WHERE ea.assignment_id = p_assignment_id
      AND ea.assignment_status = 'פעילה'
      AND ea.return_date IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active equipment assignment id % was not found', p_assignment_id;
    END IF;

    IF p_return_date < v_assignment_date THEN
        RAISE EXCEPTION 'Return date cannot be earlier than assignment date';
    END IF;

    UPDATE EquipmentAssignment
    SET
        return_date = p_return_date,
        assignment_status = 'הוחזרה'
    WHERE assignment_id = p_assignment_id;

    RAISE NOTICE 'Equipment assignment % was returned successfully. Equipment availability is synchronized by trigger.', p_assignment_id;
END;
$$;

-- ============================================================
-- Example checks:
-- ============================================================

-- SELECT * FROM get_soldier_resource_snapshot(1001);

-- SELECT * FROM get_unit_readiness_summary(4);

-- SELECT assignment_id
-- FROM WeaponAssignment
-- WHERE return_date IS NULL
-- ORDER BY assignment_id
-- LIMIT 5;

-- CALL return_weapon_assignment(1, CURRENT_DATE, 'Returned after training');

-- SELECT assignment_id
-- FROM EquipmentAssignment
-- WHERE assignment_status = 'פעילה'
--   AND return_date IS NULL
-- ORDER BY assignment_id
-- LIMIT 5;

-- CALL return_equipment_assignment(1, CURRENT_DATE);