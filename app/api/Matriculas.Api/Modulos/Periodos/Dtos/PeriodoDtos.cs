using System.ComponentModel.DataAnnotations;

namespace Matriculas.Api.Modulos.Periodos.Dtos;

public sealed class CrearPeriodoDto
{
    [Required, MaxLength(10)]
    public string   Nombre      { get; init; } = "";   // 2026-II

    [Required] public DateOnly FechaInicio { get; init; }
    [Required] public DateOnly FechaFin    { get; init; }
}
