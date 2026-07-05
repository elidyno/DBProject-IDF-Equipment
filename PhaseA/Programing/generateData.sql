-- =========================================================
-- generateData.sql
-- Automatic data generation for the military equipment database
-- Clean and consistent dataset for Phase B queries
-- =========================================================

BEGIN;

TRUNCATE TABLE
    EquipmentAssignment,
    EquipmentItem,
    EquipmentStock,
    EquipmentAsset,
    CategoryType,
    EquipmentType,
    EquipmentCategory,
    StorageLocation,
    Recipient
RESTART IDENTITY CASCADE;


-- =========================================================
-- Insert realistic equipment categories
-- 5 levels * 5 domains * 2 contexts = 50 categories
-- =========================================================

WITH category_levels(level_order, level_name) AS (
    VALUES
        (1, $$אישי$$),
        (2, $$צוותי$$),
        (3, $$פלוגתי$$),
        (4, $$גדודי$$),
        (5, $$חטיבתי$$)
),
category_domains(domain_order, domain_name) AS (
    VALUES
        (1, $$קשר$$),
        (2, $$מיגון$$),
        (3, $$רפואה$$),
        (4, $$לינה$$),
        (5, $$תחזוקה$$)
),
usage_contexts(context_order, context_name) AS (
    VALUES
        (1, $$שגרה$$),
        (2, $$חירום$$)
)
INSERT INTO EquipmentCategory (category_name)
SELECT
    $$ציוד $$ || cl.level_name || $$ - $$ || cd.domain_name || $$ - $$ || uc.context_name
FROM category_domains cd
CROSS JOIN usage_contexts uc
CROSS JOIN category_levels cl
ORDER BY
    cd.domain_order,
    uc.context_order,
    cl.level_order;


-- =========================================================
-- Insert realistic equipment types
-- 30 base equipment names * 2 variants = 60 equipment types
-- =========================================================

WITH base_equipment(item_order, item_name, requires_serial_number) AS (
    VALUES
        (1, $$מכשיר קשר ידני$$, TRUE),
        (2, $$מכשיר קשר לרכב$$, TRUE),
        (3, $$מחשב מוקשח$$, TRUE),
        (4, $$טאבלט שטח$$, TRUE),
        (5, $$ערכת ניווט GPS$$, TRUE),
        (6, $$מצלמת שטח$$, TRUE),
        (7, $$גנרטור נייד$$, TRUE),
        (8, $$מד טווח$$, TRUE),
        (9, $$מטען סוללות חכם$$, TRUE),
        (10, $$פנס טקטי נטען$$, TRUE),
        (11, $$ערכת בדיקה אלקטרונית$$, TRUE),
        (12, $$ראוטר שטח$$, TRUE),
        (13, $$מסך שליטה נייד$$, TRUE),
        (14, $$ערכת תקשורת לוויינית$$, TRUE),
        (15, $$מערכת כריזה ניידת$$, TRUE),

        (16, $$מדי א$$, FALSE),
        (17, $$מדי ב$$, FALSE),
        (18, $$מעיל חורף$$, FALSE),
        (19, $$שק שינה$$, FALSE),
        (20, $$מזרן שטח$$, FALSE),
        (21, $$אוהל צוות$$, FALSE),
        (22, $$אוהל פלוגתי$$, FALSE),
        (23, $$כיסא מתקפל$$, FALSE),
        (24, $$שולחן מתקפל$$, FALSE),
        (25, $$ארגז ציוד$$, FALSE),
        (26, $$ג'ריקן מים$$, FALSE),
        (27, $$ערכת אוכל אישית$$, FALSE),
        (28, $$ערכת מטבח שדה$$, FALSE),
        (29, $$ערכת עזרה ראשונה$$, FALSE),
        (30, $$אלונקה מתקפלת$$, FALSE)
),
variants(variant_order, variant_name) AS (
    VALUES
        (1, $$תקן א$$),
        (2, $$תקן ב$$)
)
INSERT INTO EquipmentType (type_name, requires_serial_number)
SELECT
    be.item_name || $$ - $$ || v.variant_name,
    be.requires_serial_number
FROM variants v
CROSS JOIN base_equipment be
ORDER BY
    v.variant_order,
    be.item_order;


-- =========================================================
-- Insert many-to-many links between categories and equipment types
-- Each equipment type is linked to two different categories
-- =========================================================

INSERT INTO CategoryType (category_id, type_id)
SELECT DISTINCT
    category_id,
    type_id
FROM (
    SELECT
        et.type_id,
        ((et.type_id - 1) % 50) + 1 AS category_id
    FROM EquipmentType et

    UNION ALL

    SELECT
        et.type_id,
        ((et.type_id + 17 - 1) % 50) + 1 AS category_id
    FROM EquipmentType et
) links;


-- =========================================================
-- Insert realistic storage locations
-- 5 location prefixes * 3 units * 2 domains = 30 locations
-- =========================================================

WITH location_prefixes(prefix_order, location_prefix, location_type) AS (
    VALUES
        (1, $$מחסן מרכזי$$, $$חטיבתי$$),
        (2, $$מחסן קדמי$$, $$גדודי$$),
        (3, $$מחסן פלוגתי$$, $$פלוגתי$$),
        (4, $$מכולת ציוד$$, $$מכולה$$),
        (5, $$חדר ציוד ייעודי$$, $$חדר ציוד$$)
),
units(unit_order, unit_name) AS (
    VALUES
        (1, $$פלוגה א$$),
        (2, $$פלוגה ב$$),
        (3, $$גדוד א$$)
),
storage_domains(domain_order, domain_name) AS (
    VALUES
        (1, $$ציוד קשר$$),
        (2, $$ציוד לוגיסטי$$)
)
INSERT INTO StorageLocation (location_name, location_type)
SELECT
    lp.location_prefix || $$ - $$ || u.unit_name || $$ - $$ || sd.domain_name,
    lp.location_type
FROM storage_domains sd
CROSS JOIN units u
CROSS JOIN location_prefixes lp
ORDER BY
    sd.domain_order,
    u.unit_order,
    lp.prefix_order;


-- =========================================================
-- Insert recipients
-- The table only stores recipient type, so we generate 80 recipient rows
-- =========================================================

INSERT INTO Recipient (recipient_type)
SELECT
    (ARRAY[$$חייל$$, $$צוות$$, $$פלוגה$$, $$גדוד$$, $$חטיבה$$])[(floor(random() * 5) + 1)::INT]
FROM generate_series(1, 80);


-- =========================================================
-- Insert equipment assets
-- First 500 assets use equipment types that require serial numbers
-- Next 500 assets use equipment types that do not require serial numbers
-- Availability is updated later according to assignments and condition
-- =========================================================

INSERT INTO EquipmentAsset
(type_id, location_id, condition_status, intake_date, availability_status)
SELECT
    et.type_id,
    (floor(random() * 30) + 1)::INT AS location_id,
    (ARRAY[$$תקין$$, $$פגום$$, $$בתיקון$$, $$חסר$$])[(floor(random() * 4) + 1)::INT] AS condition_status,
    CURRENT_DATE - ((random() * 600)::INT) AS intake_date,
    $$זמין$$ AS availability_status
FROM generate_series(1, 1000) AS gs(i)
JOIN LATERAL (
    SELECT type_id
    FROM EquipmentType
    WHERE requires_serial_number = (gs.i <= 500)
    ORDER BY random()
    LIMIT 1
) et ON TRUE;


-- =========================================================
-- Insert serialized equipment items
-- Only assets whose equipment type requires a serial number are inserted here
-- =========================================================

INSERT INTO EquipmentItem (asset_id, serial_number)
SELECT
    ea.asset_id,
    $$SN-$$ || LPAD(ea.asset_id::TEXT, 6, $$0$$)
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE et.requires_serial_number = TRUE;


-- =========================================================
-- Insert stock-managed equipment
-- Only assets whose equipment type does not require a serial number are inserted here
-- =========================================================

INSERT INTO EquipmentStock (asset_id, quantity)
SELECT
    ea.asset_id,
    (floor(random() * 180) + 20)::INT AS quantity
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE et.requires_serial_number = FALSE;


-- =========================================================
-- Insert equipment assignments
-- One assignment per asset
-- Assignment date is always after the intake date
-- Returned assignments never have a future return date
-- Serialized equipment is always assigned with quantity 1
-- Stock equipment is assigned with a quantity that does not exceed stock quantity
-- =========================================================

WITH assignment_source AS (
    SELECT
        ea.asset_id,
        ea.intake_date,
        ea.condition_status,
        (floor(random() * 80) + 1)::INT AS recipient_id,
        random() AS status_roll,
        (
            ea.intake_date
            + ((random() * GREATEST((CURRENT_DATE - ea.intake_date), 0))::INT)
        )::DATE AS assignment_date
    FROM EquipmentAsset ea
),
assignment_final AS (
    SELECT
        asset_id,
        intake_date,
        condition_status,
        recipient_id,
        assignment_date,
        CASE
            WHEN condition_status = $$תקין$$ AND status_roll < 0.35 THEN $$פעילה$$
            WHEN status_roll < 0.75 THEN $$הוחזרה$$
            ELSE $$בוטלה$$
        END AS assignment_status
    FROM assignment_source
)
INSERT INTO EquipmentAssignment
(asset_id, recipient_id, assignment_date, return_date, assigned_quantity, assignment_status)
SELECT
    af.asset_id,
    af.recipient_id,
    af.assignment_date,
    CASE
        WHEN af.assignment_status = $$הוחזרה$$ THEN
            LEAST(CURRENT_DATE, af.assignment_date + ((random() * 60)::INT))
        ELSE NULL
    END AS return_date,
    CASE
        WHEN ei.asset_id IS NOT NULL THEN 1
        ELSE (floor(random() * LEAST(es.quantity, 10)) + 1)::INT
    END AS assigned_quantity,
    af.assignment_status
FROM assignment_final af
LEFT JOIN EquipmentItem ei
    ON af.asset_id = ei.asset_id
LEFT JOIN EquipmentStock es
    ON af.asset_id = es.asset_id;


-- =========================================================
-- Update availability status according to active assignments and condition
-- =========================================================

UPDATE EquipmentAsset ea
SET availability_status =
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM EquipmentAssignment a
            WHERE a.asset_id = ea.asset_id
              AND a.assignment_status = $$פעילה$$
        ) THEN $$מוקצה$$
        WHEN ea.condition_status = $$תקין$$ THEN $$זמין$$
        ELSE $$לא זמין$$
    END;


COMMIT;


-- =========================================================
-- Row count check
-- =========================================================

SELECT $$EquipmentCategory$$ AS table_name, COUNT(*) AS row_count FROM EquipmentCategory
UNION ALL
SELECT $$EquipmentType$$, COUNT(*) FROM EquipmentType
UNION ALL
SELECT $$CategoryType$$, COUNT(*) FROM CategoryType
UNION ALL
SELECT $$StorageLocation$$, COUNT(*) FROM StorageLocation
UNION ALL
SELECT $$Recipient$$, COUNT(*) FROM Recipient
UNION ALL
SELECT $$EquipmentAsset$$, COUNT(*) FROM EquipmentAsset
UNION ALL
SELECT $$EquipmentItem$$, COUNT(*) FROM EquipmentItem
UNION ALL
SELECT $$EquipmentStock$$, COUNT(*) FROM EquipmentStock
UNION ALL
SELECT $$EquipmentAssignment$$, COUNT(*) FROM EquipmentAssignment;


-- =========================================================
-- Consistency checks
-- All problem counts should be 0
-- =========================================================

SELECT COUNT(*) AS wrong_items
FROM EquipmentItem ei
JOIN EquipmentAsset ea
    ON ei.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE et.requires_serial_number = FALSE;

SELECT COUNT(*) AS wrong_stock
FROM EquipmentStock es
JOIN EquipmentAsset ea
    ON es.asset_id = ea.asset_id
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE et.requires_serial_number = TRUE;

SELECT COUNT(*) AS wrong_serial_assignments
FROM EquipmentAssignment a
JOIN EquipmentItem ei
    ON a.asset_id = ei.asset_id
WHERE a.assigned_quantity <> 1;

SELECT COUNT(*) AS assignments_before_intake
FROM EquipmentAssignment a
JOIN EquipmentAsset ea
    ON a.asset_id = ea.asset_id
WHERE a.assignment_date < ea.intake_date;

SELECT COUNT(*) AS returned_without_return_date
FROM EquipmentAssignment
WHERE assignment_status = $$הוחזרה$$
  AND return_date IS NULL;

SELECT COUNT(*) AS active_with_return_date
FROM EquipmentAssignment
WHERE assignment_status = $$פעילה$$
  AND return_date IS NOT NULL;

SELECT COUNT(*) AS future_returned_assignments
FROM EquipmentAssignment
WHERE assignment_status = $$הוחזרה$$
  AND return_date > CURRENT_DATE;

SELECT COUNT(*) AS active_assets_not_marked_allocated
FROM EquipmentAsset ea
WHERE EXISTS (
    SELECT 1
    FROM EquipmentAssignment a
    WHERE a.asset_id = ea.asset_id
      AND a.assignment_status = $$פעילה$$
)
AND ea.availability_status <> $$מוקצה$$;

SELECT COUNT(*) AS allocated_assets_without_active_assignment
FROM EquipmentAsset ea
WHERE ea.availability_status = $$מוקצה$$
AND NOT EXISTS (
    SELECT 1
    FROM EquipmentAssignment a
    WHERE a.asset_id = ea.asset_id
      AND a.assignment_status = $$פעילה$$
);

SELECT COUNT(*) AS unavailable_condition_marked_available
FROM EquipmentAsset
WHERE condition_status <> $$תקין$$
  AND availability_status = $$זמין$$;

SELECT COUNT(*) AS duplicated_active_serial_items
FROM (
    SELECT a.asset_id
    FROM EquipmentAssignment a
    JOIN EquipmentItem ei
        ON a.asset_id = ei.asset_id
    WHERE a.assignment_status = $$פעילה$$
    GROUP BY a.asset_id
    HAVING COUNT(*) > 1
) duplicated_items;

SELECT COUNT(*) AS stock_over_allocated
FROM (
    SELECT
        es.asset_id,
        es.quantity,
        COALESCE(SUM(a.assigned_quantity), 0) AS active_assigned_quantity
    FROM EquipmentStock es
    LEFT JOIN EquipmentAssignment a
        ON es.asset_id = a.asset_id
       AND a.assignment_status = $$פעילה$$
    GROUP BY
        es.asset_id,
        es.quantity
    HAVING COALESCE(SUM(a.assigned_quantity), 0) > es.quantity
) stock_check;


-- =========================================================
-- M:N check
-- The result should be 60 because every equipment type is linked
-- to two categories
-- =========================================================

SELECT COUNT(*) AS equipment_types_with_multiple_categories
FROM (
    SELECT type_id
    FROM CategoryType
    GROUP BY type_id
    HAVING COUNT(category_id) > 1
) multi_category_types;
