-- =====================================================================
--  EL USUARIO DE LA APLICACION
--
--  Hasta ahora la cadena de conexion usa 'sqladmin', que es
--  administrador total: puede leer cualquier tabla, borrarlas, y crear
--  usuarios. Si la API se compromete, el atacante hereda todo eso.
--
--  Como TODO el acceso pasa por procedimientos, la aplicacion no
--  necesita ningun permiso sobre las tablas. Solo EXECUTE.
-- =====================================================================

-- ---------------------------------------------------------------------
--  En Azure SQL: el usuario vive en la base, no en el servidor
--  (no hay CREATE LOGIN en bases de datos independientes).
-- ---------------------------------------------------------------------
-- La clave NO va escrita aqui: se pasa al ejecutar, con
--     sqlcmd -v CLAVE_APP="loquesea" -i 05-usuario-aplicacion.sql
-- Asi este fichero puede estar en el repositorio sin contener ningun
-- secreto.
-- Sin :setvar aqui a proposito: una definicion dentro del guion TIENE
-- PRIORIDAD sobre la que se pasa con -v, asi que el marcador de
-- posicion ganaria siempre. Dejandolo fuera, ejecutar sin -v falla de
-- forma ruidosa en vez de crear un usuario con una clave conocida.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_matriculas')
BEGIN
    CREATE USER app_matriculas WITH PASSWORD = '$(CLAVE_APP)';
END
GO

-- Permiso de ejecucion sobre TODOS los procedimientos del esquema dbo,
-- incluidos los que se creen en el futuro.
GRANT EXECUTE ON SCHEMA::dbo TO app_matriculas;
GO

-- Y nada mas. Sin esto, la aplicacion NO puede:
--   SELECT * FROM dbo.Usuario
--   UPDATE dbo.Matricula SET Estado = 'Aprobada'
--   DROP TABLE dbo.Alumno
-- Solo puede llamar a los procedimientos que existen, con los
-- parametros que aceptan.
GO

-- ---------------------------------------------------------------------
--  Comprobacion: que permisos tiene realmente
-- ---------------------------------------------------------------------
-- SELECT  p.permission_name,
--         Objeto = COALESCE(o.name, SCHEMA_NAME(p.major_id), 'BASE DE DATOS'),
--         p.state_desc
-- FROM        sys.database_permissions p
-- LEFT JOIN   sys.objects o ON o.object_id = p.major_id
-- WHERE  p.grantee_principal_id = DATABASE_PRINCIPAL_ID('app_matriculas');
