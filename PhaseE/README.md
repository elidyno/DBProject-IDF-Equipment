# שלב ה׳ — ממשק משתמש למערכת לניהול ציוד צבאי בחטיבת מילואים

## 1. מה זה שלב ה׳

שלב ה׳ הוא שלב ממשק המשתמש של הפרויקט בבסיסי נתונים.
המטרה היא להדגים שבסיס הנתונים שנבנה בשלבים הקודמים שמיש דרך מסך:
תצוגת נתונים, שאילתות, הוספת רשומות, עדכון רשומות, מחיקת רשומות,
והרצת פונקציות ופרוצדורות מאוחסנות עם הצגת התוצאות.

זהו ממשק הדגמה אקדמי פשוט — לא אפליקציית ווב מלאה.
אין התחברות, אין משתמשים, אין הרשאות, ואין React או תהליך Build.

## 2. אילו קבצים נוצרו

```
PhaseE/
├── backend/
│   ├── package.json      הגדרות הפרויקט והתלויות (express, pg, cors, dotenv)
│   ├── server.js         שרת Express — כל נקודות הקצה בקובץ אחד
│   ├── .env.example      תבנית לקובץ הסביבה (ללא סיסמה אמיתית)
│   └── .gitignore        מתעלם מ-.env ומ-node_modules
├── frontend/
│   └── index.html        דף HTML עצמאי בעברית עם CSS ו-JavaScript פנימיים
└── README.md             הקובץ הזה
```

## 3. מה השרת (Backend) עושה

השרת הוא Node.js + Express פשוט שמתחבר ל-PostgreSQL (Neon) דרך חבילת `pg`.

נקודות הקצה:

| נקודת קצה | תיאור |
|---|---|
| `GET /api/health` | בדיקת חיבור לשרת ולבסיס הנתונים |
| `GET /api/views/soldiers` | המבט `v_soldier_resource_overview` (עד 50 שורות) |
| `GET /api/views/units` | המבט `v_unit_resource_summary` (עד 50 שורות) |
| `GET /api/tables/:table` | עד 50 שורות מטבלה מאושרת (רשימה סגורה של 16 טבלאות) |
| `POST /api/crud/:table` | הוספת רשומה (רק EquipmentCategory / StorageLocation / MaintenanceType) |
| `PUT /api/crud/:table/:id` | עדכון רשומה לפי מפתח ראשי |
| `DELETE /api/crud/:table/:id` | מחיקת רשומה לפי מפתח ראשי |
| `GET /api/reports/d1` | שאילתה D1 מתוך `PhaseD/complexQueries.sql` |
| `GET /api/reports/d2` | שאילתה D2 — פעילות חודשית משולבת |
| `GET /api/reports/d6` | שאילתה D6 — עומס אחזקה לפי טכנאי וסוג נשק |
| `GET /api/reports/d7` | שאילתה D7 — חיילים עם עומס משאבים גבוה |
| `GET /api/functions/soldier/:id` | הפונקציה `get_soldier_resource_snapshot($1)` |
| `GET /api/functions/unit/:id` | הפונקציה `get_unit_readiness_summary($1)` |
| `POST /api/procedures/return-weapon` | הפרוצדורה `return_weapon_assignment($1, $2, $3)` |
| `POST /api/procedures/return-equipment` | הפרוצדורה `return_equipment_assignment($1, $2)` |

הערות אבטחה בסיסיות (ברמת הדגמה):

- שמות הטבלאות נלקחים רק מרשימה סגורה (Allowlist) — לא מקלט חופשי.
- כל הערכים מועברים כפרמטרים (Parameterized Queries).
- מפתחות ה-JSON ב-CRUD נבדקים מול רשימת עמודות מותרות לכל טבלה.
- CORS פתוח — מקובל עבור הדגמה בקורס.

טבלאות ה-CRUD והעמודות האמיתיות שלהן (לפי `PhaseC/createTables.sql`):

| טבלה | מפתח ראשי | עמודות |
|---|---|---|
| EquipmentCategory | `category_id` | `category_name` |
| StorageLocation | `location_id` | `location_name`, `location_type` |
| MaintenanceType | `maint_type_id` | `type_name` |

## 4. מה הממשק (Frontend) עושה

`frontend/index.html` הוא דף עצמאי בעברית (RTL) הכולל:

1. **חיבור לשרת** — שדה API Base URL וכפתור בדיקת חיבור.
2. **דשבורד** — הצגת סיכום חיילים וסיכום יחידות מהמבטים של שלב ד׳.
3. **דפדפן טבלאות** — בחירת טבלה מתוך 16 הטבלאות המאושרות והצגתה.
4. **הדגמת CRUD** — הוספה, עדכון ומחיקה על שלוש טבלאות ניהול פשוטות,
   עם דוגמת JSON שמתעדכנת אוטומטית לפי הטבלה שנבחרה.
5. **דוחות** — ארבעה דוחות מתוך השאילתות המורכבות של שלב ד׳ (D1, D2, D6, D7).
6. **פונקציות** — תמונת משאבים לחייל ומוכנות יחידה לפי entity_id.
7. **פרוצדורות** — החזרת נשק והחזרת ציוד.
8. **אזור תוצאות** — כל תגובה מוצגת כטבלה (עבור מערך שורות) או כאובייקט,
   עם הודעות שגיאה ברורות בעברית.

## 5. הרצה מקומית

```
cd PhaseE/backend
npm install
```

יצירת קובץ סביבה: העתיקו את `.env.example` לקובץ בשם `.env`
ומלאו בו את כתובת החיבור האמיתית (ראו סעיף 6). לאחר מכן:

```
npm start
```

השרת יעלה על `http://localhost:3000`.

לבסוף פתחו את הקובץ `PhaseE/frontend/index.html` בדפדפן
(לחיצה כפולה מספיקה — אין צורך בשרת עבור הדף עצמו).

## 6. הגדרת DATABASE_URL

בקובץ `.env` (שנוצר ידנית, לא נשמר ב-Git):

```
DATABASE_URL=postgresql://<user>:<password>@<host>/<database>?sslmode=require
PORT=3000
```

את כתובת החיבור המלאה מעתיקים מלוח הבקרה של Neon
(Connection Details → Connection string).

## 7. שדה API Base URL בממשק

בראש הדף יש שדה "API Base URL" עם ברירת מחדל `http://localhost:3000`.

- בהרצה מקומית — משאירים את ברירת המחדל.
- אם השרת פרוס בענן (למשל Render) — מזינים את כתובת השרת הפרוס,
  למשל `https://my-service.onrender.com`, ולוחצים "בדיקת חיבור".

## 8. פריסה עתידית ל-Render

1. יוצרים **Web Service** חדש ב-Render.
2. מחברים את מאגר ה-GitHub של הפרויקט.
3. מגדירים:
   - Root Directory: `PhaseE/backend`
   - Build Command: `npm install`
   - Start Command: `npm start`
4. מוסיפים משתנה סביבה `DATABASE_URL` עם כתובת החיבור של Neon.
5. לאחר הפריסה, מזינים את כתובת השירות בשדה ה-API Base URL בממשק.

## 9. הטמעה ב-WordPress / Elementor

1. מעתיקים את תוכן הקובץ `frontend/index.html`.
2. מדביקים אותו בתוך ווידג׳ט HTML בעמוד (Elementor → HTML Widget).
3. משנים את שדה ה-API Base URL לכתובת השרת הפרוס (מסעיף 8).

## 10. ⚠️ הערה חשובה — הפרוצדורות משנות נתונים לצמיתות

כפתורי הפרוצדורות בממשק ("החזר נשק" ו"החזר ציוד") מריצים
`CALL return_weapon_assignment(...)` ו-`CALL return_equipment_assignment(...)`
**ומעדכנים את בסיס הנתונים באופן קבוע**.

זאת בניגוד ל-`PhaseD/mainPhaseD.sql`, שם ההדגמה נעטפה ב-`BEGIN ... ROLLBACK`
כך שהנתונים לא השתנו בפועל.

בנוסף, הרצת הפרוצדורות מדגימה את הטריגרים של שלב ד׳:
`trg_sync_weapon_status` מסנכרן את סטטוס הנשק,
ו-`trg_sync_equipment_availability` מסנכרן את זמינות הציוד.
אפשר לראות את השינוי בדפדפן הטבלאות (טבלת Weapon או EquipmentAsset) אחרי ההרצה.

## 11. אילו דרישות קורס מודגמות בממשק

| דרישה | איפה בממשק |
|---|---|
| תצוגת נתונים (SELECT) | דשבורד, דפדפן טבלאות |
| שאילתות ודוחות | סעיף הדוחות (D1, D2, D6, D7) |
| הוספת רשומה (INSERT) | הדגמת CRUD — "הוסף רשומה" |
| עדכון רשומה (UPDATE) | הדגמת CRUD — "עדכן רשומה לפי ID" |
| מחיקת רשומה (DELETE) | הדגמת CRUD — "מחק רשומה לפי ID" |
| פונקציות מאוחסנות | תמונת משאבים לחייל, מוכנות יחידה |
| פרוצדורות מאוחסנות | החזרת נשק, החזרת ציוד |
| טריגרים | סנכרון אוטומטי של סטטוס נשק / זמינות ציוד אחרי החזרה |
| שלמות נתונים (Constraints) | הודעות שגיאה על הפרת FK / Unique ב-CRUD |
