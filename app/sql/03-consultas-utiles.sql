-- =====================================================================
--  Consultas para comprobar que el modelo responde a lo que se le pide
-- =====================================================================

-- Matriculas pendientes de resolver, que es la bandeja del gestor
SELECT  m.Id,
        a.Codigo        AS AlumnoCodigo,
        a.Nombres + ' ' + a.Apellidos AS Alumno,
        p.Nombre        AS Periodo,
        m.FechaSolicitud,
        COUNT(mc.CursoId) AS Cursos,
        SUM(c.Creditos)   AS Creditos
FROM        dbo.Matricula        m
JOIN        dbo.Alumno           a  ON a.Id = m.AlumnoId
JOIN        dbo.PeriodoAcademico p  ON p.Id = m.PeriodoId
LEFT JOIN   dbo.MatriculaCurso   mc ON mc.MatriculaId = m.Id
LEFT JOIN   dbo.Curso            c  ON c.Id = mc.CursoId
WHERE  m.Estado = 'Solicitada'
GROUP BY m.Id, a.Codigo, a.Nombres, a.Apellidos, p.Nombre, m.FechaSolicitud
ORDER BY m.FechaSolicitud;
GO

-- Los alumnos de un curso: el muchos a muchos recorrido al reves
SELECT  c.Codigo, c.Nombre,
        a.Codigo AS AlumnoCodigo,
        a.Nombres + ' ' + a.Apellidos AS Alumno
FROM      dbo.Curso           c
JOIN      dbo.MatriculaCurso  mc ON mc.CursoId   = c.Id
JOIN      dbo.Matricula       m  ON m.Id         = mc.MatriculaId
JOIN      dbo.Alumno          a  ON a.Id         = m.AlumnoId
WHERE  c.Codigo = 'BD101'
  AND  m.Estado = 'Aprobada';
GO

-- Carga de cada docente en el periodo abierto
SELECT  d.Codigo, d.Nombres + ' ' + d.Apellidos AS Docente,
        COUNT(DISTINCT c.Id)  AS Cursos,
        COUNT(m.Id)           AS Matriculados
FROM      dbo.Docente         d
JOIN      dbo.Curso           c  ON c.DocenteId = d.Id
LEFT JOIN dbo.MatriculaCurso  mc ON mc.CursoId  = c.Id
LEFT JOIN dbo.Matricula       m  ON m.Id = mc.MatriculaId AND m.Estado = 'Aprobada'
GROUP BY d.Codigo, d.Nombres, d.Apellidos;
GO
