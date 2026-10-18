-- =====================================================================
--  SOLO PARA EL ENTORNO LOCAL
--
--  En Azure la base 'appdb' se creo con 'az sql db create'. Aqui hay
--  que crearla a mano antes de cargar el esquema.
-- =====================================================================

IF DB_ID('appdb') IS NULL
BEGIN
    CREATE DATABASE appdb;
END
GO
