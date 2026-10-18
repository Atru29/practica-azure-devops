using System.ComponentModel.DataAnnotations;

namespace Matriculas.Api.Modulos.Cursos.Dtos;

public sealed class CrearCursoDto
{
    [Required]                       public int    DocenteId { get; init; }
    [Required, MaxLength(12)]        public string Codigo    { get; init; } = "";
    [Required, MaxLength(120)]       public string Nombre    { get; init; } = "";
    [Range(1, 10)]                   public byte   Creditos  { get; init; }
    [Range(1, 10)]                   public byte   Ciclo     { get; init; }
}

public sealed class ActualizarCursoDto
{
    [Required]                       public int    DocenteId { get; init; }
    [Required, MaxLength(120)]       public string Nombre    { get; init; } = "";
    [Range(1, 10)]                   public byte   Creditos  { get; init; }
    [Range(1, 10)]                   public byte   Ciclo     { get; init; }
}
