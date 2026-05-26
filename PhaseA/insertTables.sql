INSERT INTO EquipmentCategory (category_name) VALUES
('ציוד אישי'),
('ציוד צוותי'),
('ציוד פלוגתי');

INSERT INTO EquipmentType (type_name, requires_serial_number) VALUES
('מדי א', true),
('כיסא', false),
('אוהל', true);

INSERT INTO StorageLocation (location_name, location_type) VALUES
('מחסן א', 'פלוגתי'),
('מחסן ב', 'גדודי');

INSERT INTO Recipient (recipient_type) VALUES
('חייל'),
('צוות'),
('פלוגה');
