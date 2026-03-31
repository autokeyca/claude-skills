# Known Issues & Solutions

## Newlines in fields break ALL buttons (2026-02-09)

**Symptom:** All buttons dead on a form (Save, Convert, etc.)
**Cause:** `form_encode_input()` injects record values into JS string literals. CR/LF in a text field → JS syntax error → `nm_atualiza` (save function) never defined → all buttons broken.
**Fix:** Clean the data. Create a trigger to strip CR/LF on INSERT/UPDATE for affected fields.
**Prevention:** Add SQL triggers for text fields used in Link-type buttons.

## CSRF false positives — "data already sent" (2026-01-29)

**Symptom:** "The record cannot be inserted because these data have been already sent"
**Cause:** `security_enable_csrf = S` in `sc_tbapl.Attr1` — session token mismatch.
**Fix:** Set `security_enable_csrf` to `N` in Attr1 (serialized PHP). See SKILL.md app settings pattern.

## VARCHAR to DATETIME conversion error

**Symptom:** "The conversion of a varchar data type to a datetime data type resulted in an out-of-range value"
**Cause:** ScriptCase round-trips ALL fields in UPDATE, even unchanged ones. Date/time fields get reformatted through the form's display format and sent back mangled (e.g., `2026-02-11 10:50:22` becomes `022620 00:00:00:000`).
**Fix:** Set `banco_val_tipo_upd = 'db_calc'` (and `banco_val_tipo = 'db_calc'` for INSERT) in the field's Attr1. This tells ScriptCase the field is database-calculated and should be skipped in the SQL. This is the correct ScriptCase way — `Entra_Update = 'N'` is cruder and may not reliably take effect.
**Example:** TIME_ADDED, LAST_MOD_TIME — metadata fields that should never be round-tripped through the form.

## scEventControl_active blocks all buttons

**Symptom:** All buttons unresponsive after an AJAX event.
**Cause:** A stuck AJAX event leaves the `scEventControl_active` flag set, blocking all subsequent button clicks.
**Fix:** Debug the AJAX event that's failing.

## Versao mismatch — events invisible in IDE

**Symptom:** Event exists in database but IDE doesn't show it.
**Cause:** `Versao` in `sc_tbevt` doesn't match `Versao` in `sc_tbapl`.
**Fix:** Always query the app's version before inserting events.

## onRecord runs per-row in grids

Don't put JavaScript `echo` in `onRecord` for grids — it executes for every row.
