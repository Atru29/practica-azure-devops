using System.ComponentModel.DataAnnotations;

namespace Matriculas.Api.Modulos.Alumnos.Dtos;

/// <summary>
/// Lo que ENTRA por HTTP. Separado del modelo a proposito: el cliente
/// manda la contrasena en claro, y el modelo nunca debe tenerla.
///
/// Las validaciones de aqui son de FORMATO. Las reglas de negocio
/// -codigo repetido, DNI duplicado- viven en el procedimiento.
/// </summary>
public sealed class CrearAlumnoDto
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

    [Required, StringLength(12, MinimumLength = 8)]
    public string Dni { get; init; } = "";
}

public sealed class ActualizarAlumnoDto
{
    [Required, MaxLength(80)]
    public string Nombres { get; init; } = "";

    [Required, MaxLength(80)]
    public string Apellidos { get; init; } = "";

    [Required, StringLength(12, MinimumLength = 8)]
    public string Dni { get; init; } = "";
}
