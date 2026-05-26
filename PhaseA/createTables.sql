CREATE TABLE EquipmentCategory (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE EquipmentType (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    requires_serial_number BOOLEAN
);

CREATE TABLE CategoryType (
    category_id INT,
    type_id INT,
    PRIMARY KEY (category_id, type_id),
    FOREIGN KEY (category_id) REFERENCES EquipmentCategory(category_id),
    FOREIGN KEY (type_id) REFERENCES EquipmentType(type_id)
);

CREATE TABLE StorageLocation (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(100),
    location_type VARCHAR(50)
);

CREATE TABLE EquipmentAsset (
    asset_id SERIAL PRIMARY KEY,
    type_id INT,
    location_id INT,
    condition_status VARCHAR(50),
    intake_date DATE,
    availability_status VARCHAR(50),
    FOREIGN KEY (type_id) REFERENCES EquipmentType(type_id),
    FOREIGN KEY (location_id) REFERENCES StorageLocation(location_id)
);

CREATE TABLE EquipmentItem (
    asset_id INT PRIMARY KEY,
    serial_number VARCHAR(100),
    FOREIGN KEY (asset_id) REFERENCES EquipmentAsset(asset_id)
);

CREATE TABLE EquipmentStock (
    asset_id INT PRIMARY KEY,
    quantity INT,
    FOREIGN KEY (asset_id) REFERENCES EquipmentAsset(asset_id)
);

CREATE TABLE Recipient (
    recipient_id SERIAL PRIMARY KEY,
    recipient_type VARCHAR(50)
);

CREATE TABLE EquipmentAssignment (
    assignment_id SERIAL PRIMARY KEY,
    asset_id INT,
    recipient_id INT,
    assignment_date DATE,
    return_date DATE,
    assigned_quantity INT,
    assignment_status VARCHAR(50),
    FOREIGN KEY (asset_id) REFERENCES EquipmentAsset(asset_id),
    FOREIGN KEY (recipient_id) REFERENCES Recipient(recipient_id)
);
