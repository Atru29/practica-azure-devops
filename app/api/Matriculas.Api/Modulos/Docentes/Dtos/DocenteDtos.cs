using System.ComponentModel.DataAnnotations;

namespace Matriculas.Api.Modulos.Docentes.Dtos;

public sealed class CrearDocenteDto
{
    [Required, EmailAddress, MaxLength(160)]
    public string Email { get; init; } = "";

    [Required, MinLength(8), MaxLength(100)]
    public string Clave { get; init; } = "";

    [Required, MaxLength(12)]
    public string Codigo { get; init; } = "";

    [Required, MaxLength(80)]
    public string Nombres { get; init; } = "";

    [Required, MaxLength(80)]
    public string Apellidos { get; init; } = "";

    [MaxLength(80)]
    public string? Especialidad { get; init; }
}
