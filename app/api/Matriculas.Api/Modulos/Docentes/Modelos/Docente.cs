namespace Matriculas.Api.Modulos.Docentes.Modelos;

public sealed class Docente
{
    public int    Id           { get; init; }
    public string Codigo       { get; init; } = "";
    public string Nombres      { get; init; } = "";
    public string Apellidos    { get; init; } = "";
    public string? Especialidad { get; init; }
    public string Email        { get; init; } = "";
    public bool   Activo       { get; init; }
    public int    Cursos       { get; init; }   // solo lo devuelve Listar
}

public sealed class DocenteCreado
{
    public int DocenteId { get; init; }
    public int UsuarioId { get; init; }
}
