-- =====================================================================
--  Deja appdb vacia para recargarla desde cero.
--
--  SOLO para la base de practicas: borra todo lo que haya.
--  No usar nunca contra datos que importen.
--
--  No se hace DROP DATABASE porque en Azure SQL eso tiraria tambien la
--  configuracion de capa gratuita sin servidor, y habria que volver a
--  crearla con todos sus parametros.
-- =====================================================================

SET NOCOUNT ON;

-- 1. Procedimientos
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'DROP PROCEDURE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(p.name) + N';' + CHAR(10)
FROM   sys.procedures p
JOIN   sys.schemas    s ON s.schema_id = p.schema_id;

EXEC sp_executesql @sql;

-- 2. Claves foraneas, antes que las tablas: si no, el orden de borrado
--    importaria y habria que acertarlo a mano.
SET @sql = N'';

SELECT @sql = @sql + N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
                   + N' DROP CONSTRAINT ' + QUOTENAME(f.name) + N';' + CHAR(10)
FROM   sys.foreign_keys f
JOIN   sys.tables       t ON t.object_id = f.parent_object_id
JOIN   sys.schemas      s ON s.schema_id = t.schema_id;

EXEC sp_executesql @sql;

-- 3. Tablas
SET @sql = N'';

SELECT @sql = @sql + N'DROP TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';' + CHAR(10)
FROM   sys.tables  t
JOIN   sys.schemas s ON s.schema_id = t.schema_id;

EXEC sp_executesql @sql;

SELECT TablasQueQuedan = (SELECT COUNT(*) FROM sys.tables),
       ProcedimientosQueQuedan = (SELECT COUNT(*) FROM sys.procedures);
GO
