-- =====================================================================
--  REGISTRO DE ERRORES
--
--  La trampa de esto: si el error deshace la transaccion, tambien
--  deshace la fila que acabas de insertar en el log. Por eso el orden
--  dentro del CATCH es SIEMPRE:
--
--      1. ROLLBACK    deshacer el trabajo a medias
--      2. registrar   ya fuera de la transaccion, asi SI persiste
--      3. THROW       relanzar el error original al cliente
--
--  Invertir 1 y 2 hace que el log desaparezca justo cuando lo necesitas.
-- =====================================================================

-- La columna calculada PERSISTED exige estas opciones. sqlcmd las trae
-- desactivadas por defecto, de ahi el error 1934 si faltan.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.ErrorLog') IS NULL
BEGIN
    CREATE TABLE dbo.ErrorLog (
        Id             BIGINT IDENTITY(1,1) NOT NULL,
        Fecha          DATETIME2(3)   NOT NULL CONSTRAINT DF_ErrorLog_Fecha   DEFAULT (SYSUTCDATETIME()),
        Procedimiento  NVARCHAR(128)  NULL,
        NumeroError    INT            NULL,
        Severidad      TINYINT        NULL,
        Linea          INT            NULL,
        Mensaje        NVARCHAR(2048) NULL,
        Parametros     NVARCHAR(1000) NULL,
        Usuario        NVARCHAR(128)  NOT NULL CONSTRAINT DF_ErrorLog_Usuario DEFAULT (SUSER_SNAME()),

        -- Distingue una regla de negocio de un fallo real. Sin esto, el
        -- log se llena de "el alumno ya tiene matricula" y nadie ve el
        -- error de verdad cuando ocurre.
        EsReglaNegocio AS (CASE WHEN NumeroError BETWEEN 50000 AND 59999
                                THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) PERSISTED,

        CONSTRAINT PK_ErrorLog PRIMARY KEY (Id)
    );

    -- Para la consulta habitual: "que fallo de verdad en las ultimas horas"
    CREATE INDEX IX_ErrorLog_Fecha ON dbo.ErrorLog (Fecha DESC)
        INCLUDE (Procedimiento, NumeroError);
END
GO


-- ---------------------------------------------------------------------
--  Se llama SOLO desde dentro de un bloque CATCH.
--  Las funciones ERROR_* siguen disponibles ahi aunque ya se haya
--  hecho el ROLLBACK.
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Error_Registrar
    @v_parametros NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF ERROR_NUMBER() IS NULL
        RETURN;        -- no se llamo desde un CATCH: no hay nada que registrar

    -- Si registrar el error fallara, no debe tapar el error original.
    BEGIN TRY
        INSERT INTO dbo.ErrorLog
            (Procedimiento, NumeroError, Severidad, Linea, Mensaje, Parametros)
        VALUES
            (ERROR_PROCEDURE(), ERROR_NUMBER(), ERROR_SEVERITY(),
             ERROR_LINE(), ERROR_MESSAGE(), @v_parametros);
    END TRY
    BEGIN CATCH
        -- a proposito: se traga el fallo del log. Es peor perder el
        -- error original que perder su registro.
    END CATCH
END
GO


-- ---------------------------------------------------------------------
--  Consultas de diagnostico
-- ---------------------------------------------------------------------

-- Los fallos REALES de las ultimas 24 horas, sin el ruido de las
-- reglas de negocio
-- SELECT Fecha, Procedimiento, NumeroError, Mensaje, Parametros
-- FROM   dbo.ErrorLog
-- WHERE  EsReglaNegocio = 0
--   AND  Fecha >= DATEADD(HOUR, -24, SYSUTCDATETIME())
-- ORDER BY Fecha DESC;

-- Que reglas se incumplen mas: dice mucho sobre la interfaz de usuario.
-- Si "ya tiene matricula" sale 200 veces, es que la pantalla no lo avisa.
-- SELECT NumeroError, Mensaje = MIN(Mensaje), Veces = COUNT(*)
-- FROM   dbo.ErrorLog
-- WHERE  EsReglaNegocio = 1
-- GROUP BY NumeroError
-- ORDER BY Veces DESC;
