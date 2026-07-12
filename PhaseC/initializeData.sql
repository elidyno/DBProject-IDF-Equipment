-- ============================================================
-- initializeData.sql
-- Phase C - Initial data for the integrated database
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- 1. Core integration layer data
-- ============================================================

INSERT INTO Rank (rank_id, rank_name) VALUES
(1, 'טוראי'),
(2, 'רב טוראי'),
(3, 'סמל'),
(4, 'סמ"ר'),
(5, 'רס"ל'),
(6, 'סג"ם'),
(7, 'סגן'),
(8, 'סרן');

INSERT INTO MilitaryEntity (entity_id, entity_type, entity_name) VALUES
(1, 'חטיבה', 'חטיבת מילואים 55'),
(2, 'גדוד', 'גדוד חי"ר 701'),
(3, 'גדוד', 'גדוד חי"ר 702'),
(4, 'פלוגה', 'פלוגה א'),
(5, 'פלוגה', 'פלוגה ב'),
(6, 'פלוגה', 'פלוגה ג'),
(7, 'פלוגה', 'פלוגת מסייעת'),
(8, 'צוות', 'צוות אלפא'),
(9, 'צוות', 'צוות ברק'),
(10, 'צוות', 'צוות גולן');

INSERT INTO MilitaryUnit (entity_id, unit_id, unit_name, company, commander_entity_id) VALUES
(1, 'BDE-55', 'חטיבת מילואים 55', NULL, NULL),
(2, 'BN-701', 'גדוד חי"ר 701', NULL, NULL),
(3, 'BN-702', 'גדוד חי"ר 702', NULL, NULL),
(4, 'CO-A', 'פלוגה א', 'א', NULL),
(5, 'CO-B', 'פלוגה ב', 'ב', NULL),
(6, 'CO-C', 'פלוגה ג', 'ג', NULL),
(7, 'CO-S', 'פלוגת מסייעת', 'מסייעת', NULL),
(8, 'TM-A', 'צוות אלפא', 'א', NULL),
(9, 'TM-B', 'צוות ברק', 'ב', NULL),
(10, 'TM-G', 'צוות גולן', 'ג', NULL);

INSERT INTO MilitaryEntity (entity_id, entity_type, entity_name)
SELECT
    1000 + gs,
    'חייל',
    'חייל ' || gs
FROM generate_series(1, 120) AS gs;

INSERT INTO Soldier (
    entity_id,
    soldier_id,
    first_name,
    last_name,
    enlistment_date,
    phone,
    rank_id,
    unit_entity_id
)
SELECT
    1000 + gs,
    'S' || LPAD(gs::TEXT, 5, '0'),
    (ARRAY['אלון', 'דניאל', 'יואב', 'איתי', 'נועם', 'עידו', 'אורי', 'רועי', 'איתן', 'גלעד'])[(gs % 10) + 1],
    (ARRAY['כהן', 'לוי', 'מזרחי', 'פרץ', 'דוד', 'אברהמי', 'שלום', 'ביטון', 'חדד', 'רוזן'])[(gs % 10) + 1],
    DATE '2018-01-01' + (gs * 13),
    '05' || LPAD((10000000 + gs)::TEXT, 8, '0'),
    ((gs - 1) % 8) + 1,
    ((gs - 1) % 7) + 4
FROM generate_series(1, 120) AS gs;

UPDATE MilitaryUnit
SET commander_entity_id =
    CASE entity_id
        WHEN 1 THEN 1001
        WHEN 2 THEN 1002
        WHEN 3 THEN 1003
        WHEN 4 THEN 1004
        WHEN 5 THEN 1005
        WHEN 6 THEN 1006
        WHEN 7 THEN 1007
        WHEN 8 THEN 1008
        WHEN 9 THEN 1009
        WHEN 10 THEN 1010
    END
WHERE entity_id BETWEEN 1 AND 10;

-- ============================================================
-- 2. Logistics system data
-- ============================================================

INSERT INTO EquipmentCategory (category_id, category_name) VALUES
(1, 'ציוד אישי'),
(2, 'ציוד צוותי'),
(3, 'ציוד פלוגתי'),
(4, 'ציוד גדודי'),
(5, 'ציוד חטיבתי');

INSERT INTO EquipmentType (type_id, type_name, requires_serial_number) VALUES
(1, 'מכשיר קשר ידני', TRUE),
(2, 'מחשב מוקשח', TRUE),
(3, 'ערכת ניווט', TRUE),
(4, 'גנרטור קטן', TRUE),
(5, 'מצלמה תרמית', TRUE),
(6, 'רחפן תצפית', TRUE),
(7, 'ערכת קשר פלוגתית', TRUE),
(8, 'מכשיר לווייני', TRUE),
(9, 'מדי א', FALSE),
(10, 'מדי ב', FALSE),
(11, 'קסדה', FALSE),
(12, 'אפוד', FALSE),
(13, 'שולחן מתקפל', FALSE),
(14, 'כיסא מתקפל', FALSE),
(15, 'אוהל צוות', FALSE),
(16, 'שק שינה', FALSE),
(17, 'ערכת עזרה ראשונה', FALSE),
(18, 'ג׳ריקן מים', FALSE),
(19, 'מזרן שטח', FALSE),
(20, 'ערכת תאורה', FALSE);

INSERT INTO CategoryType (category_id, type_id) VALUES
(1, 1), (1, 2), (1, 9), (1, 10), (1, 11), (1, 12),
(2, 1), (2, 3), (2, 6), (2, 15), (2, 16), (2, 17),
(3, 4), (3, 7), (3, 13), (3, 14), (3, 18), (3, 20),
(4, 5), (4, 7), (4, 15), (4, 17), (4, 18), (4, 19),
(5, 2), (5, 4), (5, 5), (5, 8), (5, 20);

INSERT INTO StorageLocation (location_id, location_name, location_type) VALUES
(1, 'מחסן מרכזי חטיבתי', 'מחסן'),
(2, 'מחסן גדוד 701', 'מחסן'),
(3, 'מחסן גדוד 702', 'מחסן'),
(4, 'מכולת ציוד פלוגה א', 'מכולה'),
(5, 'מכולת ציוד פלוגה ב', 'מכולה'),
(6, 'מכולת ציוד פלוגה ג', 'מכולה'),
(7, 'חדר קשר', 'חדר ציוד'),
(8, 'מחסן רפואי', 'מחסן'),
(9, 'מחסן שטח', 'מחסן'),
(10, 'אזור ציוד פגום', 'אזור אחסון');

INSERT INTO MilitaryEntity (entity_id, entity_type, entity_name)
SELECT
    2000 + gs,
    CASE
        WHEN gs <= 5 THEN 'חטיבה'
        WHEN gs <= 15 THEN 'גדוד'
        WHEN gs <= 35 THEN 'פלוגה'
        ELSE 'צוות'
    END,
    'גורם מקבל נוסף ' || gs
FROM generate_series(1, 40) AS gs;

INSERT INTO MilitaryUnit (entity_id, unit_id, unit_name, company, commander_entity_id)
SELECT
    entity_id,
    'EXT-' || entity_id,
    entity_name,
    CASE
        WHEN entity_type = 'פלוגה' THEN 'מילואים'
        WHEN entity_type = 'צוות' THEN 'צוות'
        ELSE NULL
    END,
    NULL
FROM MilitaryEntity
WHERE entity_id BETWEEN 2001 AND 2040;

INSERT INTO Recipient (recipient_type, entity_id)
SELECT
    me.entity_type,
    s.entity_id
FROM Soldier s
JOIN MilitaryEntity me
    ON s.entity_id = me.entity_id
WHERE s.entity_id BETWEEN 1001 AND 1080
  AND me.entity_type = 'חייל'

UNION ALL

SELECT
    me.entity_type,
    mu.entity_id
FROM MilitaryUnit mu
JOIN MilitaryEntity me
    ON mu.entity_id = me.entity_id
WHERE (
        mu.entity_id BETWEEN 1 AND 10
        OR mu.entity_id BETWEEN 2001 AND 2040
      )
  AND me.entity_type IN ('צוות', 'פלוגה', 'גדוד', 'חטיבה')

ORDER BY entity_id;

INSERT INTO EquipmentAsset (
    asset_id,
    type_id,
    location_id,
    condition_status,
    intake_date,
    availability_status
)
SELECT
    gs,
    ((gs - 1) % 20) + 1,
    ((gs - 1) % 10) + 1,
    CASE
        WHEN gs % 29 = 0 THEN 'חסר'
        WHEN gs % 17 = 0 THEN 'בתיקון'
        WHEN gs % 11 = 0 THEN 'פגום'
        ELSE 'תקין'
    END,
    DATE '2021-01-01' + (gs * 3),
    CASE
        WHEN gs % 29 = 0 THEN 'לא זמין'
        WHEN gs % 17 = 0 THEN 'לא זמין'
        WHEN gs % 11 = 0 THEN 'לא זמין'
        ELSE 'זמין'
    END
FROM generate_series(1, 300) AS gs;

INSERT INTO EquipmentItem (asset_id, serial_number)
SELECT
    ea.asset_id,
    'EQ-SN-' || LPAD(ea.asset_id::TEXT, 6, '0')
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
WHERE et.requires_serial_number = TRUE;

INSERT INTO EquipmentStock (asset_id, quantity)
SELECT
    ea.asset_id,
    50 + (ea.asset_id % 300)
FROM EquipmentAsset ea
JOIN EquipmentType et
ON ea.type_id = et.type_id
WHERE et.requires_serial_number = FALSE;

INSERT INTO EquipmentAssignment (
    asset_id,
    recipient_id,
    assignment_date,
    return_date,
    assigned_quantity,
    assignment_status
)
WITH valid_assets AS (
    SELECT
        ea.asset_id,
        ea.intake_date,
        et.requires_serial_number,
        ROW_NUMBER() OVER (ORDER BY ea.asset_id) AS rn,
        COUNT(*) OVER () AS total_assets
    FROM EquipmentAsset ea
    JOIN EquipmentType et
    ON ea.type_id = et.type_id
    WHERE ea.condition_status = 'תקין'
),
recipient_list AS (
    SELECT
        recipient_id,
        ROW_NUMBER() OVER (ORDER BY recipient_id) AS rn,
        COUNT(*) OVER () AS total_recipients
    FROM Recipient
)
SELECT
    va.asset_id,
    rl.recipient_id,
    va.intake_date + ((va.rn % 180)::INT),
    CASE
        WHEN va.rn % 12 = 0 THEN NULL
        WHEN va.rn % 4 = 0 THEN va.intake_date + ((va.rn % 180)::INT) + (((va.rn % 30) + 1)::INT)
        ELSE NULL
    END,
    CASE
        WHEN va.requires_serial_number = TRUE THEN 1
        ELSE (((va.rn % 20) + 1)::INT)
    END,
    CASE
        WHEN va.rn % 12 = 0 THEN 'בוטלה'
        WHEN va.rn % 4 = 0 THEN 'הוחזרה'
        ELSE 'פעילה'
    END
FROM valid_assets va
JOIN recipient_list rl
ON rl.rn = ((va.rn - 1) % rl.total_recipients) + 1;

UPDATE EquipmentAsset
SET availability_status = 'מוקצה'
WHERE asset_id IN (
    SELECT asset_id
    FROM EquipmentAssignment
    WHERE assignment_status = 'פעילה'
);

UPDATE EquipmentAsset
SET availability_status = 'לא זמין'
WHERE condition_status <> 'תקין'
  AND asset_id NOT IN (
      SELECT asset_id
      FROM EquipmentAssignment
      WHERE assignment_status = 'פעילה'
  );

-- ============================================================
-- 3. Armory system data
-- ============================================================

INSERT INTO WeaponType (type_id, type_name) VALUES
(1, 'רובה סער'),
(2, 'מקלע קל'),
(3, 'אקדח'),
(4, 'מטול'),
(5, 'רובה צלפים'),
(6, 'מקלע בינוני');

INSERT INTO WeaponStatus (status_id, status_name) VALUES
(1, 'תקין'),
(2, 'מוקצה'),
(3, 'בתחזוקה'),
(4, 'פגום'),
(5, 'הושבת');

INSERT INTO Weapon (serial_number, type_id, status_id, model, manufacture_year, entry_date)
SELECT
    'WPN-' || LPAD(gs::TEXT, 5, '0'),
    ((gs - 1) % 6) + 1,
    CASE
        WHEN gs % 19 = 0 THEN 4
        WHEN gs % 13 = 0 THEN 3
        ELSE 1
    END,
    CASE ((gs - 1) % 6) + 1
        WHEN 1 THEN 'M4'
        WHEN 2 THEN 'Negev'
        WHEN 3 THEN 'Glock 19'
        WHEN 4 THEN 'M203'
        WHEN 5 THEN 'Barak'
        ELSE 'MAG'
    END,
    2000 + (gs % 24),
    DATE '2020-01-01' + (gs * 8)
FROM generate_series(1, 120) AS gs;

INSERT INTO WeaponAssignment (
    serial_number,
    soldier_entity_id,
    assignment_date,
    return_date,
    return_reason
)
WITH valid_weapons AS (
    SELECT
        serial_number,
        ROW_NUMBER() OVER (ORDER BY serial_number) AS rn,
        COUNT(*) OVER () AS total_weapons
    FROM Weapon
    WHERE status_id = 1
),
soldier_list AS (
    SELECT
        entity_id,
        ROW_NUMBER() OVER (ORDER BY entity_id) AS rn,
        COUNT(*) OVER () AS total_soldiers
    FROM Soldier
)
SELECT
    vw.serial_number,
    sl.entity_id,
    DATE '2023-01-01' + ((vw.rn * 2)::INT),
    CASE
        WHEN vw.rn % 3 = 0 THEN DATE '2023-01-01' + ((vw.rn * 2)::INT) + (((vw.rn % 40) + 1)::INT)
        ELSE NULL
    END,
    CASE
        WHEN vw.rn % 3 = 0 THEN 'הוחזר לאחר אימון'
        ELSE NULL
    END
FROM valid_weapons vw
JOIN soldier_list sl
ON sl.rn = ((vw.rn - 1) % sl.total_soldiers) + 1;

UPDATE Weapon
SET status_id = 2
WHERE serial_number IN (
    SELECT serial_number
    FROM WeaponAssignment
    WHERE return_date IS NULL
);

INSERT INTO AmmoType (ammo_type_id, type_name) VALUES
(1, 'תחמושת רובה'),
(2, 'תחמושת מקלע'),
(3, 'תחמושת אקדח'),
(4, 'רימון מטול'),
(5, 'תחמושת צלפים');

INSERT INTO Ammunition (
    ammo_id,
    ammo_type_id,
    caliber,
    stock_quantity,
    minimum_stock
)
SELECT
    gs,
    ((gs - 1) % 5) + 1,
    CASE ((gs - 1) % 5) + 1
        WHEN 1 THEN '5.56mm'
        WHEN 2 THEN '7.62mm'
        WHEN 3 THEN '9mm'
        WHEN 4 THEN '40mm'
        ELSE '0.338'
    END,
    5000 + (gs * 350),
    500 + (gs * 20)
FROM generate_series(1, 10) AS gs;

INSERT INTO AmmoIssue (
    ammo_id,
    soldier_entity_id,
    quantity,
    issue_date,
    purpose
)
SELECT
    ((gs - 1) % 10) + 1,
    1000 + (((gs - 1) % 120) + 1),
    5 + (gs % 120),
    DATE '2023-06-01' + (gs * 2),
    CASE
        WHEN gs % 3 = 0 THEN 'אימון'
        WHEN gs % 3 = 1 THEN 'תרגיל גדודי'
        ELSE 'פעילות מבצעית'
    END
FROM generate_series(1, 200) AS gs;

INSERT INTO MaintenanceType (maint_type_id, type_name) VALUES
(1, 'בדיקה תקופתית'),
(2, 'ניקוי נשק'),
(3, 'תיקון תקלה'),
(4, 'החלפת חלק'),
(5, 'בדיקת בטיחות');

INSERT INTO Maintenance (
    serial_number,
    technician_entity_id,
    maint_type_id,
    maintenance_date,
    description,
    status_after
)
WITH non_active_weapons AS (
    SELECT
        w.serial_number,
        ROW_NUMBER() OVER (ORDER BY w.serial_number) AS rn,
        COUNT(*) OVER () AS total_weapons
    FROM Weapon w
    WHERE w.serial_number NOT IN (
        SELECT wa.serial_number
        FROM WeaponAssignment wa
        WHERE wa.return_date IS NULL
    )
),
soldier_list AS (
    SELECT
        entity_id,
        ROW_NUMBER() OVER (ORDER BY entity_id) AS rn,
        COUNT(*) OVER () AS total_soldiers
    FROM Soldier
),
maintenance_base AS (
    SELECT
        gs,
        naw.serial_number,
        sl.entity_id AS technician_entity_id
    FROM generate_series(1, 100) AS gs
    JOIN non_active_weapons naw
    ON naw.rn = ((gs - 1) % naw.total_weapons) + 1
    JOIN soldier_list sl
    ON sl.rn = ((gs + 10 - 1) % sl.total_soldiers) + 1
)
SELECT
    serial_number,
    technician_entity_id,
    (((gs - 1) % 5) + 1)::INT,
    DATE '2023-01-15' + ((gs * 5)::INT),
    CASE
        WHEN gs % 5 = 0 THEN 'בוצע תיקון בעקבות תקלה'
        WHEN gs % 5 = 1 THEN 'בוצעה בדיקה תקופתית'
        WHEN gs % 5 = 2 THEN 'בוצע ניקוי נשק'
        WHEN gs % 5 = 3 THEN 'בוצעה החלפת חלק'
        ELSE 'בוצעה בדיקת בטיחות'
    END,
    CASE
        WHEN gs % 17 = 0 THEN 'בתיקון'
        WHEN gs % 13 = 0 THEN 'פגום'
        ELSE 'תקין'
    END
FROM maintenance_base;

WITH latest_maintenance AS (
    SELECT DISTINCT ON (serial_number)
        serial_number,
        status_after
    FROM Maintenance
    ORDER BY serial_number, maintenance_date DESC, maintenance_id DESC
)
UPDATE Weapon w
SET status_id =
    CASE lm.status_after
        WHEN 'תקין' THEN 1
        WHEN 'בתיקון' THEN 3
        WHEN 'פגום' THEN 4
        WHEN 'הושבת' THEN 5
        ELSE w.status_id
    END
FROM latest_maintenance lm
WHERE w.serial_number = lm.serial_number
  AND w.serial_number NOT IN (
      SELECT wa.serial_number
      FROM WeaponAssignment wa
      WHERE wa.return_date IS NULL
  );

-- ============================================================
-- 4. Reset sequences after explicit IDs
-- ============================================================

SELECT setval(pg_get_serial_sequence('MilitaryEntity', 'entity_id'), (SELECT MAX(entity_id) FROM MilitaryEntity));
SELECT setval(pg_get_serial_sequence('Rank', 'rank_id'), (SELECT MAX(rank_id) FROM Rank));
SELECT setval(pg_get_serial_sequence('EquipmentCategory', 'category_id'), (SELECT MAX(category_id) FROM EquipmentCategory));
SELECT setval(pg_get_serial_sequence('EquipmentType', 'type_id'), (SELECT MAX(type_id) FROM EquipmentType));
SELECT setval(pg_get_serial_sequence('StorageLocation', 'location_id'), (SELECT MAX(location_id) FROM StorageLocation));
SELECT setval(pg_get_serial_sequence('EquipmentAsset', 'asset_id'), (SELECT MAX(asset_id) FROM EquipmentAsset));
SELECT setval(pg_get_serial_sequence('Recipient', 'recipient_id'), (SELECT MAX(recipient_id) FROM Recipient));
SELECT setval(pg_get_serial_sequence('EquipmentAssignment', 'assignment_id'), (SELECT MAX(assignment_id) FROM EquipmentAssignment));
SELECT setval(pg_get_serial_sequence('WeaponType', 'type_id'), (SELECT MAX(type_id) FROM WeaponType));
SELECT setval(pg_get_serial_sequence('WeaponStatus', 'status_id'), (SELECT MAX(status_id) FROM WeaponStatus));
SELECT setval(pg_get_serial_sequence('AmmoType', 'ammo_type_id'), (SELECT MAX(ammo_type_id) FROM AmmoType));
SELECT setval(pg_get_serial_sequence('Ammunition', 'ammo_id'), (SELECT MAX(ammo_id) FROM Ammunition));
SELECT setval(pg_get_serial_sequence('AmmoIssue', 'issue_id'), (SELECT MAX(issue_id) FROM AmmoIssue));
SELECT setval(pg_get_serial_sequence('MaintenanceType', 'maint_type_id'), (SELECT MAX(maint_type_id) FROM MaintenanceType));
SELECT setval(pg_get_serial_sequence('Maintenance', 'maintenance_id'), (SELECT MAX(maintenance_id) FROM Maintenance));