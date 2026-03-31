# Cloning / Backup Procedure

**MANDATORY before any modification.**

## Clone an App

```bash
ssh ja@192.168.1.19 "sqlite3 /opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db \"
INSERT INTO sc_tbapl SELECT Cod_Prj, Versao, 'APPNAME_BKP_YYYYMMDD' as Cod_Apl, friendly_name, Login, Tipo_Apl, Descricao, Folder, strftime('%Y%m%d','now') as Data_Inc, strftime('%H%M%S','now') as Hora_Inc, strftime('%Y%m%d','now') as Data_Uacc, strftime('%H%M%S','now') as Hora_Uacc, '' as Data_Ger, '' as Hora_Ger, usa_seguranca, Idioma, charset_specific, NomeConexao, NomeTabela, Campos_Chave, Template, TemplateGrid, TemplateEdit, TemplateSearch, TemplateDetalhe, TemplateHeadSearch, TemplateFooterSearch, SchemaAll, schemachart, SchemaSearch, ButtonAll, ButtonSearch, Cabecalho_Grid_Mostra, Cabecalho_Pesq_Mostra, Cabecalho_Edit_Mostra, Cabecalho_Detalhe_Mostra, Tables, ComandoSelect, Variaveis, Xml_Procedure, Attr1, Attr2, Attr3, Attr4, Attr5, Attr6, Attr7, Attr8, Attr9, Attr10 FROM sc_tbapl WHERE Cod_Apl = 'ORIGINAL_APP';
INSERT INTO sc_tbcmp SELECT Cod_Prj, Versao, 'APPNAME_BKP_YYYYMMDD' as Cod_Apl, Seq, Login, Campo, Html_Tipo, Tipo_Dado, Tipo_Dado_Filtro, Tipo_Sql, Campo_Def, Def_Campo, Label, Label_Filtro, Usar_Label_Grid, Entra_Edit, Entra_Update, Entra_Sort, EntraDetalhe, EntraDetalheOrd, Def_Tabela, Def_Complemento, Def_Complemento_Cons, Def_Complemento_Pesq, Texto_Xml, Xml_Subconsulta, Ajax_Dados, Attr1, Attr2, Attr3, Attr4, Attr5, Attr6 FROM sc_tbcmp WHERE Cod_Apl = 'ORIGINAL_APP';
INSERT INTO sc_tbevt SELECT Cod_Prj, Versao, 'APPNAME_BKP_YYYYMMDD' as Cod_Apl, Nome, Tipo, Parms, Codigo FROM sc_tbevt WHERE Cod_Apl = 'ORIGINAL_APP';
\""
```

## Verify Clone

```bash
ssh ja@192.168.1.19 "sqlite3 /opt/Scriptcase/v9-php81/wwwroot/scriptcase/devel/conf/scriptcase/nm_scriptcase.db \
  \"SELECT 'App' as type, Cod_Apl FROM sc_tbapl WHERE Cod_Apl = 'APPNAME_BKP_YYYYMMDD' UNION ALL SELECT 'Fields', COUNT(*) || ' fields' FROM sc_tbcmp WHERE Cod_Apl = 'APPNAME_BKP_YYYYMMDD' UNION ALL SELECT 'Events', COUNT(*) || ' events' FROM sc_tbevt WHERE Cod_Apl = 'APPNAME_BKP_YYYYMMDD'\""
```

## Delete a Clone (cleanup after verified fix)

```sql
DELETE FROM sc_tbapl WHERE Cod_Apl = 'APPNAME_BKP_YYYYMMDD';
DELETE FROM sc_tbcmp WHERE Cod_Apl = 'APPNAME_BKP_YYYYMMDD';
DELETE FROM sc_tbevt WHERE Cod_Apl = 'APPNAME_BKP_YYYYMMDD';
```
