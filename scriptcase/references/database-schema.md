# ScriptCase SQLite Database Schema

**Location:** `/opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db`

## Core Tables

### sc_tbapl (Applications)

| Column | Type | Description |
|--------|------|-------------|
| Cod_Prj | VARCHAR(120) | Project code (akcrm, inven) |
| Versao | INT | Version number |
| Cod_Apl | VARCHAR(120) | App name (PK with above) |
| Tipo_Apl | VARCHAR(20) | Type: form, cons (grid), contr, menu, chart, report, blank, calendar, search |
| NomeConexao | VARCHAR(120) | DB connection name |
| NomeTabela | VARCHAR(255) | Source table |
| Campos_Chave | TEXT | Primary key fields |
| ComandoSelect | TEXT | SQL SELECT |
| Attr1-Attr10 | TEXT | Serialized PHP config arrays |
| Data_Ger / Hora_Ger | VARCHAR(8) | Last generation date/time (YYYYMMDD/HHMMSS) |

### sc_tbcmp (Fields)

| Column | Type | Description |
|--------|------|-------------|
| Cod_Apl | VARCHAR(120) | App name |
| Seq | INT | Field order |
| Campo | VARCHAR(255) | Field/column name |
| Label | VARCHAR(255) | Display label |
| Html_Tipo | VARCHAR(10) | HTML type: TEXT, SELECT, TEXTAREA, etc. |
| Tipo_Sql | VARCHAR(32) | SQL type: INTEGER, NVARCHAR, DATETIME, etc. |
| Entra_Update | VARCHAR(1) | S/N — participates in UPDATE SQL |
| Attr1 | TEXT | Serialized PHP (~349 properties) |
| Attr4 | TEXT | Serialized PHP (lookup SQL in `comando_select_edit`) |

### sc_tbevt (Events)

| Column | Type | Description |
|--------|------|-------------|
| Cod_Apl | VARCHAR(120) | App name |
| Versao | INT | Must match sc_tbapl.Versao |
| Nome | VARCHAR(120) | Event name |
| Tipo | VARCHAR(1) | E = Event |
| Codigo | TEXT | PHP code |

## Serialized PHP Format

Config in Attr columns uses PHP `serialize()`:
```
a:349:{s:12:"autoinc_nome";s:0:"";s:16:"banco_val_forcar";s:1:"N";...}
```
- `a:N` = array with N elements
- `s:N:"value"` = string of length N
- `i:N` = integer N
- `b:0` / `b:1` = boolean

**Never hand-edit serialized data.** Always use PHP to unserialize → modify → reserialize.
