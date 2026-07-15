// ============================================================
// server.js
// Phase E - Simple Express API for the course project database
// Military Equipment Logistics + Armory System
// PostgreSQL / Neon
//
// All routes live in this single file on purpose:
// this is a database course demo, not a production application.
// ============================================================

require('dotenv').config();

const express = require('express');
const path = require('path');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());


// Serve the Phase E frontend from the same local server.
const frontendPath = path.join(__dirname, '..', 'frontend');
app.use(express.static(frontendPath));

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    // Neon requires SSL; this simple setting works for the demo.
    ssl: { rejectUnauthorized: false }
});

// ============================================================
// Allowlists
// ============================================================

// Tables approved for read-only browsing (GET /api/tables/:table).
// Keys are lowercase for case-insensitive lookup; values are the
// exact identifiers used in the SQL text.
const BROWSE_TABLES = {
    soldier: 'Soldier',
    militaryunit: 'MilitaryUnit',
    equipmentcategory: 'EquipmentCategory',
    equipmenttype: 'EquipmentType',
    storagelocation: 'StorageLocation',
    equipmentasset: 'EquipmentAsset',
    equipmentassignment: 'EquipmentAssignment',
    weapontype: 'WeaponType',
    weaponstatus: 'WeaponStatus',
    weapon: 'Weapon',
    weaponassignment: 'WeaponAssignment',
    ammotype: 'AmmoType',
    ammunition: 'Ammunition',
    ammoissue: 'AmmoIssue',
    maintenancetype: 'MaintenanceType',
    maintenance: 'Maintenance'
};

// Tables approved for the CRUD demo, with their real primary key
// and editable columns exactly as defined in PhaseC/createTables.sql.
const CRUD_TABLES = {
    equipmentcategory: {
        table: 'EquipmentCategory',
        primaryKey: 'category_id',
        columns: ['category_name']
    },
    storagelocation: {
        table: 'StorageLocation',
        primaryKey: 'location_id',
        columns: ['location_name', 'location_type']
    },
    maintenancetype: {
        table: 'MaintenanceType',
        primaryKey: 'maint_type_id',
        columns: ['type_name']
    }
};

// ============================================================
// Helpers
// ============================================================

function dbErrorResponse(res, err) {
    // Foreign key violation gets a friendlier explanation,
    // because it demonstrates referential integrity in the demo.
    if (err.code === '23503') {
        return res.status(409).json({
            error: 'שגיאת שלמות נתונים: הרשומה מקושרת לרשומות אחרות (Foreign Key) ולכן לא ניתן לבצע את הפעולה.',
            detail: err.detail || err.message
        });
    }
    if (err.code === '23505') {
        return res.status(409).json({
            error: 'שגיאת ייחודיות: ערך זה כבר קיים בטבלה (Unique constraint).',
            detail: err.detail || err.message
        });
    }
    return res.status(500).json({
        error: 'שגיאת בסיס נתונים',
        detail: err.message
    });
}

function getCrudTable(res, tableParam) {
    const config = CRUD_TABLES[String(tableParam).toLowerCase()];
    if (!config) {
        res.status(400).json({
            error: 'CRUD אינו נתמך עבור טבלה זו. הטבלאות המותרות: EquipmentCategory, StorageLocation, MaintenanceType.'
        });
        return null;
    }
    return config;
}

// Validates the JSON body keys against the table's column allowlist.
// Returns { columns, values } or null after sending an error response.
function getBodyColumns(res, config, body) {
    if (!body || typeof body !== 'object' || Object.keys(body).length === 0) {
        res.status(400).json({ error: 'גוף הבקשה (JSON) ריק. יש לשלוח לפחות עמודה אחת.' });
        return null;
    }
    const columns = Object.keys(body);
    const invalid = columns.filter((c) => !config.columns.includes(c));
    if (invalid.length > 0) {
        res.status(400).json({
            error: `עמודות לא מוכרות עבור ${config.table}: ${invalid.join(', ')}. העמודות המותרות: ${config.columns.join(', ')}.`
        });
        return null;
    }
    return { columns, values: columns.map((c) => body[c]) };
}

function getIdParam(res, idParam) {
    const id = Number(idParam);
    if (!Number.isInteger(id)) {
        res.status(400).json({ error: 'מזהה (ID) חייב להיות מספר שלם.' });
        return null;
    }
    return id;
}

// ============================================================
// 1. Health check
// ============================================================

app.get('/api/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ status: 'ok', database: 'connected' });
    } catch (err) {
        res.status(500).json({ status: 'ok', database: 'error', detail: err.message });
    }
});

// ============================================================
// 2. Views (Phase D)
// ============================================================

app.get('/api/views/soldiers', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM v_soldier_resource_overview LIMIT 50');
        res.json(result.rows);
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

app.get('/api/views/units', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM v_unit_resource_summary LIMIT 50');
        res.json(result.rows);
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

// ============================================================
// 3. Table browser (read-only, fixed allowlist)
// ============================================================

app.get('/api/tables/:table', async (req, res) => {
    const tableName = BROWSE_TABLES[String(req.params.table).toLowerCase()];
    if (!tableName) {
        return res.status(400).json({
            error: 'טבלה לא מאושרת לצפייה.',
            allowedTables: Object.values(BROWSE_TABLES)
        });
    }
    try {
        // tableName comes only from the fixed allowlist above,
        // never from raw user input.
        const result = await pool.query(`SELECT * FROM ${tableName} LIMIT 50`);
        res.json(result.rows);
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

// ============================================================
// 4. CRUD demo (3 simple management tables only)
// ============================================================

app.post('/api/crud/:table', async (req, res) => {
    const config = getCrudTable(res, req.params.table);
    if (!config) return;
    const parsed = getBodyColumns(res, config, req.body);
    if (!parsed) return;
    const placeholders = parsed.columns.map((_, i) => `$${i + 1}`).join(', ');
    try {
        const result = await pool.query(
            `INSERT INTO ${config.table} (${parsed.columns.join(', ')})
             VALUES (${placeholders})
             RETURNING *`,
            parsed.values
        );
        res.status(201).json({ message: 'הרשומה נוספה בהצלחה', row: result.rows[0] });
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

app.put('/api/crud/:table/:id', async (req, res) => {
    const config = getCrudTable(res, req.params.table);
    if (!config) return;
    const id = getIdParam(res, req.params.id);
    if (id === null) return;
    const parsed = getBodyColumns(res, config, req.body);
    if (!parsed) return;
    const setClause = parsed.columns.map((c, i) => `${c} = $${i + 1}`).join(', ');
    try {
        const result = await pool.query(
            `UPDATE ${config.table}
             SET ${setClause}
             WHERE ${config.primaryKey} = $${parsed.columns.length + 1}
             RETURNING *`,
            [...parsed.values, id]
        );
        if (result.rowCount === 0) {
            return res.status(404).json({ error: `לא נמצאה רשומה עם ${config.primaryKey} = ${id}.` });
        }
        res.json({ message: 'הרשומה עודכנה בהצלחה', row: result.rows[0] });
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

app.delete('/api/crud/:table/:id', async (req, res) => {
    const config = getCrudTable(res, req.params.table);
    if (!config) return;
    const id = getIdParam(res, req.params.id);
    if (id === null) return;
    try {
        const result = await pool.query(
            `DELETE FROM ${config.table}
             WHERE ${config.primaryKey} = $1
             RETURNING *`,
            [id]
        );
        if (result.rowCount === 0) {
            return res.status(404).json({ error: `לא נמצאה רשומה עם ${config.primaryKey} = ${id}.` });
        }
        res.json({ message: 'הרשומה נמחקה בהצלחה', row: result.rows[0] });
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

// ============================================================
// 5. Reports - complex queries copied from PhaseD/complexQueries.sql
// ============================================================

// Query D1: active equipment assignments by real recipient group
// and equipment type.
const QUERY_D1 = `
SELECT
    CASE
        WHEN recipient_soldier.entity_id IS NOT NULL THEN 'Soldier'
        WHEN recipient_unit.entity_id IS NOT NULL THEN 'MilitaryUnit'
        ELSE 'Unknown'
    END AS recipient_real_group,
    COALESCE(
        recipient_soldier.first_name || ' ' || recipient_soldier.last_name,
        recipient_unit.unit_name
    ) AS recipient_name,
    recipient_unit.unit_level AS recipient_unit_level,
    COALESCE(soldier_unit.unit_name, 'Not a soldier recipient') AS soldier_unit_name,
    et.type_name AS equipment_type_name,
    COUNT(ea.assignment_id) AS active_assignment_count,
    SUM(ea.assigned_quantity) AS total_assigned_quantity
FROM EquipmentAssignment ea
JOIN Recipient r
    ON ea.recipient_id = r.recipient_id
JOIN EquipmentAsset asset
    ON ea.asset_id = asset.asset_id
JOIN EquipmentType et
    ON asset.type_id = et.type_id
LEFT JOIN Soldier recipient_soldier
    ON r.entity_id = recipient_soldier.entity_id
LEFT JOIN MilitaryUnit recipient_unit
    ON r.entity_id = recipient_unit.entity_id
LEFT JOIN MilitaryUnit soldier_unit
    ON recipient_soldier.unit_entity_id = soldier_unit.entity_id
WHERE ea.assignment_status = 'פעילה'
GROUP BY
    recipient_soldier.entity_id,
    recipient_soldier.first_name,
    recipient_soldier.last_name,
    recipient_unit.entity_id,
    recipient_unit.unit_name,
    recipient_unit.unit_level,
    soldier_unit.unit_name,
    et.type_name
ORDER BY
    total_assigned_quantity DESC,
    active_assignment_count DESC
`;

// Query D2: monthly activity across the integrated database.
const QUERY_D2 = `
WITH monthly_activity AS (
    SELECT
        DATE_TRUNC('month', ea.assignment_date)::DATE AS activity_month,
        'Equipment Assignment' AS activity_type,
        COUNT(ea.assignment_id) AS event_count,
        SUM(ea.assigned_quantity) AS quantity_count
    FROM EquipmentAssignment ea
    WHERE ea.assignment_status <> 'בוטלה'
    GROUP BY
        DATE_TRUNC('month', ea.assignment_date)::DATE

    UNION ALL

    SELECT
        DATE_TRUNC('month', wa.assignment_date)::DATE AS activity_month,
        'Weapon Assignment' AS activity_type,
        COUNT(wa.assignment_id) AS event_count,
        COUNT(wa.assignment_id) AS quantity_count
    FROM WeaponAssignment wa
    GROUP BY
        DATE_TRUNC('month', wa.assignment_date)::DATE

    UNION ALL

    SELECT
        DATE_TRUNC('month', ai.issue_date)::DATE AS activity_month,
        'Ammo Issue' AS activity_type,
        COUNT(ai.issue_id) AS event_count,
        SUM(ai.quantity) AS quantity_count
    FROM AmmoIssue ai
    GROUP BY
        DATE_TRUNC('month', ai.issue_date)::DATE
)
SELECT
    activity_month,
    SUM(CASE WHEN activity_type = 'Equipment Assignment' THEN event_count ELSE 0 END) AS equipment_assignment_count,
    SUM(CASE WHEN activity_type = 'Equipment Assignment' THEN quantity_count ELSE 0 END) AS equipment_quantity,
    SUM(CASE WHEN activity_type = 'Weapon Assignment' THEN event_count ELSE 0 END) AS weapon_assignment_count,
    SUM(CASE WHEN activity_type = 'Ammo Issue' THEN event_count ELSE 0 END) AS ammo_issue_count,
    SUM(CASE WHEN activity_type = 'Ammo Issue' THEN quantity_count ELSE 0 END) AS ammo_quantity
FROM monthly_activity
GROUP BY
    activity_month
ORDER BY
    activity_month
`;

// Query D6: maintenance workload by technician unit, weapon type,
// and maintenance type.
const QUERY_D6 = `
SELECT
    tech_unit.unit_name AS technician_unit_name,
    tech_unit.unit_level AS technician_unit_level,
    tech.entity_id AS technician_entity_id,
    tech.soldier_id AS technician_soldier_id,
    tech.first_name AS technician_first_name,
    tech.last_name AS technician_last_name,
    wt.type_name AS weapon_type_name,
    mt.type_name AS maintenance_type_name,
    COUNT(m.maintenance_id) AS maintenance_count,
    MIN(m.maintenance_date) AS first_maintenance_date,
    MAX(m.maintenance_date) AS last_maintenance_date
FROM Maintenance m
JOIN Soldier tech
    ON m.technician_entity_id = tech.entity_id
JOIN MilitaryUnit tech_unit
    ON tech.unit_entity_id = tech_unit.entity_id
JOIN Weapon w
    ON m.serial_number = w.serial_number
JOIN WeaponType wt
    ON w.type_id = wt.type_id
JOIN MaintenanceType mt
    ON m.maint_type_id = mt.maint_type_id
GROUP BY
    tech_unit.unit_name,
    tech_unit.unit_level,
    tech.entity_id,
    tech.soldier_id,
    tech.first_name,
    tech.last_name,
    wt.type_name,
    mt.type_name
ORDER BY
    maintenance_count DESC,
    last_maintenance_date DESC
`;

// Query D7: high resource load soldiers, based on the Phase D
// soldier view.
const QUERY_D7 = `
SELECT
    soldier_entity_id,
    soldier_id,
    first_name,
    last_name,
    rank_name,
    unit_name,
    unit_level,
    active_equipment_assignment_count,
    active_equipment_quantity,
    active_weapon_count,
    ammo_issue_count,
    total_ammo_quantity,
    maintenance_action_count,
    resource_load_score
FROM v_soldier_resource_overview
WHERE resource_load_score > 0
ORDER BY
    resource_load_score DESC,
    total_ammo_quantity DESC,
    active_equipment_quantity DESC
LIMIT 20
`;

const REPORTS = { d1: QUERY_D1, d2: QUERY_D2, d6: QUERY_D6, d7: QUERY_D7 };

app.get('/api/reports/:report', async (req, res) => {
    const sql = REPORTS[String(req.params.report).toLowerCase()];
    if (!sql) {
        return res.status(400).json({ error: 'דוח לא קיים. הדוחות הזמינים: d1, d2, d6, d7.' });
    }
    try {
        const result = await pool.query(sql);
        res.json(result.rows);
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

// ============================================================
// 6. Functions (Phase D)
// ============================================================

app.get('/api/functions/soldier/:id', async (req, res) => {
    const id = getIdParam(res, req.params.id);
    if (id === null) return;
    try {
        const result = await pool.query('SELECT * FROM get_soldier_resource_snapshot($1)', [id]);
        res.json(result.rows);
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

app.get('/api/functions/unit/:id', async (req, res) => {
    const id = getIdParam(res, req.params.id);
    if (id === null) return;
    try {
        const result = await pool.query('SELECT * FROM get_unit_readiness_summary($1)', [id]);
        res.json(result.rows);
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

// ============================================================
// 7. Procedures (Phase D)
// Note: these procedures permanently change data in the database.
// ============================================================

app.post('/api/procedures/return-weapon', async (req, res) => {
    const { assignmentId, returnDate, returnReason } = req.body || {};
    if (assignmentId === undefined || !returnDate) {
        return res.status(400).json({ error: 'חסרים פרמטרים: assignmentId ו-returnDate הם חובה.' });
    }
    const id = getIdParam(res, assignmentId);
    if (id === null) return;
    try {
        await pool.query('CALL return_weapon_assignment($1, $2, $3)', [
            id,
            returnDate,
            returnReason || null
        ]);
        res.json({
            message: `הקצאת נשק ${id} הוחזרה בהצלחה. סטטוס הנשק סונכרן אוטומטית על ידי הטריגר trg_sync_weapon_status.`
        });
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

app.post('/api/procedures/return-equipment', async (req, res) => {
    const { assignmentId, returnDate } = req.body || {};
    if (assignmentId === undefined || !returnDate) {
        return res.status(400).json({ error: 'חסרים פרמטרים: assignmentId ו-returnDate הם חובה.' });
    }
    const id = getIdParam(res, assignmentId);
    if (id === null) return;
    try {
        await pool.query('CALL return_equipment_assignment($1, $2)', [id, returnDate]);
        res.json({
            message: `הקצאת ציוד ${id} הוחזרה בהצלחה. זמינות הציוד סונכרנה אוטומטית על ידי הטריגר trg_sync_equipment_availability.`
        });
    } catch (err) {
        dbErrorResponse(res, err);
    }
});

// ============================================================
// Start server
// ============================================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Phase E backend is running on http://localhost:${PORT}`);
});
