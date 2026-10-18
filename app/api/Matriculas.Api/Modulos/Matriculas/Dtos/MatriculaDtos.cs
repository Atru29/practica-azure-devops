using System.ComponentModel.DataAnnotations;

namespace Matriculas.Api.Modulos.Matriculas.Dtos;

/// <summary>
/// Lo que manda el alumno. NO lleva alumnoId: ese sale del token.
/// Si viniera en el cuerpo, cualquiera podria matricular a otro
/// cambiando un numero.
/// </summary>
public sealed class SolicitarMatriculaDto
{
    [Required]
    public int PeriodoId { get; init; }

    [Required, MinLength(1, ErrorMessage = "Hay que elegir al menos un curso.")]
    public int[] Cursos { get; init; } = [];
}

/// <summary>El gestor matricula a alguien directamente: aqui si lleva alumnoId.</summary>
public sealed class CrearMatriculaAprobadaDto
{
    [Required] public int   AlumnoId  { get; init; }
    [Required] public int   PeriodoId { get; init; }
    [Required, MinLength(1)] public int[] Cursos { get; init; } = [];
}

public sealed class RechazarMatriculaDto
{
    [Required(ErrorMessage = "Hay que indicar el motivo del rechazo.")]
    [MaxLength(400)]
    public string Observacion { get; init; } = "";
}
