namespace Matriculas.Api.Modulos.Identidad.Modelos;

/// <summary>Lo que devuelve usp_Usuario_PorCorreo.</summary>
public sealed class UsuarioAutenticacion
{
    public int    Id           { get; init; }
    public string Email        { get; init; } = "";
    public string PasswordHash { get; init; } = "";
    public string Rol          { get; init; } = "";
    public bool   Activo       { get; init; }

    // Solo uno de los dos tiene valor, segun el rol.
    public int?   AlumnoId     { get; init; }
    public int?   DocenteId    { get; init; }

    public string? Nombres     { get; init; }
    public string? Apellidos   { get; init; }
}
