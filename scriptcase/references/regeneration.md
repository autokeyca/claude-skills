# Regeneration / Deployment

After ANY SQLite database change, the app must be regenerated for changes to take effect.

## Method: ScriptCase IDE (Manual)

**ScriptCase code is SourceGuardian-encrypted — no CLI generation is possible.**

1. Open ScriptCase IDE: http://scase.autokey.ca:8092/scriptcase/
2. Close the app if it's currently open (forces reload from DB)
3. Reopen the app (this picks up SQLite changes)
4. Click **Generate** (the gear/play icon) -> Deploy

This is the ONLY way to regenerate. Jerry must do this step.

## Verify Deployment

Check the generation timestamp updated:
```bash
ssh ja@192.168.1.19 "sqlite3 /opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db \
  \"SELECT Data_Ger, Hora_Ger FROM sc_tbapl WHERE Cod_Apl = 'APP_NAME' AND Cod_Prj = 'akcrm'\""
```

Check deployed files exist:
```bash
ssh ja@192.168.1.19 "ls -la /opt/Scriptcase/v9-php81/wwwroot/scriptcase/app/akcrm/APP_NAME/"
```

## Production URLs

- AKCRM apps: `https://crm.autokey.ca/scriptcase/app/akcrm/APP_NAME/`
- Inven apps: `https://inventory.autokey.ca/scriptcase/app/inven/APP_NAME/`
