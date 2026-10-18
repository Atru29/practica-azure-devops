namespace Matriculas.Api.Modulos.Alumnos.Modelos;

/// <summary>
/// Lo que devuelven usp_Alumno_Listar y usp_Alumno_Obtener.
/// Los nombres coinciden con las columnas: asi Dapper mapea solo.
/// </summary>
public sealed class Alumno
{
    public int    Id        { get; init; }
    public string Codigo    { get; init; } = "";
    public string Nombres   { get; init; } = "";
    public string Apellidos { get; init; } = "";
    public string Dni       { get; init; } = "";
    public string Email     { get; init; } = "";
    public bool   Activo    { get; init; }
}

/// <summary>Lo que devuelve usp_Alumno_Crear.</summary>
public sealed class AlumnoCreado
{
    public int AlumnoId  { get; init; }
    public int UsuarioId { get; init; }
}
