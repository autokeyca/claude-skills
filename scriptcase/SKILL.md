---
name: scriptcase
description: Modify, fix, and manage ScriptCase 9 applications for AutoKey's AKCRM and AKINV projects. Use when the user mentions ScriptCase forms, grids, apps, or any CRM/inventory UI issues (broken buttons, validation errors, field behavior, CSRF issues, SQL errors from form saves, deployment). Covers direct SQLite database manipulation of app definitions, field settings, events, cloning, and regeneration via SSH.
---

# ScriptCase Management

## Quick Reference

- **Server:** 192.168.1.19 (scase.autokey.ca:8092)
- **SSH:** `ssh ja@192.168.1.19` (passwordless)
- **SQLite DB:** `/opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db`
- **PHP binary:** `/opt/Scriptcase/v9-php81/components/php/bin/php`
- **Deployed apps:** `/opt/Scriptcase/v9-php81/wwwroot/scriptcase/app/{akcrm,inven}/`
- **Projects:** AKCRM (CRM, 300 apps), Inven (Inventory, 164 apps)
- **MSSQL:** 192.168.1.4, sa / AKR00xx!!@@, databases AKCRM and AKINV

## Architecture

ScriptCase stores ALL app definitions in a SQLite database — not in files. Three core tables:

| Table | Contains |
|-------|----------|
| `sc_tbapl` | App definitions (SQL, config in serialized PHP Attr1-Attr10) |
| `sc_tbcmp` | Fields (config in serialized PHP Attr1, Attr4) |
| `sc_tbevt` | Events (PHP code in Codigo column) |

**We modify apps programmatically via SSH + SQLite/PHP.** No browser IDE needed.

## Standard Workflow

For any ScriptCase modification:

1. **Identify the app** — Query `sc_tbapl` to confirm it exists and get its type/version
2. **Clone/backup first** — MANDATORY before any changes. See `references/cloning.md`
3. **Make the change** — Modify fields, events, or app settings via scripts
4. **Regenerate** — Run the regeneration script. See `references/regeneration.md`
5. **Test** — Verify the fix on production URL

## Common Tasks

### Modify a field setting (e.g., make read-only, disable update)

Field config lives in serialized PHP in `sc_tbcmp.Attr1`. Use a PHP script on the server:

```bash
ssh ja@192.168.1.19 "cat > /tmp/sc_work.php << 'ENDPHP'
<?php
error_reporting(0);
\$db = new SQLite3('/opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db');
\$result = \$db->query(\"SELECT Attr1 FROM sc_tbcmp WHERE Cod_Apl = 'APP_NAME' AND Campo = 'FIELD_NAME' AND Cod_Prj = 'akcrm'\");
\$row = \$result->fetchArray();
\$attr = @unserialize(\$row[0]);
// Modify the property (e.g., mark as db-calculated to exclude from UPDATE):
// \$attr['banco_val_tipo_upd'] = 'db_calc';
\$attr['PROPERTY_NAME'] = 'VALUE';
\$stmt = \$db->prepare(\"UPDATE sc_tbcmp SET Attr1 = :attr WHERE Cod_Apl = 'APP_NAME' AND Campo = 'FIELD_NAME' AND Cod_Prj = 'akcrm'\");
\$stmt->bindValue(':attr', serialize(\$attr), SQLITE3_TEXT);
\$stmt->execute();
echo \"Done: FIELD_NAME.PROPERTY_NAME = VALUE\n\";
ENDPHP
/opt/Scriptcase/v9-php81/components/php/bin/php /tmp/sc_work.php 2>/dev/null"
```

**Key field properties** (in Attr1 unless noted):
- `banco_val_tipo` — field value type for INSERT. Set to `'db_calc'` to tell ScriptCase the value is database-calculated (skips it in INSERT SQL). **This is the correct way to exclude datetime/computed fields.**
- `banco_val_tipo_upd` — same as above but for UPDATE. Set to `'db_calc'` to skip in UPDATE SQL.
- `banco_val_forcar` — "S" = force include in SQL, "N" = don't force
- `read_only` — "S"/"N"
- `html_disabled` — "S"/"N"
- `visivel` — "S"/"N" (visible on form)
- `val_inicial` — default value
- `formato_data` — date format string

**Field properties in sc_tbcmp columns directly:**
- `Entra_Update` — "S"/"N" — whether field participates in UPDATE (column-level, not Attr1)

**To exclude a field from UPDATE/INSERT (e.g., TIME_ADDED, computed columns):**
- **Preferred:** Set `banco_val_tipo_upd = 'db_calc'` (and/or `banco_val_tipo = 'db_calc'` for INSERT) in Attr1. Field stays visible on form but ScriptCase treats it as DB-computed.
- **Alternative:** Set `Entra_Update = 'N'` in sc_tbcmp — cruder, may not always take effect on regeneration.

### Modify an app setting (e.g., CSRF)

App config lives in serialized PHP in `sc_tbapl.Attr1`. Same pattern as field modification but query `sc_tbapl` instead of `sc_tbcmp`.

**Key app properties:**
- `security_enable_csrf` — "S"/"N" (CSRF protection)

### Add/modify an event

Events are plain PHP code in `sc_tbevt.Codigo`. See `references/events.md`.

### Inspect an app or field

```bash
# List fields for an app
ssh ja@192.168.1.19 "sqlite3 /opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db \
  \"SELECT Seq, Campo, Label, Html_Tipo, Tipo_Sql, Entra_Update FROM sc_tbcmp WHERE Cod_Apl = 'APP_NAME' AND Cod_Prj = 'akcrm' ORDER BY Seq\""

# Get events for an app
ssh ja@192.168.1.19 "sqlite3 /opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db \
  \"SELECT Nome, length(Codigo) FROM sc_tbevt WHERE Cod_Apl = 'APP_NAME' AND Cod_Prj = 'akcrm'\""

# Check a specific field's Attr1 property
ssh ja@192.168.1.19 "cat > /tmp/sc_work.php << 'ENDPHP'
<?php
error_reporting(0);
\$db = new SQLite3('/opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db');
\$result = \$db->query(\"SELECT Attr1 FROM sc_tbcmp WHERE Cod_Apl = 'APP_NAME' AND Campo = 'FIELD_NAME' AND Cod_Prj = 'akcrm'\");
\$row = \$result->fetchArray();
\$attr = @unserialize(\$row[0]);
echo \"banco_val_forcar = \" . (\$attr['banco_val_forcar'] ?? 'not set') . \"\n\";
echo \"read_only = \" . (\$attr['read_only'] ?? 'not set') . \"\n\";
echo \"Entra_Update check: query sc_tbcmp.Entra_Update column directly\n\";
ENDPHP
/opt/Scriptcase/v9-php81/components/php/bin/php /tmp/sc_work.php 2>/dev/null"
```

## Regeneration

After ANY database change, the app must be regenerated. See `references/regeneration.md` for the full procedure.

**ScriptCase code is SourceGuardian-encrypted — no CLI generation possible.** Jerry must open the IDE, close/reopen the app, and click Generate. Tell him exactly which app to regenerate.

## References

- **`references/cloning.md`** — Backup/clone procedure (read before any modification)
- **`references/events.md`** — Event system, validation patterns, common events
- **`references/regeneration.md`** — How to regenerate/deploy after changes
- **`references/known-issues.md`** — Solved problems and gotchas (newlines in JS, CSRF, etc.)
- **`references/database-schema.md`** — Full SQLite schema details, serialized PHP format

## Project Documentation

Detailed business context, database schemas, and app inventories live in:
`/home/ja/projects/scriptcase_dev/` — See CLAUDE.md there for full index.
