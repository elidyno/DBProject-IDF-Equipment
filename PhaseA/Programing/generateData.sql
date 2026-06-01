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

INSERT INTO EquipmentCategory (category_name)
SELECT 'קטגוריית ציוד ' || i
FROM generate_series(1, 500) AS i;

INSERT INTO EquipmentType (type_name, requires_serial_number)
SELECT 'סוג ציוד ' || i, (i % 2 = 0)
FROM generate_series(1, 500) AS i;

INSERT INTO CategoryType (category_id, type_id)
SELECT i, i
FROM generate_series(1, 500) AS i;

INSERT INTO StorageLocation (location_name, location_type)
SELECT 
  'מחסן ' || i,
  (ARRAY['פלוגתי','גדודי','חטיבתי','מכולה'])[floor(random()*4)+1]
FROM generate_series(1, 500) AS i;

INSERT INTO Recipient (recipient_type)
SELECT 
  (ARRAY['חייל','צוות','פלוגה','גדוד','חטיבה'])[floor(random()*5)+1]
FROM generate_series(1, 500);

-- יצירת 20,000 רשומות ציוד:
-- 10,000 ראשונות יקבלו type_id של סוג ציוד שדורש מספר סידורי
-- 10,000 הבאות יקבלו type_id של סוג ציוד שלא דורש מספר סידורי
INSERT INTO EquipmentAsset 
(type_id, location_id, condition_status, intake_date, availability_status)
SELECT
  CASE
    WHEN i <= 10000 THEN
      2 * ((floor(random() * 250) + 1)::int)      -- type_id זוגי: requires_serial_number = true
    ELSE
      2 * (floor(random() * 250)::int) + 1        -- type_id אי־זוגי: requires_serial_number = false
  END,
  (floor(random() * 500) + 1)::int,
  (ARRAY['תקין','פגום','בתיקון','חסר'])[floor(random()*4)+1],
  CURRENT_DATE - ((random() * 1000)::int),
  (ARRAY['זמין','מוקצה','לא זמין'])[floor(random()*3)+1]
FROM generate_series(1, 20000) AS i;

-- הכנסת ציוד בודד רק עבור סוגי ציוד שדורשים מספר סידורי
INSERT INTO EquipmentItem (asset_id, serial_number)
SELECT 
  ea.asset_id,
  'SN-' || ea.asset_id
FROM EquipmentAsset ea
JOIN EquipmentType et ON ea.type_id = et.type_id
WHERE et.requires_serial_number = true;

-- הכנסת ציוד מלאי רק עבור סוגי ציוד שלא דורשים מספר סידורי
INSERT INTO EquipmentStock (asset_id, quantity)
SELECT 
  ea.asset_id,
  (floor(random() * 200) + 1)::int
FROM EquipmentAsset ea
JOIN EquipmentType et ON ea.type_id = et.type_id
WHERE et.requires_serial_number = false;

-- יצירת 20,000 הקצאות ציוד
-- אם מדובר בציוד עם מספר סידורי, assigned_quantity יהיה 1
-- אם מדובר בציוד מלאי, assigned_quantity יהיה מספר אקראי בין 1 ל־10
WITH assignment_source AS (
  SELECT
    (floor(random() * 20000) + 1)::int AS asset_id,
    (floor(random() * 500) + 1)::int AS recipient_id,
    CURRENT_DATE - ((random() * 365)::int) AS assignment_date,
    random() AS return_probability
  FROM generate_series(1, 20000)
)
INSERT INTO EquipmentAssignment
(asset_id, recipient_id, assignment_date, return_date, assigned_quantity, assignment_status)
SELECT
  s.asset_id,
  s.recipient_id,
  s.assignment_date,
  CASE 
    WHEN s.return_probability < 0.5 THEN NULL
    ELSE s.assignment_date + ((random() * 100)::int)
  END,
  CASE
    WHEN ei.asset_id IS NOT NULL THEN 1
    ELSE (floor(random() * 10) + 1)::int
  END,
  (ARRAY['פעילה','הוחזרה','בוטלה'])[floor(random()*3)+1]
FROM assignment_source s
LEFT JOIN EquipmentItem ei ON s.asset_id = ei.asset_id;
