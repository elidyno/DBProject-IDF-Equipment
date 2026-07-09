INSERT INTO EquipmentCategory (category_name) VALUES
('ציוד אישי'),
('ציוד צוותי'),
('ציוד פלוגתי'),
('ציוד גדודי'),
('ציוד חטיבתי');

INSERT INTO EquipmentType (type_name, requires_serial_number) VALUES
('מדי א', false),
('מדי ב', false),
('כיסא', false),
('שולחן', false),
('אוהל', true),
('דגל', true),
('ערכת בישול', false),
('ציוד חורף', false);

INSERT INTO CategoryType (category_id, type_id) VALUES
(1,1), (1,2), (1,8),
(2,5),
(3,3), (3,4), (3,7),
(4,6),
(5,3), (5,4), (5,6);

INSERT INTO StorageLocation (location_name, location_type) VALUES
('מחסן מרכזי', 'חטיבתי'),
('מחסן פלוגה א', 'פלוגתי'),
('מחסן פלוגה ב', 'פלוגתי'),
('מכולת ציוד 1', 'מכולה'),
('מכולת ציוד 2', 'מכולה');

INSERT INTO Recipient (recipient_type) VALUES
('חייל'),
('צוות'),
('פלוגה'),
('גדוד'),
('חטיבה');
