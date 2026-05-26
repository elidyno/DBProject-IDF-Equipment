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

-- 500 categories
INSERT INTO EquipmentCategory (category_name)
SELECT 'קטגוריית ציוד ' || i
FROM generate_series(1, 500) AS i;

-- 500 types
INSERT INTO EquipmentType (type_name, requires_serial_number)
SELECT 'סוג ציוד ' || i, (i % 2 = 0)
FROM generate_series(1, 500) AS i;

-- 500 category-type links
INSERT INTO CategoryType (category_id, type_id)
SELECT i, i
FROM generate_series(1, 500) AS i;

-- 500 storage locations
INSERT INTO StorageLocation (location_name, location_type)
SELECT 
  'מחסן ' || i,
  (ARRAY['פלוגתי','גדודי','חטיבתי','מכולה'])[floor(random()*4)+1]
FROM generate_series(1, 500) AS i;

-- 500 recipients
INSERT INTO Recipient (recipient_type)
SELECT 
  (ARRAY['חייל','צוות','פלוגה','גדוד','חטיבה'])[floor(random()*5)+1]
FROM generate_series(1, 500);

-- 20,000 equipment assets
INSERT INTO EquipmentAsset 
(type_id, location_id, condition_status, intake_date, availability_status)
SELECT
  (floor(random() * 500) + 1)::int,
  (floor(random() * 500) + 1)::int,
  (ARRAY['תקין','פגום','בתיקון','חסר'])[floor(random()*4)+1],
  CURRENT_DATE - ((random() * 1000)::int),
  (ARRAY['זמין','מוקצה','לא זמין'])[floor(random()*3)+1]
FROM generate_series(1, 20000);

-- 10,000 serialized items
INSERT INTO EquipmentItem (asset_id, serial_number)
SELECT asset_id, 'SN-' || asset_id
FROM EquipmentAsset
WHERE asset_id % 2 = 1;

-- 10,000 stock records
INSERT INTO EquipmentStock (asset_id, quantity)
SELECT asset_id, (floor(random() * 200) + 1)::int
FROM EquipmentAsset
WHERE asset_id % 2 = 0;

-- 20,000 assignments
INSERT INTO EquipmentAssignment
(asset_id, recipient_id, assignment_date, return_date, assigned_quantity, assignment_status)
SELECT
  (floor(random() * 20000) + 1)::int,
  (floor(random() * 500) + 1)::int,
  CURRENT_DATE - ((random() * 365)::int),
  CASE 
    WHEN random() < 0.5 THEN NULL
    ELSE CURRENT_DATE - ((random() * 100)::int)
  END,
  (floor(random() * 10) + 1)::int,
  (ARRAY['פעילה','הוחזרה','בוטלה'])[floor(random()*3)+1]
FROM generate_series(1, 20000);
