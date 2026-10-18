using Matriculas.Api.Modulos.Periodos.Dtos;
using Matriculas.Api.Modulos.Periodos.Modelos;

namespace Matriculas.Api.Modulos.Periodos;

public sealed class PeriodoServicio(PeriodoRepositorio repositorio)
{
    public Task<IEnumerable<Periodo>> ListarAsync()  => repositorio.ListarAsync();
    public Task<Periodo?>             AbiertoAsync() => repositorio.AbiertoAsync();

    public Task<PeriodoCreado?> CrearAsync(CrearPeriodoDto dto) =>
        repositorio.CrearAsync(dto.Nombre.Trim().ToUpperInvariant(),
                               dto.FechaInicio, dto.FechaFin);

    public Task CerrarAsync(int id) => repositorio.CerrarAsync(id);
}
