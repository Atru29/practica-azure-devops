namespace Matriculas.Api.Modulos.Cursos.Modelos;

public sealed class Curso
{
    public int    Id        { get; init; }
    public string Codigo    { get; init; } = "";
    public string Nombre    { get; init; } = "";
    public byte   Creditos  { get; init; }
    public byte   Ciclo     { get; init; }
    public int    DocenteId { get; init; }
    public string Docente   { get; init; } = "";

    /// <summary>Codigos que este curso exige aprobados, o null si no exige nada.</summary>
    public string? Requisitos { get; init; }

    /// <summary>
    /// true si al alumno que consulta le falta algun requisito.
    /// Siempre false cuando quien mira no es un alumno.
    /// </summary>
    public bool   Bloqueado  { get; init; }
}

public sealed class CursoCreado
{
    public int CursoId { get; init; }
}
