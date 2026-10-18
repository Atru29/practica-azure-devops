using System.ComponentModel.DataAnnotations;

namespace Matriculas.Api.Modulos.Identidad.Dtos;

public sealed class EntrarDto
{
    [Required, EmailAddress]
    public string Email { get; init; } = "";

    [Required]
    public string Clave { get; init; } = "";
}

/// <summary>
/// Lo que se devuelve tras entrar. El token lleva dentro el rol y los
/// identificadores, pero se repiten aqui para que Angular no tenga que
/// descodificarlo solo para pintar el nombre en la cabecera.
/// </summary>
public sealed class SesionDto
{
    public string  Token      { get; init; } = "";
    public DateTime Expira    { get; init; }
    public int     UsuarioId  { get; init; }
    public string  Email      { get; init; } = "";
    public string  Rol        { get; init; } = "";
    public string  Nombre     { get; init; } = "";
    public int?    AlumnoId   { get; init; }
    public int?    DocenteId  { get; init; }
}
