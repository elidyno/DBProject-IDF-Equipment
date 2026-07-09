CREATE TABLE EquipmentCategory (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE EquipmentType (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    requires_serial_number BOOLEAN NOT NULL
);

CREATE TABLE CategoryType (
    category_id INT NOT NULL,
    type_id INT NOT NULL,
    PRIMARY KEY (category_id, type_id),
    FOREIGN KEY (category_id) REFERENCES EquipmentCategory(category_id),
    FOREIGN KEY (type_id) REFERENCES EquipmentType(type_id)
);

CREATE TABLE StorageLocation (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    location_type VARCHAR(50) NOT NULL
);

CREATE TABLE EquipmentAsset (
    asset_id SERIAL PRIMARY KEY,
    type_id INT NOT NULL,
    location_id INT NOT NULL,
    condition_status VARCHAR(50) NOT NULL,
    intake_date DATE NOT NULL,
    availability_status VARCHAR(50) NOT NULL,
    FOREIGN KEY (type_id) REFERENCES EquipmentType(type_id),
    FOREIGN KEY (location_id) REFERENCES StorageLocation(location_id),
    CHECK (condition_status IN ('תקין', 'פגום', 'בתיקון', 'חסר')),
    CHECK (availability_status IN ('זמין', 'מוקצה', 'לא זמין'))
);

CREATE TABLE EquipmentItem (
    asset_id INT PRIMARY KEY,
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (asset_id) REFERENCES EquipmentAsset(asset_id)
);

CREATE TABLE EquipmentStock (
    asset_id INT PRIMARY KEY,
    quantity INT NOT NULL,
    FOREIGN KEY (asset_id) REFERENCES EquipmentAsset(asset_id),
    CHECK (quantity >= 0)
);

CREATE TABLE Recipient (
    recipient_id SERIAL PRIMARY KEY,
    recipient_type VARCHAR(50) NOT NULL,
    CHECK (recipient_type IN ('חייל', 'צוות', 'פלוגה', 'גדוד', 'חטיבה'))
);

CREATE TABLE EquipmentAssignment (
    assignment_id SERIAL PRIMARY KEY,
    asset_id INT NOT NULL,
    recipient_id INT NOT NULL,
    assignment_date DATE NOT NULL,
    return_date DATE,
    assigned_quantity INT NOT NULL,
    assignment_status VARCHAR(50) NOT NULL,
    FOREIGN KEY (asset_id) REFERENCES EquipmentAsset(asset_id),
    FOREIGN KEY (recipient_id) REFERENCES Recipient(recipient_id),
    CHECK (assigned_quantity > 0),
    CHECK (assignment_status IN ('פעילה', 'הוחזרה', 'בוטלה')),
    CHECK (return_date IS NULL OR return_date >= assignment_date)
);
