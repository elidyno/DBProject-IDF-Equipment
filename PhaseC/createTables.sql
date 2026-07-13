-- ============================================================
-- createTables.sql
-- Phase D refactor - Integrated database schema
-- Military Equipment Logistics + Armory System
-- PostgreSQL / Neon
-- ============================================================

-- ============================================================
-- 1. Core integration layer
-- ============================================================

CREATE TABLE MilitaryEntity (
    entity_id SERIAL PRIMARY KEY
);

CREATE TABLE Rank (
    rank_id SERIAL PRIMARY KEY,
    rank_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE MilitaryUnit (
    entity_id INT PRIMARY KEY,
    unit_id VARCHAR(50) NOT NULL UNIQUE,
    unit_name VARCHAR(100) NOT NULL,
    unit_level VARCHAR(50) NOT NULL,
    company VARCHAR(50),
    commander_entity_id INT,
    FOREIGN KEY (entity_id) REFERENCES MilitaryEntity(entity_id),
    CHECK (unit_level IN ('צוות', 'פלוגה', 'גדוד', 'חטיבה'))
);

CREATE TABLE Soldier (
    entity_id INT PRIMARY KEY,
    soldier_id VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    enlistment_date DATE NOT NULL,
    phone VARCHAR(20),
    rank_id INT NOT NULL,
    unit_entity_id INT NOT NULL,
    FOREIGN KEY (entity_id) REFERENCES MilitaryEntity(entity_id),
    FOREIGN KEY (rank_id) REFERENCES Rank(rank_id),
    FOREIGN KEY (unit_entity_id) REFERENCES MilitaryUnit(entity_id)
);

ALTER TABLE MilitaryUnit
ADD CONSTRAINT fk_militaryunit_commander
FOREIGN KEY (commander_entity_id) REFERENCES Soldier(entity_id);

-- ============================================================
-- 2. Logistics system
-- ============================================================

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
    entity_id INT NOT NULL UNIQUE,
    FOREIGN KEY (entity_id) REFERENCES MilitaryEntity(entity_id)
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

-- ============================================================
-- 3. Armory system
-- ============================================================

CREATE TABLE WeaponType (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE WeaponStatus (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Weapon (
    serial_number VARCHAR(100) PRIMARY KEY,
    type_id INT NOT NULL,
    status_id INT NOT NULL,
    model VARCHAR(100) NOT NULL,
    manufacture_year INT NOT NULL,
    entry_date DATE NOT NULL,
    FOREIGN KEY (type_id) REFERENCES WeaponType(type_id),
    FOREIGN KEY (status_id) REFERENCES WeaponStatus(status_id),
    CHECK (manufacture_year >= 1950)
);

CREATE TABLE WeaponAssignment (
    assignment_id SERIAL PRIMARY KEY,
    serial_number VARCHAR(100) NOT NULL,
    soldier_entity_id INT NOT NULL,
    assignment_date DATE NOT NULL,
    return_date DATE,
    return_reason VARCHAR(200),
    FOREIGN KEY (serial_number) REFERENCES Weapon(serial_number),
    FOREIGN KEY (soldier_entity_id) REFERENCES Soldier(entity_id),
    CHECK (return_date IS NULL OR return_date >= assignment_date),
    CHECK (
        (return_date IS NULL AND return_reason IS NULL)
        OR
        (return_date IS NOT NULL)
    )
);

CREATE TABLE AmmoType (
    ammo_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Ammunition (
    ammo_id SERIAL PRIMARY KEY,
    ammo_type_id INT NOT NULL,
    caliber VARCHAR(50) NOT NULL,
    stock_quantity INT NOT NULL,
    minimum_stock INT NOT NULL,
    FOREIGN KEY (ammo_type_id) REFERENCES AmmoType(ammo_type_id),
    CHECK (stock_quantity >= 0),
    CHECK (minimum_stock >= 0),
    CHECK (stock_quantity >= minimum_stock)
);

CREATE TABLE AmmoIssue (
    issue_id SERIAL PRIMARY KEY,
    ammo_id INT NOT NULL,
    soldier_entity_id INT NOT NULL,
    quantity INT NOT NULL,
    issue_date DATE NOT NULL,
    purpose VARCHAR(100) NOT NULL,
    FOREIGN KEY (ammo_id) REFERENCES Ammunition(ammo_id),
    FOREIGN KEY (soldier_entity_id) REFERENCES Soldier(entity_id),
    CHECK (quantity > 0)
);

CREATE TABLE MaintenanceType (
    maint_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Maintenance (
    maintenance_id SERIAL PRIMARY KEY,
    serial_number VARCHAR(100) NOT NULL,
    technician_entity_id INT NOT NULL,
    maint_type_id INT NOT NULL,
    maintenance_date DATE NOT NULL,
    description TEXT,
    status_after VARCHAR(50) NOT NULL,
    FOREIGN KEY (serial_number) REFERENCES Weapon(serial_number),
    FOREIGN KEY (technician_entity_id) REFERENCES Soldier(entity_id),
    FOREIGN KEY (maint_type_id) REFERENCES MaintenanceType(maint_type_id),
    CHECK (status_after IN ('תקין', 'בתיקון', 'פגום', 'הושבת'))
);

-- ============================================================
-- 4. Helpful indexes
-- ============================================================

CREATE INDEX idx_recipient_entity_id
ON Recipient(entity_id);

CREATE INDEX idx_soldier_unit_entity_id
ON Soldier(unit_entity_id);

CREATE INDEX idx_equipmentassignment_recipient_id
ON EquipmentAssignment(recipient_id);

CREATE INDEX idx_equipmentassignment_asset_id
ON EquipmentAssignment(asset_id);

CREATE INDEX idx_weaponassignment_soldier_entity_id
ON WeaponAssignment(soldier_entity_id);

CREATE INDEX idx_weaponassignment_serial_number
ON WeaponAssignment(serial_number);

CREATE INDEX idx_ammoissue_soldier_entity_id
ON AmmoIssue(soldier_entity_id);

CREATE INDEX idx_maintenance_technician_entity_id
ON Maintenance(technician_entity_id);