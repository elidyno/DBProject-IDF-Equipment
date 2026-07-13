-- ============================================================
-- triggers.sql
-- Phase D refactor - Triggers
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

DROP TRIGGER IF EXISTS trg_sync_weapon_status ON WeaponAssignment;
DROP TRIGGER IF EXISTS trg_sync_equipment_availability ON EquipmentAssignment;

DROP FUNCTION IF EXISTS sync_weapon_status_from_assignment();
DROP FUNCTION IF EXISTS sync_equipment_availability_from_assignment();

-- ============================================================
-- Trigger Function 1:
-- Synchronizes weapon status according to weapon assignments.
-- If a weapon has an active assignment, its status becomes allocated.
-- If it has no active assignment, its status becomes ready.
-- ============================================================

CREATE OR REPLACE FUNCTION sync_weapon_status_from_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_allocated_status_id INT;
    v_ready_status_id INT;
    v_active_assignment_count INT;
BEGIN
    SELECT ws.status_id
    INTO v_allocated_status_id
    FROM WeaponStatus ws
    WHERE ws.status_name = 'מוקצה';

    SELECT ws.status_id
    INTO v_ready_status_id
    FROM WeaponStatus ws
    WHERE ws.status_name = 'תקין';

    IF v_allocated_status_id IS NULL THEN
        RAISE EXCEPTION 'Allocated weapon status was not found';
    END IF;

    IF v_ready_status_id IS NULL THEN
        RAISE EXCEPTION 'Ready weapon status was not found';
    END IF;

    IF NEW.return_date IS NULL THEN
        UPDATE Weapon
        SET status_id = v_allocated_status_id
        WHERE serial_number = NEW.serial_number;
    ELSE
        SELECT COUNT(*)
        INTO v_active_assignment_count
        FROM WeaponAssignment wa
        WHERE wa.serial_number = NEW.serial_number
          AND wa.return_date IS NULL;

        IF v_active_assignment_count = 0 THEN
            UPDATE Weapon
            SET status_id = v_ready_status_id
            WHERE serial_number = NEW.serial_number;
        ELSE
            UPDATE Weapon
            SET status_id = v_allocated_status_id
            WHERE serial_number = NEW.serial_number;
        END IF;
    END IF;

    IF TG_OP = 'UPDATE'
       AND OLD.serial_number IS DISTINCT FROM NEW.serial_number THEN

        SELECT COUNT(*)
        INTO v_active_assignment_count
        FROM WeaponAssignment wa
        WHERE wa.serial_number = OLD.serial_number
          AND wa.return_date IS NULL;

        IF v_active_assignment_count = 0 THEN
            UPDATE Weapon
            SET status_id = v_ready_status_id
            WHERE serial_number = OLD.serial_number;
        ELSE
            UPDATE Weapon
            SET status_id = v_allocated_status_id
            WHERE serial_number = OLD.serial_number;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_weapon_status
AFTER INSERT OR UPDATE OF serial_number, return_date
ON WeaponAssignment
FOR EACH ROW
EXECUTE FUNCTION sync_weapon_status_from_assignment();

-- ============================================================
-- Trigger Function 2:
-- Synchronizes equipment asset availability according to equipment assignments.
-- If an asset has at least one active assignment, it becomes allocated.
-- If it has no active assignments, it becomes available.
-- ============================================================

CREATE OR REPLACE FUNCTION sync_equipment_availability_from_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_active_assignment_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_active_assignment_count
    FROM EquipmentAssignment ea
    WHERE ea.asset_id = NEW.asset_id
      AND ea.assignment_status = 'פעילה'
      AND ea.return_date IS NULL;

    IF v_active_assignment_count > 0 THEN
        UPDATE EquipmentAsset
        SET availability_status = 'מוקצה'
        WHERE asset_id = NEW.asset_id;
    ELSE
        UPDATE EquipmentAsset
        SET availability_status = 'זמין'
        WHERE asset_id = NEW.asset_id;
    END IF;

    IF TG_OP = 'UPDATE'
       AND OLD.asset_id IS DISTINCT FROM NEW.asset_id THEN

        SELECT COUNT(*)
        INTO v_active_assignment_count
        FROM EquipmentAssignment ea
        WHERE ea.asset_id = OLD.asset_id
          AND ea.assignment_status = 'פעילה'
          AND ea.return_date IS NULL;

        IF v_active_assignment_count > 0 THEN
            UPDATE EquipmentAsset
            SET availability_status = 'מוקצה'
            WHERE asset_id = OLD.asset_id;
        ELSE
            UPDATE EquipmentAsset
            SET availability_status = 'זמין'
            WHERE asset_id = OLD.asset_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_equipment_availability
AFTER INSERT OR UPDATE OF asset_id, assignment_status, return_date
ON EquipmentAssignment
FOR EACH ROW
EXECUTE FUNCTION sync_equipment_availability_from_assignment();

-- ============================================================
-- Example checks:
-- ============================================================

-- SELECT wa.assignment_id, wa.serial_number, ws.status_name
-- FROM WeaponAssignment wa
-- JOIN Weapon w ON wa.serial_number = w.serial_number
-- JOIN WeaponStatus ws ON w.status_id = ws.status_id
-- WHERE wa.return_date IS NULL
-- ORDER BY wa.assignment_id
-- LIMIT 5;

-- SELECT ea.assignment_id, ea.asset_id, asset.availability_status
-- FROM EquipmentAssignment ea
-- JOIN EquipmentAsset asset ON ea.asset_id = asset.asset_id
-- WHERE ea.assignment_status = 'פעילה'
--   AND ea.return_date IS NULL
-- ORDER BY ea.assignment_id
-- LIMIT 5;