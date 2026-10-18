-- =====================================================================
--  Registro de matriculas  -  esquema para Azure SQL Database
--
--  Orden de creacion: primero las tablas sin dependencias, despues las
--  que apuntan a ellas. Una clave foranea no puede apuntar a una tabla
--  que todavia no existe.
-- =====================================================================

-- ---------------------------------------------------------------------
--  Usuario: quien entra al sistema. El rol decide que puede hacer.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Usuario (
    Id            INT IDENTITY(1,1) NOT NULL,
    Email         NVARCHAR(160)     NOT NULL,
    PasswordHash  NVARCHAR(256)     NOT NULL,
    Rol           VARCHAR(10)       NOT NULL,
    Activo        BIT               NOT NULL CONSTRAINT DF_Usuario_Activo   DEFAULT (1),
    CreadoEn      DATETIME2(0)      NOT NULL CONSTRAINT DF_Usuario_CreadoEn DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Usuario       PRIMARY KEY (Id),
    CONSTRAINT UQ_Usuario_Email UNIQUE (Email),
    CONSTRAINT CK_Usuario_Rol   CHECK (Rol IN ('Alumno','Gestor','Docente'))
);
GO

-- ---------------------------------------------------------------------
--  Alumno: el solicitante.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Alumno (
    Id         INT IDENTITY(1,1) NOT NULL,
    UsuarioId  INT               NOT NULL,
    Codigo     VARCHAR(12)       NOT NULL,
    Nombres    NVARCHAR(80)      NOT NULL,
    Apellidos  NVARCHAR(80)      NOT NULL,
    Dni        VARCHAR(12)       NOT NULL,
    Activo     BIT               NOT NULL CONSTRAINT DF_Alumno_Activo DEFAULT (1),

    CONSTRAINT PK_Alumno          PRIMARY KEY (Id),
    CONSTRAINT UQ_Alumno_Codigo   UNIQUE (Codigo),
    CONSTRAINT UQ_Alumno_Dni      UNIQUE (Dni),
    CONSTRAINT UQ_Alumno_Usuario  UNIQUE (UsuarioId),          -- 1 a 1 con Usuario
    CONSTRAINT FK_Alumno_Usuario  FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario (Id)
);
GO

-- ---------------------------------------------------------------------
--  Docente: dicta cursos.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Docente (
    Id            INT IDENTITY(1,1) NOT NULL,
    UsuarioId     INT               NOT NULL,
    Codigo        VARCHAR(12)       NOT NULL,
    Nombres       NVARCHAR(80)      NOT NULL,
    Apellidos     NVARCHAR(80)      NOT NULL,
    Especialidad  NVARCHAR(80)      NULL,
    Activo        BIT               NOT NULL CONSTRAINT DF_Docente_Activo DEFAULT (1),

    CONSTRAINT PK_Docente         PRIMARY KEY (Id),
    CONSTRAINT UQ_Docente_Codigo  UNIQUE (Codigo),
    CONSTRAINT UQ_Docente_Usuario UNIQUE (UsuarioId),
    CONSTRAINT FK_Docente_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario (Id)
);
GO

-- ---------------------------------------------------------------------
--  PeriodoAcademico: solo se puede matricular en uno Abierto.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.PeriodoAcademico (
    Id           INT IDENTITY(1,1) NOT NULL,
    Nombre       VARCHAR(10)       NOT NULL,          -- 2026-I
    FechaInicio  DATE              NOT NULL,
    FechaFin     DATE              NOT NULL,
    Estado       VARCHAR(8)        NOT NULL CONSTRAINT DF_Periodo_Estado DEFAULT ('Abierto'),

    CONSTRAINT PK_Periodo        PRIMARY KEY (Id),
    CONSTRAINT UQ_Periodo_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Periodo_Estado CHECK (Estado IN ('Abierto','Cerrado')),
    CONSTRAINT CK_Periodo_Fechas CHECK (FechaFin > FechaInicio)
);
GO

-- ---------------------------------------------------------------------
--  Curso: pertenece a un docente.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Curso (
    Id         INT IDENTITY(1,1) NOT NULL,
    DocenteId  INT               NOT NULL,
    Codigo     VARCHAR(12)       NOT NULL,
    Nombre     NVARCHAR(120)     NOT NULL,
    Creditos   TINYINT           NOT NULL,
    Ciclo      TINYINT           NOT NULL,

    CONSTRAINT PK_Curso           PRIMARY KEY (Id),
    CONSTRAINT UQ_Curso_Codigo    UNIQUE (Codigo),
    CONSTRAINT FK_Curso_Docente   FOREIGN KEY (DocenteId) REFERENCES dbo.Docente (Id),
    CONSTRAINT CK_Curso_Creditos  CHECK (Creditos BETWEEN 1 AND 10),
    CONSTRAINT CK_Curso_Ciclo     CHECK (Ciclo    BETWEEN 1 AND 10)
);
GO

CREATE INDEX IX_Curso_Docente ON dbo.Curso (DocenteId);
GO

-- ---------------------------------------------------------------------
--  Matricula: el corazon del dominio. Nace Solicitada y el gestor la
--  resuelve. GestorId y FechaResolucion son NULL hasta que eso ocurre.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Matricula (
    Id               INT IDENTITY(1,1) NOT NULL,
    AlumnoId         INT               NOT NULL,
    PeriodoId        INT               NOT NULL,
    Estado           VARCHAR(10)       NOT NULL CONSTRAINT DF_Matricula_Estado DEFAULT ('Solicitada'),
    FechaSolicitud   DATETIME2(0)      NOT NULL CONSTRAINT DF_Matricula_Fecha  DEFAULT (SYSUTCDATETIME()),
    GestorId         INT               NULL,
    FechaResolucion  DATETIME2(0)      NULL,
    Observacion      NVARCHAR(400)     NULL,
    -- ruta RELATIVA dentro del contenedor de Blob Storage, no la URL
    -- completa: si cambia la cuenta de almacenamiento o el dominio, no
    -- hay que actualizar todas las filas.
    ConstanciaRuta       NVARCHAR(400) NULL,
    ConstanciaGeneradaEn DATETIME2(0)  NULL,

    CONSTRAINT PK_Matricula          PRIMARY KEY (Id),
    CONSTRAINT FK_Matricula_Alumno   FOREIGN KEY (AlumnoId)  REFERENCES dbo.Alumno (Id),
    CONSTRAINT FK_Matricula_Periodo  FOREIGN KEY (PeriodoId) REFERENCES dbo.PeriodoAcademico (Id),
    CONSTRAINT FK_Matricula_Gestor   FOREIGN KEY (GestorId)  REFERENCES dbo.Usuario (Id),

    -- un alumno no puede tener dos matriculas en el mismo periodo
    CONSTRAINT UQ_Matricula_Alumno_Periodo UNIQUE (AlumnoId, PeriodoId),

    CONSTRAINT CK_Matricula_Estado CHECK (Estado IN ('Solicitada','Aprobada','Rechazada')),

    -- si esta resuelta, tiene gestor y fecha; si no, ninguno de los dos
    CONSTRAINT CK_Matricula_Resolucion CHECK (
        (Estado = 'Solicitada' AND GestorId IS NULL     AND FechaResolucion IS NULL)
     OR (Estado <> 'Solicitada' AND GestorId IS NOT NULL AND FechaResolucion IS NOT NULL)
    ),

    -- solo una matricula aprobada puede tener constancia, y si la tiene,
    -- tiene tambien la fecha en que se genero
    CONSTRAINT CK_Matricula_Constancia CHECK (
        (ConstanciaRuta IS NULL     AND ConstanciaGeneradaEn IS NULL)
     OR (ConstanciaRuta IS NOT NULL AND ConstanciaGeneradaEn IS NOT NULL AND Estado = 'Aprobada')
    )
);
GO

CREATE INDEX IX_Matricula_Periodo_Estado ON dbo.Matricula (PeriodoId, Estado);
GO

-- ---------------------------------------------------------------------
--  MatriculaCurso: la tabla puente del muchos a muchos.
--  La clave primaria compuesta impide repetir el mismo curso.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.MatriculaCurso (
    MatriculaId  INT           NOT NULL,
    CursoId      INT           NOT NULL,
    AgregadoEn   DATETIME2(0)  NOT NULL CONSTRAINT DF_MatCurso_Fecha DEFAULT (SYSUTCDATETIME()),

    -- Nota sobre 20. NULL mientras el curso sigue en marcha.
    Nota         DECIMAL(4,2)  NULL,
    NotaPuestaEn DATETIME2(0)  NULL,

    -- Se calcula sola a partir de la nota: no hay forma de marcar como
    -- aprobado algo que no llega al minimo. Sigue siendo NULL mientras
    -- no haya nota, que no es lo mismo que estar desaprobado.
    Aprobado AS (CASE WHEN Nota IS NULL   THEN NULL
                      WHEN Nota >= 11.00  THEN CAST(1 AS BIT)
                      ELSE                     CAST(0 AS BIT) END) PERSISTED,

    CONSTRAINT PK_MatriculaCurso         PRIMARY KEY (MatriculaId, CursoId),
    CONSTRAINT FK_MatCurso_Matricula     FOREIGN KEY (MatriculaId) REFERENCES dbo.Matricula (Id) ON DELETE CASCADE,
    CONSTRAINT FK_MatCurso_Curso         FOREIGN KEY (CursoId)     REFERENCES dbo.Curso (Id),
    CONSTRAINT CK_MatCurso_Nota          CHECK (Nota IS NULL OR Nota BETWEEN 0 AND 20),

    -- O hay nota y fecha, o no hay ninguna de las dos.
    CONSTRAINT CK_MatCurso_NotaFecha     CHECK ((Nota IS NULL     AND NotaPuestaEn IS NULL)
                                             OR (Nota IS NOT NULL AND NotaPuestaEn IS NOT NULL))
);
GO

CREATE INDEX IX_MatCurso_Curso ON dbo.MatriculaCurso (CursoId);
GO

-- Para la consulta "que ha aprobado este alumno", que es la que corre
-- cada vez que alguien pide matricula.
CREATE INDEX IX_MatCurso_Aprobado ON dbo.MatriculaCurso (CursoId, Aprobado)
    INCLUDE (MatriculaId);
GO


-- ---------------------------------------------------------------------
--  CursoPrerrequisito
--  Que cursos hay que traer aprobados para poder llevar otro.
--  Es la tabla relacionandose consigo misma: un curso exige otros.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.CursoPrerrequisito (
    CursoId          INT NOT NULL,   -- el que se quiere llevar
    CursoRequeridoId INT NOT NULL,   -- el que hay que traer aprobado

    CONSTRAINT PK_CursoPrerrequisito    PRIMARY KEY (CursoId, CursoRequeridoId),

    -- Sin ON DELETE CASCADE a proposito: dos caminos en cascada hacia
    -- la misma tabla y SQL Server rechaza la creacion.
    CONSTRAINT FK_Prerreq_Curso         FOREIGN KEY (CursoId)          REFERENCES dbo.Curso (Id),
    CONSTRAINT FK_Prerreq_Requerido     FOREIGN KEY (CursoRequeridoId) REFERENCES dbo.Curso (Id),

    -- Un curso no puede exigirse a si mismo.
    CONSTRAINT CK_Prerreq_NoMismo       CHECK (CursoId <> CursoRequeridoId)
);
GO

CREATE INDEX IX_Prerreq_Requerido ON dbo.CursoPrerrequisito (CursoRequeridoId);
GO
