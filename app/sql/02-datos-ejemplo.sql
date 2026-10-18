-- =====================================================================
--  Datos minimos para poder probar el flujo de principio a fin.
--  Las contrasenas van ya cifradas con BCrypt.
-- =====================================================================

-- DEMO: todas las cuentas usan la misma contrasena: admin123.$
-- Se muestra en la propia pantalla de entrada. No es un descuido:
-- es una demostracion, no un sistema con usuarios reales.
-- El hash es de BCrypt, con la sal incluida dentro. Se repite el mismo
-- en los cinco solo porque son datos de prueba; en produccion cada
-- usuario tendria el suyo, con su propia sal.
INSERT INTO dbo.Usuario (Email, PasswordHash, Rol) VALUES
  ('ana.quispe@universidad-demo.edu', '$2a$11$rUv51EG.PwYE8NhAcdJML.xtVhuo.eX9dF.nSh3BVQixk4Ri8qYQ2', 'Alumno'),
  ('luis.ramos@universidad-demo.edu', '$2a$11$rUv51EG.PwYE8NhAcdJML.xtVhuo.eX9dF.nSh3BVQixk4Ri8qYQ2', 'Alumno'),
  ('gestor@universidad-demo.edu',     '$2a$11$rUv51EG.PwYE8NhAcdJML.xtVhuo.eX9dF.nSh3BVQixk4Ri8qYQ2', 'Gestor'),
  ('m.torres@universidad-demo.edu',   '$2a$11$rUv51EG.PwYE8NhAcdJML.xtVhuo.eX9dF.nSh3BVQixk4Ri8qYQ2', 'Docente'),
  ('j.flores@universidad-demo.edu',   '$2a$11$rUv51EG.PwYE8NhAcdJML.xtVhuo.eX9dF.nSh3BVQixk4Ri8qYQ2', 'Docente');
GO

INSERT INTO dbo.Alumno (UsuarioId, Codigo, Nombres, Apellidos, Dni)
SELECT Id, 'A2026001', 'Ana',  'Quispe Mamani', '71234567' FROM dbo.Usuario WHERE Email = 'ana.quispe@universidad-demo.edu'
UNION ALL
SELECT Id, 'A2026002', 'Luis', 'Ramos Diaz',    '72345678' FROM dbo.Usuario WHERE Email = 'luis.ramos@universidad-demo.edu';
GO

INSERT INTO dbo.Docente (UsuarioId, Codigo, Nombres, Apellidos, Especialidad)
SELECT Id, 'D001', 'Maria', 'Torres Leon',  'Bases de datos'      FROM dbo.Usuario WHERE Email = 'm.torres@universidad-demo.edu'
UNION ALL
SELECT Id, 'D002', 'Jorge', 'Flores Vega',  'Desarrollo web'      FROM dbo.Usuario WHERE Email = 'j.flores@universidad-demo.edu';
GO

INSERT INTO dbo.PeriodoAcademico (Nombre, FechaInicio, FechaFin, Estado) VALUES
  ('2026-I',  '2026-03-16', '2026-07-24', 'Cerrado'),
  ('2026-II', '2026-08-17', '2026-12-18', 'Abierto');
GO

INSERT INTO dbo.Curso (DocenteId, Codigo, Nombre, Creditos, Ciclo)
SELECT Id, 'BD101',  'Bases de datos I',          4, 3 FROM dbo.Docente WHERE Codigo = 'D001'
UNION ALL
SELECT Id, 'BD201',  'Bases de datos II',         4, 4 FROM dbo.Docente WHERE Codigo = 'D001'
UNION ALL
SELECT Id, 'WEB101', 'Desarrollo web',            4, 3 FROM dbo.Docente WHERE Codigo = 'D002'
UNION ALL
SELECT Id, 'CLD101', 'Computacion en la nube',    3, 5 FROM dbo.Docente WHERE Codigo = 'D002';
GO

-- ---------------------------------------------------------------------
--  Prerrequisitos
--  Para llevar Bases de datos II hay que traer aprobada Bases de datos I.
-- ---------------------------------------------------------------------
INSERT INTO dbo.CursoPrerrequisito (CursoId, CursoRequeridoId)
SELECT destino.Id, requerido.Id
FROM   dbo.Curso destino
JOIN   dbo.Curso requerido ON requerido.Codigo = 'BD101'
WHERE  destino.Codigo = 'BD201';
GO

-- ---------------------------------------------------------------------
--  Historial del periodo anterior (2026-I), ya cerrado y con notas.
--
--  Ana aprobo Bases de datos I con 15  -> podra llevar BD201.
--  Luis la desaprobo con 8             -> el sistema le parara los pies.
--
--  Asi la demostracion cuenta sola por que existe el prerrequisito.
-- ---------------------------------------------------------------------
INSERT INTO dbo.Matricula (AlumnoId, PeriodoId, Estado, FechaSolicitud, GestorId, FechaResolucion)
SELECT a.Id, p.Id, 'Aprobada', '2026-03-10T09:00:00', g.Id, '2026-03-12T11:30:00'
FROM   dbo.Alumno a
CROSS JOIN dbo.PeriodoAcademico p
CROSS JOIN dbo.Usuario g
WHERE  p.Nombre = '2026-I'
  AND  g.Email  = 'gestor@universidad-demo.edu'
  AND  a.Codigo IN ('A2026001', 'A2026002');
GO

-- Notas de ese periodo. La columna Aprobado se calcula sola: 11 es el
-- minimo, asi que el 8 de Luis queda como desaprobado sin que nadie lo
-- marque a mano.
INSERT INTO dbo.MatriculaCurso (MatriculaId, CursoId, Nota, NotaPuestaEn)
SELECT m.Id, c.Id, v.Nota, '2026-07-20T18:00:00'
FROM   dbo.Matricula m
JOIN   dbo.Alumno    a ON a.Id = m.AlumnoId
JOIN   dbo.PeriodoAcademico p ON p.Id = m.PeriodoId
JOIN   (VALUES ('A2026001', 'BD101',  15.00),
               ('A2026001', 'WEB101', 13.50),
               ('A2026002', 'BD101',   8.00),
               ('A2026002', 'WEB101', 12.00)) AS v(Alumno, Curso, Nota)
         ON v.Alumno = a.Codigo
JOIN   dbo.Curso c ON c.Codigo = v.Curso
WHERE  p.Nombre = '2026-I';
GO

-- Una matricula solicitada, sin resolver todavia
INSERT INTO dbo.Matricula (AlumnoId, PeriodoId)
SELECT a.Id, p.Id
FROM dbo.Alumno a, dbo.PeriodoAcademico p
WHERE a.Codigo = 'A2026001' AND p.Nombre = '2026-II';
GO

-- OJO con el filtro por periodo: sin el, al tener Ana tambien una
-- matricula en 2026-I, esta sentencia intenta meter los mismos cursos
-- en las dos y la clave duplicada tumba la insercion entera.
INSERT INTO dbo.MatriculaCurso (MatriculaId, CursoId)
SELECT m.Id, c.Id
FROM dbo.Matricula m
JOIN dbo.Alumno a ON a.Id = m.AlumnoId
JOIN dbo.PeriodoAcademico p ON p.Id = m.PeriodoId
CROSS JOIN dbo.Curso c
WHERE a.Codigo = 'A2026001'
  AND p.Nombre = '2026-II'
  AND c.Codigo IN ('BD101','WEB101');
GO
