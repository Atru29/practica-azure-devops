namespace Matriculas.Api.Modulos.Periodos.Modelos;

public sealed class Periodo
{
    public int      Id          { get; init; }
    public string   Nombre      { get; init; } = "";
    public DateOnly FechaInicio { get; init; }
    public DateOnly FechaFin    { get; init; }
    public string   Estado      { get; init; } = "";
    public int      Matriculas  { get; init; }   // solo lo devuelve Listar
}

public sealed class PeriodoCreado
{
    public int PeriodoId { get; init; }
}
