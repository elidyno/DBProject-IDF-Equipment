-- ============================================================
-- dropTables.sql
-- Phase C - Integrated Database Schema
-- Drops all Phase C tables in a safe order
-- PostgreSQL / Neon
-- ============================================================

-- Drop circular foreign key first
ALTER TABLE IF EXISTS MilitaryUnit
DROP CONSTRAINT IF EXISTS fk_military_unit_commander;

-- ============================================================
-- 1. Armory dependent tables
-- ============================================================

DROP TABLE IF EXISTS Maintenance;
DROP TABLE IF EXISTS MaintenanceType;

DROP TABLE IF EXISTS AmmoIssue;
DROP TABLE IF EXISTS Ammunition;
DROP TABLE IF EXISTS AmmoType;

DROP TABLE IF EXISTS WeaponAssignment;
DROP TABLE IF EXISTS Weapon;
DROP TABLE IF EXISTS WeaponStatus;
DROP TABLE IF EXISTS WeaponType;

-- ============================================================
-- 2. Logistics dependent tables
-- ============================================================

DROP TABLE IF EXISTS EquipmentAssignment;

DROP TABLE IF EXISTS Recipient;

DROP TABLE IF EXISTS EquipmentItem;
DROP TABLE IF EXISTS EquipmentStock;
DROP TABLE IF EXISTS EquipmentAsset;

DROP TABLE IF EXISTS StorageLocation;

DROP TABLE IF EXISTS CategoryType;
DROP TABLE IF EXISTS EquipmentType;
DROP TABLE IF EXISTS EquipmentCategory;

-- ============================================================
-- 3. Core integration tables
-- ============================================================

DROP TABLE IF EXISTS Soldier;
DROP TABLE IF EXISTS MilitaryUnit;
DROP TABLE IF EXISTS Rank;
DROP TABLE IF EXISTS MilitaryEntity;