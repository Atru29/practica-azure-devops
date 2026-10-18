namespace Matriculas.Api.Comun;

/// <summary>
/// Los nombres de los procedimientos, en un solo sitio.
/// Si manana se renombra uno en la base, el compilador senala
/// todos los puntos que hay que tocar. Con cadenas sueltas por el
/// codigo, el fallo aparecería en ejecucion y en produccion.
/// </summary>
public static class Procedimientos
{
    public static class Alumno
    {
        public const string Listar      = "dbo.usp_Alumno_Listar";
        public const string Obtener     = "dbo.usp_Alumno_Obtener";
        public const string Crear       = "dbo.usp_Alumno_Crear";
        public const string Actualizar  = "dbo.usp_Alumno_Actualizar";
        public const string Desactivar  = "dbo.usp_Alumno_Desactivar";
    }

    public static class Docente
    {
        public const string Listar      = "dbo.usp_Docente_Listar";
        public const string Obtener     = "dbo.usp_Docente_Obtener";
        public const string Crear       = "dbo.usp_Docente_Crear";
        public const string Desactivar  = "dbo.usp_Docente_Desactivar";
    }

    public static class Curso
    {
        public const string Listar      = "dbo.usp_Curso_Listar";
        public const string Crear       = "dbo.usp_Curso_Crear";
        public const string Actualizar  = "dbo.usp_Curso_Actualizar";
    }

    public static class Periodo
    {
        public const string Listar      = "dbo.usp_Periodo_Listar";
        public const string Abierto     = "dbo.usp_Periodo_Abierto";
        public const string Crear       = "dbo.usp_Periodo_Crear";
        public const string Cerrar      = "dbo.usp_Periodo_Cerrar";
    }

    public static class Matricula
    {
        public const string Solicitar         = "dbo.usp_Matricula_Solicitar";
        public const string Aprobar           = "dbo.usp_Matricula_Aprobar";
        public const string Rechazar          = "dbo.usp_Matricula_Rechazar";
        public const string CrearAprobada     = "dbo.usp_Matricula_CrearAprobada";
        public const string ListarPendientes  = "dbo.usp_Matricula_ListarPendientes";
        public const string PorAlumno         = "dbo.usp_Matricula_PorAlumno";
        public const string Obtener           = "dbo.usp_Matricula_Obtener";
        public const string GuardarConstancia = "dbo.usp_Matricula_GuardarConstancia";
    }

    public static class Usuario
    {
        public const string PorCorreo = "dbo.usp_Usuario_PorCorreo";
    }
}
