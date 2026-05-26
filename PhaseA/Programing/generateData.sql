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

INSERT INTO EquipmentAsset 
(type_id, location_id, condition_status, intake_date, availability_status)
SELECT
  (floor(random() * 500) + 1)::int,
  (floor(random() * 500) + 1)::int,
  (ARRAY['תקין','פגום','בתיקון','חסר'])[floor(random()*4)+1],
  CURRENT_DATE - ((random() * 1000)::int),
  (ARRAY['זמין','מוקצה','לא זמין'])[floor(random()*3)+1]
FROM generate_series(1, 20000);

INSERT INTO EquipmentItem (asset_id, serial_number)
SELECT asset_id, 'SN-' || asset_id
FROM EquipmentAsset
WHERE asset_id % 2 = 1;

INSERT INTO EquipmentStock (asset_id, quantity)
SELECT asset_id, (floor(random() * 200) + 1)::int
FROM EquipmentAsset
WHERE asset_id % 2 = 0;

INSERT INTO EquipmentAssignment
(asset_id, recipient_id, assignment_date, return_date, assigned_quantity, assignment_status)
SELECT
  (floor(random() * 20000) + 1)::int,
  (floor(random() * 500) + 1)::int,
  assignment_date,
  CASE 
    WHEN random() < 0.5 THEN NULL
    ELSE assignment_date + ((random() * 100)::int)
  END,
  (floor(random() * 10) + 1)::int,
  (ARRAY['פעילה','הוחזרה','בוטלה'])[floor(random()*3)+1]
FROM (
  SELECT
    CURRENT_DATE - ((random() * 365)::int) AS assignment_date
  FROM generate_series(1, 20000)
) t;
