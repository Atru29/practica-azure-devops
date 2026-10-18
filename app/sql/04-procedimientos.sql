-- =====================================================================
--  PROCEDIMIENTOS ALMACENADOS
--
--  Convencion:  usp_<Entidad>_<Accion>
--  NUNCA "sp_": esta reservado para los de sistema y SQL Server los
--  busca primero en master, dos busquedas por llamada.
--
--  Parametros:  @i_ entero  @v_ texto  @d_ fecha  @b_ bit
--
--  Codigos de error (>= 50000 son propios). El API los traduce a HTTP:
--     50001-50009  datos invalidos    -> 400
--     50010-50019  estado incorrecto  -> 409
--     50020-50029  no encontrado      -> 404
--
--  Estructura de todo procedimiento que ESCRIBE:
--
--      SET NOCOUNT ON; SET XACT_ABORT ON;
--      BEGIN TRY
--          validaciones            <- fuera de la transaccion
--          BEGIN TRANSACTION
--              escrituras
--          COMMIT
--      END TRY
--      BEGIN CATCH
--          1. ROLLBACK      deshacer lo que quedo a medias
--          2. registrar     ya fuera de la transaccion, asi persiste
--          3. THROW         relanzar el error ORIGINAL
--      END CATCH
--
--  Requiere 06-errorlog.sql cargado antes.
-- =====================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


-- =====================================================================
--  IDENTIDAD
-- =====================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Usuario_PorCorreo
    @v_email NVARCHAR(160)
AS
BEGIN
    SET NOCOUNT ON;

    -- Devuelve tambien a que alumno o docente corresponde, para que el
    -- API sepa de quien son las matriculas sin una segunda consulta.
    SELECT  u.Id,
            u.Email,
            u.PasswordHash,
            u.Rol,
            u.Activo,
            AlumnoId  = a.Id,
            DocenteId = d.Id,
            Nombres   = COALESCE(a.Nombres,   d.Nombres),
            Apellidos = COALESCE(a.Apellidos, d.Apellidos)
    FROM        dbo.Usuario u
    LEFT JOIN   dbo.Alumno  a ON a.UsuarioId = u.Id
    LEFT JOIN   dbo.Docente d ON d.UsuarioId = u.Id
    WHERE  u.Email = @v_email
      AND  u.Activo = 1;
END
GO


-- =====================================================================
--  MATRICULA  -  el corazon del dominio
-- =====================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Matricula_Solicitar
    @i_alumnoId   INT,
    @i_periodoId  INT,
    @v_cursos     VARCHAR(500)        -- lista separada por comas: '1,3,7'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        ------------------------------------------------------ validaciones
        IF NOT EXISTS (SELECT 1 FROM dbo.Alumno WHERE Id = @i_alumnoId AND Activo = 1)
            THROW 50020, 'El alumno no existe o esta inactivo.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.PeriodoAcademico
                       WHERE Id = @i_periodoId AND Estado = 'Abierto')
            THROW 50001, 'El periodo no existe o no esta abierto para matricula.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Matricula
                   WHERE AlumnoId = @i_alumnoId AND PeriodoId = @i_periodoId)
            THROW 50010, 'El alumno ya tiene una matricula en este periodo.', 1;

        DECLARE @Cursos TABLE (CursoId INT PRIMARY KEY);

        INSERT INTO @Cursos (CursoId)
        SELECT DISTINCT TRY_CAST(value AS INT)
        FROM   STRING_SPLIT(@v_cursos, ',')
        WHERE  TRY_CAST(value AS INT) IS NOT NULL;

        IF NOT EXISTS (SELECT 1 FROM @Cursos)
            THROW 50002, 'Hay que indicar al menos un curso.', 1;

        IF EXISTS (SELECT 1 FROM @Cursos c
                   WHERE NOT EXISTS (SELECT 1 FROM dbo.Curso WHERE Id = c.CursoId))
            THROW 50003, 'Alguno de los cursos indicados no existe.', 1;

        DECLARE @creditos INT =
            (SELECT SUM(cu.Creditos) FROM @Cursos c JOIN dbo.Curso cu ON cu.Id = c.CursoId);

        IF @creditos > 24
            THROW 50004, 'La matricula supera el maximo de 24 creditos.', 1;

        -- Prerrequisitos: cada curso pedido puede exigir otros aprobados.
        --
        -- "Aprobado" significa: aparece en una matricula APROBADA de este
        -- mismo alumno y con Aprobado = 1. No basta con haberlo llevado.
        DECLARE @v_faltan NVARCHAR(500);

        SELECT @v_faltan = STRING_AGG(
                   CONCAT(destino.Codigo, ' exige ', requerido.Codigo), '; ')
        FROM       @Cursos                 c
        JOIN       dbo.Curso               destino   ON destino.Id   = c.CursoId
        JOIN       dbo.CursoPrerrequisito  p         ON p.CursoId    = c.CursoId
        JOIN       dbo.Curso               requerido ON requerido.Id = p.CursoRequeridoId
        WHERE NOT EXISTS (
                  SELECT 1
                  FROM   dbo.MatriculaCurso mc
                  JOIN   dbo.Matricula      m ON m.Id = mc.MatriculaId
                  WHERE  m.AlumnoId  = @i_alumnoId
                    AND  m.Estado    = 'Aprobada'
                    AND  mc.CursoId  = p.CursoRequeridoId
                    AND  mc.Aprobado = 1);

        IF @v_faltan IS NOT NULL
        BEGIN
            -- THROW admite una variable como mensaje, no una expresion,
            -- asi que el texto se arma antes.
            DECLARE @v_msg NVARCHAR(600) =
                CONCAT('No cumples los prerrequisitos: ', @v_faltan, '.');
            THROW 50011, @v_msg, 1;
        END

        ------------------------------------------------------ escritura
        DECLARE @id INT;

        BEGIN TRANSACTION;

            INSERT INTO dbo.Matricula (AlumnoId, PeriodoId)
            VALUES (@i_alumnoId, @i_periodoId);

            SET @id = SCOPE_IDENTITY();   -- NO @@IDENTITY: devolveria el id
                                          -- generado por un disparador

            INSERT INTO dbo.MatriculaCurso (MatriculaId, CursoId)
            SELECT @id, CursoId FROM @Cursos;

        COMMIT TRANSACTION;

        SELECT MatriculaId = @id, Estado = 'Solicitada', Creditos = @creditos;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_alumnoId=', @i_alumnoId, ' @i_periodoId=', @i_periodoId, ' @v_cursos=', @v_cursos);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE dbo.usp_Matricula_Aprobar
    @i_matriculaId INT,
    @i_gestorId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @estado VARCHAR(10);

        BEGIN TRANSACTION;

            -- UPDLOCK y HOLDLOCK: reserva la fila mientras se decide, para
            -- que dos gestores pulsando "aprobar" a la vez no la aprueben
            -- los dos. Sin esto, ambos leerian 'Solicitada'.
            SELECT @estado = Estado
            FROM   dbo.Matricula WITH (UPDLOCK, HOLDLOCK)
            WHERE  Id = @i_matriculaId;

            IF @estado IS NULL
                THROW 50021, 'La matricula no existe.', 1;

            IF @estado <> 'Solicitada'
                THROW 50011, 'Solo se puede aprobar una matricula en estado Solicitada.', 1;

            IF NOT EXISTS (SELECT 1 FROM dbo.Usuario
                           WHERE Id = @i_gestorId AND Rol = 'Gestor' AND Activo = 1)
                THROW 50005, 'El usuario indicado no es un gestor activo.', 1;

            UPDATE dbo.Matricula
            SET    Estado          = 'Aprobada',
                   GestorId        = @i_gestorId,
                   FechaResolucion = SYSUTCDATETIME()
            WHERE  Id = @i_matriculaId;

        COMMIT TRANSACTION;

        SELECT MatriculaId = @i_matriculaId, Estado = 'Aprobada';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_matriculaId=', @i_matriculaId, ' @i_gestorId=', @i_gestorId);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE dbo.usp_Matricula_Rechazar
    @i_matriculaId INT,
    @i_gestorId    INT,
    @v_observacion NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Si rechazas algo, el alumno tiene derecho a saber por que.
        IF @v_observacion IS NULL OR LTRIM(RTRIM(@v_observacion)) = ''
            THROW 50006, 'Hay que indicar el motivo del rechazo.', 1;

        DECLARE @estado VARCHAR(10);

        BEGIN TRANSACTION;

            SELECT @estado = Estado
            FROM   dbo.Matricula WITH (UPDLOCK, HOLDLOCK)
            WHERE  Id = @i_matriculaId;

            IF @estado IS NULL
                THROW 50021, 'La matricula no existe.', 1;

            IF @estado <> 'Solicitada'
                THROW 50011, 'Solo se puede rechazar una matricula en estado Solicitada.', 1;

            IF NOT EXISTS (SELECT 1 FROM dbo.Usuario
                           WHERE Id = @i_gestorId AND Rol = 'Gestor' AND Activo = 1)
                THROW 50005, 'El usuario indicado no es un gestor activo.', 1;

            UPDATE dbo.Matricula
            SET    Estado          = 'Rechazada',
                   GestorId        = @i_gestorId,
                   FechaResolucion = SYSUTCDATETIME(),
                   Observacion     = @v_observacion
            WHERE  Id = @i_matriculaId;

        COMMIT TRANSACTION;

        SELECT MatriculaId = @i_matriculaId, Estado = 'Rechazada';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_matriculaId=', @i_matriculaId, ' @i_gestorId=', @i_gestorId);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE dbo.usp_Matricula_CrearAprobada
    @i_alumnoId   INT,
    @i_periodoId  INT,
    @v_cursos     VARCHAR(500),
    @i_gestorId   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario
                       WHERE Id = @i_gestorId AND Rol = 'Gestor' AND Activo = 1)
            THROW 50005, 'El usuario indicado no es un gestor activo.', 1;

        DECLARE @salida TABLE (MatriculaId INT, Estado VARCHAR(10), Creditos INT);
        DECLARE @id INT;

        -- Se reutiliza el procedimiento de solicitud para no duplicar las
        -- validaciones. Los dos pasos van en la MISMA transaccion: o queda
        -- aprobada o no queda nada.
        BEGIN TRANSACTION;

            INSERT INTO @salida
            EXEC dbo.usp_Matricula_Solicitar @i_alumnoId, @i_periodoId, @v_cursos;

            SET @id = (SELECT MatriculaId FROM @salida);

            UPDATE dbo.Matricula
            SET    Estado          = 'Aprobada',
                   GestorId        = @i_gestorId,
                   FechaResolucion = SYSUTCDATETIME()
            WHERE  Id = @id;

        COMMIT TRANSACTION;

        SELECT MatriculaId = @id, Estado = 'Aprobada';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_alumnoId=', @i_alumnoId, ' @i_periodoId=', @i_periodoId, ' @v_cursos=', @v_cursos, ' @i_gestorId=', @i_gestorId);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE dbo.usp_Matricula_ListarPendientes
    @i_periodoId INT = NULL      -- NULL = todos los periodos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  m.Id,
            AlumnoCodigo = a.Codigo,
            Alumno       = a.Nombres + ' ' + a.Apellidos,
            Periodo      = p.Nombre,
            m.FechaSolicitud,
            Cursos       = COUNT(mc.CursoId),
            Creditos     = SUM(c.Creditos)
    FROM        dbo.Matricula        m
    JOIN        dbo.Alumno           a  ON a.Id = m.AlumnoId
    JOIN        dbo.PeriodoAcademico p  ON p.Id = m.PeriodoId
    LEFT JOIN   dbo.MatriculaCurso   mc ON mc.MatriculaId = m.Id
    LEFT JOIN   dbo.Curso            c  ON c.Id = mc.CursoId
    WHERE   m.Estado = 'Solicitada'
      AND  (@i_periodoId IS NULL OR m.PeriodoId = @i_periodoId)
    GROUP BY m.Id, a.Codigo, a.Nombres, a.Apellidos, p.Nombre, m.FechaSolicitud
    ORDER BY m.FechaSolicitud;
END
GO


CREATE OR ALTER PROCEDURE dbo.usp_Matricula_PorAlumno
    @i_alumnoId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  m.Id,
            Periodo = p.Nombre,
            m.Estado,
            m.FechaSolicitud,
            m.FechaResolucion,
            m.Observacion,
            m.ConstanciaRuta,
            Cursos   = COUNT(mc.CursoId),
            Creditos = SUM(c.Creditos)
    FROM        dbo.Matricula        m
    JOIN        dbo.PeriodoAcademico p  ON p.Id = m.PeriodoId
    LEFT JOIN   dbo.MatriculaCurso   mc ON mc.MatriculaId = m.Id
    LEFT JOIN   dbo.Curso            c  ON c.Id = mc.CursoId
    WHERE  m.AlumnoId = @i_alumnoId
    GROUP BY m.Id, p.Nombre, m.Estado, m.FechaSolicitud,
             m.FechaResolucion, m.Observacion, m.ConstanciaRuta
    ORDER BY m.FechaSolicitud DESC;
END
GO


-- Devuelve DOS conjuntos: cabecera y cursos. Dapper los lee con
-- QueryMultiple, y asi no se repiten los datos de cabecera en cada fila.
CREATE OR ALTER PROCEDURE dbo.usp_Matricula_Obtener
    @i_matriculaId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  m.Id,
            m.AlumnoId,
            AlumnoCodigo = a.Codigo,
            Alumno       = a.Nombres + ' ' + a.Apellidos,
            Periodo      = p.Nombre,
            m.Estado,
            m.FechaSolicitud,
            m.FechaResolucion,
            Gestor       = g.Email,
            m.Observacion,
            m.ConstanciaRuta,
            m.ConstanciaGeneradaEn
    FROM        dbo.Matricula        m
    JOIN        dbo.Alumno           a ON a.Id = m.AlumnoId
    JOIN        dbo.PeriodoAcademico p ON p.Id = m.PeriodoId
    LEFT JOIN   dbo.Usuario          g ON g.Id = m.GestorId
    WHERE  m.Id = @i_matriculaId;

    SELECT  c.Id,
            c.Codigo,
            c.Nombre,
            c.Creditos,
            c.Ciclo,
            Docente = d.Nombres + ' ' + d.Apellidos
    FROM        dbo.MatriculaCurso mc
    JOIN        dbo.Curso          c ON c.Id = mc.CursoId
    JOIN        dbo.Docente        d ON d.Id = c.DocenteId
    WHERE  mc.MatriculaId = @i_matriculaId
    ORDER BY c.Codigo;
END
GO


CREATE OR ALTER PROCEDURE dbo.usp_Matricula_GuardarConstancia
    @i_matriculaId INT,
    @v_ruta        NVARCHAR(400)      -- ruta RELATIVA, nunca la URL completa
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @estado VARCHAR(10);

        SELECT @estado = Estado FROM dbo.Matricula WHERE Id = @i_matriculaId;

        IF @estado IS NULL
            THROW 50021, 'La matricula no existe.', 1;

        -- El esquema tambien lo impide con CK_Matricula_Constancia; aqui se
        -- comprueba para dar un mensaje util en vez de un error de restriccion.
        IF @estado <> 'Aprobada'
            THROW 50012, 'Solo una matricula aprobada puede tener constancia.', 1;

        UPDATE dbo.Matricula
        SET    ConstanciaRuta       = @v_ruta,
               ConstanciaGeneradaEn = SYSUTCDATETIME()
        WHERE  Id = @i_matriculaId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_matriculaId=', @i_matriculaId, ' @v_ruta=', @v_ruta);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


-- =====================================================================
--  CATALOGOS
--
--  Nada se borra de verdad: se DESACTIVA. Un alumno con matriculas no
--  se puede borrar sin romper claves foraneas, y aunque se pudiera,
--  perderias el historico.
-- =====================================================================

-- ---------------------------------------------------------------------
--  ALUMNO
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Alumno_Listar
    @v_busqueda    NVARCHAR(80) = NULL,
    @b_soloActivos BIT          = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- LIKE '%x%' no puede usar indice: recorre la tabla. Aceptable con
    -- miles de filas; con cientos de miles haria falta texto completo.
    SELECT  a.Id, a.Codigo, a.Nombres, a.Apellidos, a.Dni, a.Activo,
            Email = u.Email
    FROM       dbo.Alumno  a
    JOIN       dbo.Usuario u ON u.Id = a.UsuarioId
    WHERE  (@b_soloActivos = 0 OR a.Activo = 1)
      AND  (@v_busqueda IS NULL
            OR a.Codigo    LIKE '%' + @v_busqueda + '%'
            OR a.Nombres   LIKE '%' + @v_busqueda + '%'
            OR a.Apellidos LIKE '%' + @v_busqueda + '%'
            OR a.Dni       LIKE '%' + @v_busqueda + '%')
    ORDER BY a.Apellidos, a.Nombres;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Alumno_Obtener
    @i_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  a.Id, a.Codigo, a.Nombres, a.Apellidos, a.Dni, a.Activo,
            a.UsuarioId, Email = u.Email
    FROM    dbo.Alumno  a
    JOIN    dbo.Usuario u ON u.Id = a.UsuarioId
    WHERE   a.Id = @i_id;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Alumno_Crear
    @v_email     NVARCHAR(160),
    @v_clave     NVARCHAR(256),     -- ya viene cifrada desde el API
    @v_codigo    VARCHAR(12),
    @v_nombres   NVARCHAR(80),
    @v_apellidos NVARCHAR(80),
    @v_dni       VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE Email = @v_email)
            THROW 50007, 'Ya existe un usuario con ese correo.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Alumno WHERE Codigo = @v_codigo)
            THROW 50007, 'Ya existe un alumno con ese codigo.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Alumno WHERE Dni = @v_dni)
            THROW 50007, 'Ya existe un alumno con ese DNI.', 1;

        DECLARE @usuarioId INT, @alumnoId INT;

        -- Usuario y alumno van juntos: un alumno sin cuenta no puede
        -- entrar, y una cuenta sin alumno no sirve para nada.
        BEGIN TRANSACTION;

            INSERT INTO dbo.Usuario (Email, PasswordHash, Rol)
            VALUES (@v_email, @v_clave, 'Alumno');

            SET @usuarioId = SCOPE_IDENTITY();

            INSERT INTO dbo.Alumno (UsuarioId, Codigo, Nombres, Apellidos, Dni)
            VALUES (@usuarioId, @v_codigo, @v_nombres, @v_apellidos, @v_dni);

            SET @alumnoId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT AlumnoId = @alumnoId, UsuarioId = @usuarioId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        -- @v_clave NO se registra nunca
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@v_email=', @v_email, ' @v_codigo=', @v_codigo, ' @v_dni=', @v_dni);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Alumno_Actualizar
    @i_id        INT,
    @v_nombres   NVARCHAR(80),
    @v_apellidos NVARCHAR(80),
    @v_dni       VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Alumno WHERE Id = @i_id)
            THROW 50020, 'El alumno no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Alumno WHERE Dni = @v_dni AND Id <> @i_id)
            THROW 50007, 'Ya existe otro alumno con ese DNI.', 1;

        UPDATE dbo.Alumno
        SET    Nombres = @v_nombres, Apellidos = @v_apellidos, Dni = @v_dni
        WHERE  Id = @i_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_id=', @i_id, ' @v_dni=', @v_dni);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Alumno_Desactivar
    @i_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Alumno WHERE Id = @i_id)
            THROW 50020, 'El alumno no existe.', 1;

        -- Desactivar a alguien con una solicitud en curso la dejaria
        -- pendiente para siempre en la bandeja del gestor.
        IF EXISTS (SELECT 1 FROM dbo.Matricula
                   WHERE AlumnoId = @i_id AND Estado = 'Solicitada')
            THROW 50013, 'El alumno tiene una matricula pendiente de resolver.', 1;

        BEGIN TRANSACTION;
            UPDATE dbo.Alumno  SET Activo = 0 WHERE Id = @i_id;
            UPDATE dbo.Usuario SET Activo = 0
            WHERE  Id = (SELECT UsuarioId FROM dbo.Alumno WHERE Id = @i_id);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_id=', @i_id);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


-- ---------------------------------------------------------------------
--  DOCENTE
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Docente_Listar
    @b_soloActivos BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  d.Id, d.Codigo, d.Nombres, d.Apellidos, d.Especialidad, d.Activo,
            Email  = u.Email,
            Cursos = (SELECT COUNT(*) FROM dbo.Curso WHERE DocenteId = d.Id)
    FROM       dbo.Docente d
    JOIN       dbo.Usuario u ON u.Id = d.UsuarioId
    WHERE  (@b_soloActivos = 0 OR d.Activo = 1)
    ORDER BY d.Apellidos, d.Nombres;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Docente_Obtener
    @i_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  d.Id, d.Codigo, d.Nombres, d.Apellidos, d.Especialidad, d.Activo,
            d.UsuarioId, Email = u.Email
    FROM    dbo.Docente d
    JOIN    dbo.Usuario u ON u.Id = d.UsuarioId
    WHERE   d.Id = @i_id;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Docente_Crear
    @v_email        NVARCHAR(160),
    @v_clave        NVARCHAR(256),
    @v_codigo       VARCHAR(12),
    @v_nombres      NVARCHAR(80),
    @v_apellidos    NVARCHAR(80),
    @v_especialidad NVARCHAR(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE Email  = @v_email)
            THROW 50007, 'Ya existe un usuario con ese correo.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Docente WHERE Codigo = @v_codigo)
            THROW 50007, 'Ya existe un docente con ese codigo.', 1;

        DECLARE @usuarioId INT, @docenteId INT;

        BEGIN TRANSACTION;

            INSERT INTO dbo.Usuario (Email, PasswordHash, Rol)
            VALUES (@v_email, @v_clave, 'Docente');

            SET @usuarioId = SCOPE_IDENTITY();

            INSERT INTO dbo.Docente (UsuarioId, Codigo, Nombres, Apellidos, Especialidad)
            VALUES (@usuarioId, @v_codigo, @v_nombres, @v_apellidos, @v_especialidad);

            SET @docenteId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT DocenteId = @docenteId, UsuarioId = @usuarioId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@v_email=', @v_email, ' @v_codigo=', @v_codigo);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Docente_Desactivar
    @i_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Docente WHERE Id = @i_id)
            THROW 50020, 'El docente no existe.', 1;

        -- Dejaria sus cursos sin responsable.
        IF EXISTS (SELECT 1 FROM dbo.Curso WHERE DocenteId = @i_id)
            THROW 50013, 'El docente tiene cursos asignados. Reasignalos primero.', 1;

        BEGIN TRANSACTION;
            UPDATE dbo.Docente SET Activo = 0 WHERE Id = @i_id;
            UPDATE dbo.Usuario SET Activo = 0
            WHERE  Id = (SELECT UsuarioId FROM dbo.Docente WHERE Id = @i_id);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_id=', @i_id);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


-- ---------------------------------------------------------------------
--  CURSO
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Curso_Listar
    @i_ciclo     TINYINT = NULL,
    @i_docenteId INT     = NULL,
    -- Si se pasa un alumno, cada curso viene ademas con sus requisitos y
    -- con si ese alumno los cumple. Sin alumno, las dos salen vacias:
    -- un gestor mirando el catalogo no tiene a quien aplicarselo.
    @i_alumnoId  INT     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  c.Id, c.Codigo, c.Nombre, c.Creditos, c.Ciclo,
            c.DocenteId,
            Docente = d.Nombres + ' ' + d.Apellidos,

            -- Codigos de los cursos que este exige, separados por coma.
            Requisitos = (
                SELECT STRING_AGG(req.Codigo, ', ')
                FROM   dbo.CursoPrerrequisito p
                JOIN   dbo.Curso              req ON req.Id = p.CursoRequeridoId
                WHERE  p.CursoId = c.Id),

            -- 1 si al alumno le falta algun requisito por aprobar.
            Bloqueado = CASE
                WHEN @i_alumnoId IS NULL THEN CAST(0 AS BIT)
                WHEN EXISTS (
                    SELECT 1
                    FROM   dbo.CursoPrerrequisito p
                    WHERE  p.CursoId = c.Id
                      AND  NOT EXISTS (
                          SELECT 1
                          FROM   dbo.MatriculaCurso mc
                          JOIN   dbo.Matricula      m ON m.Id = mc.MatriculaId
                          WHERE  m.AlumnoId  = @i_alumnoId
                            AND  m.Estado    = 'Aprobada'
                            AND  mc.CursoId  = p.CursoRequeridoId
                            AND  mc.Aprobado = 1))
                THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END

    FROM    dbo.Curso   c
    JOIN    dbo.Docente d ON d.Id = c.DocenteId
    WHERE  (@i_ciclo     IS NULL OR c.Ciclo     = @i_ciclo)
      AND  (@i_docenteId IS NULL OR c.DocenteId = @i_docenteId)
    ORDER BY c.Ciclo, c.Codigo;
END
GO


-- ---------------------------------------------------------------------
--  usp_MatriculaCurso_RegistrarNota
--  Pone la nota de un curso dentro de una matricula aprobada.
--  La columna Aprobado se calcula sola a partir de la nota.
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_MatriculaCurso_RegistrarNota
    @i_matriculaId INT,
    @i_cursoId     INT,
    @d_nota        DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        ------------------------------------------------------ validaciones
        IF @d_nota IS NULL OR @d_nota < 0 OR @d_nota > 20
            THROW 50005, 'La nota debe estar entre 0 y 20.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.MatriculaCurso
                       WHERE MatriculaId = @i_matriculaId AND CursoId = @i_cursoId)
            THROW 50021, 'Ese curso no figura en la matricula indicada.', 1;

        -- Poner nota a una matricula sin aprobar no tiene sentido: el
        -- alumno no llego a cursarla.
        IF NOT EXISTS (SELECT 1 FROM dbo.Matricula
                       WHERE Id = @i_matriculaId AND Estado = 'Aprobada')
            THROW 50012, 'Solo se ponen notas en matriculas aprobadas.', 1;

        ------------------------------------------------------ escritura
        UPDATE dbo.MatriculaCurso
        SET    Nota         = @d_nota,
               NotaPuestaEn = SYSUTCDATETIME()
        WHERE  MatriculaId  = @i_matriculaId
          AND  CursoId      = @i_cursoId;

        SELECT MatriculaId = @i_matriculaId,
               CursoId     = @i_cursoId,
               Nota        = @d_nota,
               Aprobado    = CASE WHEN @d_nota >= 11.00 THEN 1 ELSE 0 END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_matriculaId=', @i_matriculaId, ' @i_cursoId=', @i_cursoId, ' @d_nota=', @d_nota);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Curso_Crear
    @i_docenteId INT,
    @v_codigo    VARCHAR(12),
    @v_nombre    NVARCHAR(120),
    @i_creditos  TINYINT,
    @i_ciclo     TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Docente WHERE Id = @i_docenteId AND Activo = 1)
            THROW 50020, 'El docente no existe o esta inactivo.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Curso WHERE Codigo = @v_codigo)
            THROW 50007, 'Ya existe un curso con ese codigo.', 1;

        INSERT INTO dbo.Curso (DocenteId, Codigo, Nombre, Creditos, Ciclo)
        VALUES (@i_docenteId, @v_codigo, @v_nombre, @i_creditos, @i_ciclo);

        SELECT CursoId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_docenteId=', @i_docenteId, ' @v_codigo=', @v_codigo);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Curso_Actualizar
    @i_id        INT,
    @i_docenteId INT,
    @v_nombre    NVARCHAR(120),
    @i_creditos  TINYINT,
    @i_ciclo     TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Curso WHERE Id = @i_id)
            THROW 50020, 'El curso no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Docente WHERE Id = @i_docenteId AND Activo = 1)
            THROW 50020, 'El docente no existe o esta inactivo.', 1;

        UPDATE dbo.Curso
        SET    DocenteId = @i_docenteId, Nombre = @v_nombre,
               Creditos  = @i_creditos,  Ciclo  = @i_ciclo
        WHERE  Id = @i_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_id=', @i_id, ' @i_docenteId=', @i_docenteId);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO


-- ---------------------------------------------------------------------
--  PERIODO ACADEMICO
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Periodo_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  p.Id, p.Nombre, p.FechaInicio, p.FechaFin, p.Estado,
            Matriculas = (SELECT COUNT(*) FROM dbo.Matricula WHERE PeriodoId = p.Id)
    FROM    dbo.PeriodoAcademico p
    ORDER BY p.FechaInicio DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Periodo_Abierto
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Nombre, FechaInicio, FechaFin
    FROM   dbo.PeriodoAcademico
    WHERE  Estado = 'Abierto';
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Periodo_Crear
    @v_nombre      VARCHAR(10),
    @d_fechaInicio DATE,
    @d_fechaFin    DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.PeriodoAcademico WHERE Nombre = @v_nombre)
            THROW 50007, 'Ya existe un periodo con ese nombre.', 1;

        -- Solo un periodo abierto a la vez: si no, el alumno no sabria
        -- a cual se esta matriculando.
        IF EXISTS (SELECT 1 FROM dbo.PeriodoAcademico WHERE Estado = 'Abierto')
            THROW 50014, 'Ya hay un periodo abierto. Cierralo antes de crear otro.', 1;

        INSERT INTO dbo.PeriodoAcademico (Nombre, FechaInicio, FechaFin, Estado)
        VALUES (@v_nombre, @d_fechaInicio, @d_fechaFin, 'Abierto');

        SELECT PeriodoId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@v_nombre=', @v_nombre);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Periodo_Cerrar
    @i_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.PeriodoAcademico WHERE Id = @i_id)
            THROW 50020, 'El periodo no existe.', 1;

        -- Cerrar con solicitudes sin resolver las dejaria en el limbo.
        IF EXISTS (SELECT 1 FROM dbo.Matricula
                   WHERE PeriodoId = @i_id AND Estado = 'Solicitada')
            THROW 50013, 'Hay matriculas pendientes de resolver en este periodo.', 1;

        UPDATE dbo.PeriodoAcademico SET Estado = 'Cerrado' WHERE Id = @i_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @v_log NVARCHAR(1000) = CONCAT('@i_id=', @i_id);
        EXEC dbo.usp_Error_Registrar @v_parametros = @v_log;
        THROW;
    END CATCH
END
GO
