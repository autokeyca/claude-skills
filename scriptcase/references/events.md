# ScriptCase Events

## Event Order (Forms)

1. `onApplicationInit` — App initialization
2. `onScriptInit` — Script initialization
3. `onLoadAll` — After loading all records
4. `onNavigate` — Record navigation
5. `onValidate` — Field-level validation
6. `onValidateSuccess` — After validation passes
7. `onBeforeInsert` / `onBeforeUpdate` — Before SQL executes (**best place for business logic**)
8. SQL INSERT/UPDATE executes
9. `onAfterInsert` / `onAfterUpdate` — After SQL executes

## Adding/Modifying Events

Events stored in `sc_tbevt`. **Version must match the app's version in sc_tbapl.**

```bash
ssh ja@192.168.1.19 "cat > /tmp/sc_work.php << 'ENDPHP'
<?php
error_reporting(0);
\$db = new SQLite3('/opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db');

// Get app version first
\$result = \$db->query(\"SELECT Versao FROM sc_tbapl WHERE Cod_Apl = 'APP_NAME' AND Cod_Prj = 'akcrm'\");
\$version = \$result->fetchArray()[0];

\$code = <<<'PHP'
// Your PHP code here
\$value = {FIELD_NAME};
PHP;

\$stmt = \$db->prepare('INSERT OR REPLACE INTO sc_tbevt (Cod_Prj, Versao, Cod_Apl, Nome, Tipo, Parms, Codigo) VALUES (:prj, :ver, :apl, :nome, :tipo, :parms, :codigo)');
\$stmt->bindValue(':prj', 'akcrm');
\$stmt->bindValue(':ver', \$version);
\$stmt->bindValue(':apl', 'APP_NAME');
\$stmt->bindValue(':nome', 'onBeforeUpdate');
\$stmt->bindValue(':tipo', 'E');
\$stmt->bindValue(':parms', '');
\$stmt->bindValue(':codigo', \$code);
\$stmt->execute();
echo \"Event added/updated\n\";
ENDPHP
/opt/Scriptcase/v9-php81/components/php/bin/php /tmp/sc_work.php 2>/dev/null"
```

## Validation Pattern

**Both macros required together, in the same event:**

```php
sc_error_message('Your error message');
sc_error_exit();
```

- `sc_error_exit('message')` alone does NOT block submission.
- Splitting across events does NOT work.

## Field References in Events

Use `{FIELD_NAME}` syntax. SELECT fields return strings — always `intval()` for numeric comparisons:

```php
$make_id = intval({MAKE_ID});
$year = intval({MYEAR});
```
