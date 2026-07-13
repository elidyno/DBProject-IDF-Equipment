-- ============================================================
-- mainPhaseD.sql
-- Phase D main runner and validation checks
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- Important run order before this file:
-- 1. PhaseD/views.sql
-- 2. PhaseD/complexQueries.sql
-- 3. PhaseD/parameterizedQueries.sql
-- 4. PhaseD/procedures.sql
-- 5. PhaseD/triggers.sql
-- Then run this file.
-- ============================================================

-- ============================================================
-- Section 1:
-- Check that Phase D database objects exist.
-- ============================================================

SELECT
    'View check' AS check_group,
    table_name AS object_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'v_soldier_resource_overview',
      'v_unit_resource_summary'
  )
ORDER BY
    object_name;

SELECT
    CASE p.prokind
        WHEN 'f' THEN 'Function'
        WHEN 'p' THEN 'Procedure'
        ELSE 'Other'
    END AS object_type,
    p.proname AS object_name
FROM pg_proc p
JOIN pg_namespace n
    ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
      'get_soldier_resource_snapshot',
      'get_unit_readiness_summary',
      'return_weapon_assignment',
      'return_equipment_assignment'
  )
ORDER BY
    object_type,
    object_name;

SELECT
    c.relname AS table_name,
    t.tgname AS trigger_name
FROM pg_trigger t
JOIN pg_class c
    ON t.tgrelid = c.oid
WHERE NOT t.tgisinternal
  AND t.tgname IN (
      'trg_sync_weapon_status',
      'trg_sync_equipment_availability'
  )
ORDER BY
    c.relname,
    t.tgname;

-- ============================================================
-- Section 2:
-- View checks.
-- ============================================================

SELECT
    *
FROM v_soldier_resource_overview
ORDER BY
    resource_load_score DESC,
    soldier_entity_id
LIMIT 10;

SELECT
    *
FROM v_unit_resource_summary
ORDER BY
    total_ammo_quantity DESC,
    active_weapon_count DESC,
    soldier_active_equipment_quantity DESC
LIMIT 10;


-- ============================================================
-- Section 3:
-- Stored function checks.
-- ============================================================

SELECT
    *
FROM get_soldier_resource_snapshot(1001)
ORDER BY
    event_date DESC,
    resource_group
LIMIT 20;

SELECT
    *
FROM get_unit_readiness_summary(4);

-- ============================================================
-- Section 4:
-- Procedure and trigger demo.
-- This section uses ROLLBACK so the demo does not permanently
-- change the seeded project data.
-- ============================================================

BEGIN;

-- ============================================================
-- Weapon return demo.
-- The procedure updates WeaponAssignment.
-- The trigger updates Weapon status automatically.
-- ============================================================

CREATE TEMP TABLE tmp_weapon_return_demo AS
SELECT
    wa.assignment_id,
    wa.serial_number,
    wa.assignment_date
FROM WeaponAssignment wa
WHERE wa.return_date IS NULL
ORDER BY
    wa.assignment_id
LIMIT 1;

SELECT
    'Before weapon return' AS demo_step,
    wa.assignment_id,
    wa.serial_number,
    wa.assignment_date,
    wa.return_date,
    wa.return_reason,
    ws.status_name AS weapon_status
FROM tmp_weapon_return_demo tmp
JOIN WeaponAssignment wa
    ON tmp.assignment_id = wa.assignment_id
JOIN Weapon w
    ON wa.serial_number = w.serial_number
JOIN WeaponStatus ws
    ON w.status_id = ws.status_id;

DO $$
DECLARE
    v_assignment_id INT;
    v_return_date DATE;
BEGIN
    SELECT
        assignment_id,
        GREATEST(CURRENT_DATE, assignment_date)
    INTO
        v_assignment_id,
        v_return_date
    FROM tmp_weapon_return_demo;

    IF v_assignment_id IS NULL THEN
        RAISE EXCEPTION 'No active weapon assignment was found for the demo';
    END IF;

    CALL return_weapon_assignment(
        v_assignment_id,
        v_return_date,
        'Phase D main demo'
    );
END;
$$;

SELECT
    'After weapon return' AS demo_step,
    wa.assignment_id,
    wa.serial_number,
    wa.assignment_date,
    wa.return_date,
    wa.return_reason,
    ws.status_name AS weapon_status
FROM tmp_weapon_return_demo tmp
JOIN WeaponAssignment wa
    ON tmp.assignment_id = wa.assignment_id
JOIN Weapon w
    ON wa.serial_number = w.serial_number
JOIN WeaponStatus ws
    ON w.status_id = ws.status_id;

-- ============================================================
-- Equipment return demo.
-- The procedure updates EquipmentAssignment.
-- The trigger updates EquipmentAsset availability automatically.
-- ============================================================

CREATE TEMP TABLE tmp_equipment_return_demo AS
SELECT
    ea.assignment_id,
    ea.asset_id,
    ea.assignment_date
FROM EquipmentAssignment ea
WHERE ea.assignment_status = 'פעילה'
  AND ea.return_date IS NULL
ORDER BY
    ea.assignment_id
LIMIT 1;

SELECT
    'Before equipment return' AS demo_step,
    ea.assignment_id,
    ea.asset_id,
    ea.assignment_date,
    ea.return_date,
    ea.assignment_status,
    asset.availability_status
FROM tmp_equipment_return_demo tmp
JOIN EquipmentAssignment ea
    ON tmp.assignment_id = ea.assignment_id
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id;

DO $$
DECLARE
    v_assignment_id INT;
    v_return_date DATE;
BEGIN
    SELECT
        assignment_id,
        GREATEST(CURRENT_DATE, assignment_date)
    INTO
        v_assignment_id,
        v_return_date
    FROM tmp_equipment_return_demo;

    IF v_assignment_id IS NULL THEN
        RAISE EXCEPTION 'No active equipment assignment was found for the demo';
    END IF;

    CALL return_equipment_assignment(
        v_assignment_id,
        v_return_date
    );
END;
$$;

SELECT
    'After equipment return' AS demo_step,
    ea.assignment_id,
    ea.asset_id,
    ea.assignment_date,
    ea.return_date,
    ea.assignment_status,
    asset.availability_status
FROM tmp_equipment_return_demo tmp
JOIN EquipmentAssignment ea
    ON tmp.assignment_id = ea.assignment_id
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id;

ROLLBACK;

-- ============================================================
-- End of Phase D main runner.
-- ============================================================