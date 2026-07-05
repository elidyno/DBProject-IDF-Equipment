-- =========================================================
-- generateData.sql
-- Automatic data generation for the military equipment database
-- The data uses realistic names instead of numbered examples.
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
-- 10 levels * 10 domains * 5 usage contexts = 500 categories
-- The order is mixed so the first rows are not all from the same level.
-- =========================================================

WITH category_levels(level_order, level_name) AS (
    VALUES
        (1, $$אישי$$),
        (2, $$צוותי$$),
        (3, $$מחלקתי$$),
        (4, $$פלוגתי$$),
        (5, $$גדודי$$),
        (6, $$חטיבתי$$),
        (7, $$לוגיסטי$$),
        (8, $$מבצעי$$),
        (9, $$אימונים$$),
        (10, $$חירום$$)
),
category_domains(domain_order, domain_name) AS (
    VALUES
        (1, $$קשר$$),
        (2, $$מיגון$$),
        (3, $$רפואה$$),
        (4, $$לינה$$),
        (5, $$מטבח$$),
        (6, $$תחזוקה$$),
        (7, $$תובלה$$),
        (8, $$חורף$$),
        (9, $$קיץ$$),
        (10, $$שטח$$)
),
usage_contexts(context_order, context_name) AS (
    VALUES
        (1, $$שגרה$$),
        (2, $$אימון$$),
        (3, $$חירום$$),
        (4, $$שטח$$),
        (5, $$מחסן$$)
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
-- 50 base equipment names * 10 variants = 500 equipment types
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
        (12, $$מקרן הדרכה נייד$$, TRUE),
        (13, $$ראוטר שטח$$, TRUE),
        (14, $$מסך שליטה נייד$$, TRUE),
        (15, $$ערכת תקשורת לוויינית$$, TRUE),
        (16, $$אמצעי תאורה נייד$$, TRUE),
        (17, $$מערכת כריזה ניידת$$, TRUE),
        (18, $$מדחס אוויר נייד$$, TRUE),
        (19, $$ערכת צילום ותיעוד$$, TRUE),
        (20, $$ערכת סימון אלקטרונית$$, TRUE),

        (21, $$מדי א$$, FALSE),
        (22, $$מדי ב$$, FALSE),
        (23, $$חולצת עבודה$$, FALSE),
        (24, $$מכנסי עבודה$$, FALSE),
        (25, $$מעיל חורף$$, FALSE),
        (26, $$שק שינה$$, FALSE),
        (27, $$שמיכת צמר$$, FALSE),
        (28, $$מזרן שטח$$, FALSE),
        (29, $$אוהל צוות$$, FALSE),
        (30, $$אוהל פלוגתי$$, FALSE),
        (31, $$כיסא מתקפל$$, FALSE),
        (32, $$שולחן מתקפל$$, FALSE),
        (33, $$ארגז ציוד$$, FALSE),
        (34, $$ג'ריקן מים$$, FALSE),
        (35, $$ערכת אוכל אישית$$, FALSE),
        (36, $$ערכת מטבח שדה$$, FALSE),
        (37, $$ערכת עזרה ראשונה$$, FALSE),
        (38, $$תחבושת אישית$$, FALSE),
        (39, $$אלונקה מתקפלת$$, FALSE),
        (40, $$אפוד זיהוי$$, FALSE),
        (41, $$כפפות עבודה$$, FALSE),
        (42, $$משקפי מגן$$, FALSE),
        (43, $$קסדת עבודה$$, FALSE),
        (44, $$ערכת ניקיון$$, FALSE),
        (45, $$כלי עבודה בסיסיים$$, FALSE),
        (46, $$כבל מאריך$$, FALSE),
        (47, $$תוף חשמל$$, FALSE),
        (48, $$שלט סימון$$, FALSE),
        (49, $$קופסת אחסון$$, FALSE),
        (50, $$ברזנט שטח$$, FALSE)
),
variants(variant_order, variant_name) AS (
    VALUES
        (1, $$תקן א$$),
        (2, $$תקן ב$$),
        (3, $$תקן ג$$),
        (4, $$קל משקל$$),
        (5, $$מוקשח$$),
        (6, $$לשטח$$),
        (7, $$לאימון$$),
        (8, $$לחירום$$),
        (9, $$למחסן קדמי$$),
        (10, $$למחסן עורפי$$)
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
-- Each equipment type is linked to three different categories.
-- This demonstrates the M:N relationship in the data.
-- =========================================================

INSERT INTO CategoryType (category_id, type_id)
SELECT DISTINCT
    category_id,
    type_id
FROM (
    SELECT
        et.type_id,
        ((et.type_id - 1) % 500) + 1 AS category_id
    FROM EquipmentType et

    UNION ALL

    SELECT
        et.type_id,
        ((et.type_id + 83 - 1) % 500) + 1 AS category_id
    FROM EquipmentType et

    UNION ALL

    SELECT
        et.type_id,
        ((et.type_id + 197 - 1) % 500) + 1 AS category_id
    FROM EquipmentType et
) links;


-- =========================================================
-- Insert realistic storage locations
-- 10 location prefixes * 10 units * 5 domains = 500 locations
-- The order is mixed so the first rows are varied.
-- =========================================================

WITH location_prefixes(prefix_order, location_prefix, location_type) AS (
    VALUES
        (1, $$מחסן מרכזי$$, $$חטיבתי$$),
        (2, $$מחסן קדמי$$, $$גדודי$$),
        (3, $$מחסן פלוגתי$$, $$פלוגתי$$),
        (4, $$מכולת ציוד$$, $$מכולה$$),
        (5, $$חדר ציוד קשר$$, $$חדר ציוד$$),
        (6, $$חדר ציוד רפואי$$, $$חדר ציוד$$),
        (7, $$אזור אחסון חירום$$, $$חירום$$),
        (8, $$מחסן אימונים$$, $$אימונים$$),
        (9, $$נקודת חלוקה$$, $$לוגיסטי$$),
        (10, $$מחסן תחזוקה$$, $$תחזוקה$$)
),
units(unit_order, unit_name) AS (
    VALUES
        (1, $$פלוגה א$$),
        (2, $$פלוגה ב$$),
        (3, $$פלוגה ג$$),
        (4, $$פלוגה ד$$),
        (5, $$גדוד א$$),
        (6, $$גדוד ב$$),
        (7, $$גדוד ג$$),
        (8, $$חפ"ק חטיבתי$$),
        (9, $$מרכז לוגיסטי$$),
        (10, $$יחידת מילואים$$)
),
storage_domains(domain_order, domain_name) AS (
    VALUES
        (1, $$ציוד קשר$$),
        (2, $$ציוד מיגון$$),
        (3, $$ציוד רפואה$$),
        (4, $$ציוד לינה$$),
        (5, $$ציוד תחזוקה$$)
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
-- The table only stores recipient type, so we generate 500 recipient rows.
-- =========================================================

INSERT INTO Recipient (recipient_type)
SELECT
    (ARRAY[$$חייל$$, $$צוות$$, $$פלוגה$$, $$גדוד$$, $$חטיבה$$])[(floor(random() * 5) + 1)::INT]
FROM generate_series(1, 500);


-- =========================================================
-- Insert equipment assets
-- First 10,000 assets use equipment types that require serial numbers.
-- Next 10,000 assets use equipment types that do not require serial numbers.
-- =========================================================

INSERT INTO EquipmentAsset
(type_id, location_id, condition_status, intake_date, availability_status)
SELECT
    et.type_id,
    (floor(random() * 500) + 1)::INT AS location_id,
    (ARRAY[$$תקין$$, $$פגום$$, $$בתיקון$$, $$חסר$$])[(floor(random() * 4) + 1)::INT] AS condition_status,
    CURRENT_DATE - ((random() * 900)::INT) AS intake_date,
    (ARRAY[$$זמין$$, $$מוקצה$$, $$לא זמין$$])[(floor(random() * 3) + 1)::INT] AS availability_status
FROM generate_series(1, 20000) AS gs(i)
JOIN LATERAL (
    SELECT type_id
    FROM EquipmentType
    WHERE requires_serial_number = (gs.i <= 10000)
    ORDER BY random()
    LIMIT 1
) et ON TRUE;


-- =========================================================
-- Insert serialized equipment items
-- Only assets whose equipment type requires a serial number are inserted here.
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
-- Only assets whose equipment type does not require a serial number are inserted here.
-- =========================================================

INSERT INTO EquipmentStock (asset_id, quantity)
SELECT
    ea.asset_id,
    (floor(random() * 200) + 1)::INT AS quantity
FROM EquipmentAsset ea
JOIN EquipmentType et
    ON ea.type_id = et.type_id
WHERE et.requires_serial_number = FALSE;


-- =========================================================
-- Insert equipment assignments
-- Serialized equipment is always assigned with quantity 1.
-- Stock equipment can be assigned with a quantity between 1 and 10.
-- =========================================================

WITH assignment_source AS (
    SELECT
        (floor(random() * 20000) + 1)::INT AS asset_id,
        (floor(random() * 500) + 1)::INT AS recipient_id,
        CURRENT_DATE - ((random() * 365)::INT) AS assignment_date,
        random() AS status_roll
    FROM generate_series(1, 20000)
)
INSERT INTO EquipmentAssignment
(asset_id, recipient_id, assignment_date, return_date, assigned_quantity, assignment_status)
SELECT
    s.asset_id,
    s.recipient_id,
    s.assignment_date,
    CASE
        WHEN s.status_roll < 0.45 THEN NULL
        WHEN s.status_roll < 0.90 THEN s.assignment_date + ((random() * 90)::INT)
        ELSE NULL
    END AS return_date,
    CASE
        WHEN ei.asset_id IS NOT NULL THEN 1
        ELSE (floor(random() * 10) + 1)::INT
    END AS assigned_quantity,
    CASE
        WHEN s.status_roll < 0.45 THEN $$פעילה$$
        WHEN s.status_roll < 0.90 THEN $$הוחזרה$$
        ELSE $$בוטלה$$
    END AS assignment_status
FROM assignment_source s
LEFT JOIN EquipmentItem ei
    ON s.asset_id = ei.asset_id;


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
-- All three results should be 0.
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


-- =========================================================
-- M:N check
-- This query shows how many equipment types are linked to more than one category.
-- The result should be 500.
-- =========================================================

SELECT COUNT(*) AS equipment_types_with_multiple_categories
FROM (
    SELECT type_id
    FROM CategoryType
    GROUP BY type_id
    HAVING COUNT(category_id) > 1
) multi_category_types;
