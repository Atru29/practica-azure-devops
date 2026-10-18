using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Periodos.Modelos;

namespace Matriculas.Api.Modulos.Periodos;

public sealed class PeriodoRepositorio(IConfiguration configuracion)
    : DbFactoryBase(configuracion)
{
    public Task<IEnumerable<Periodo>> ListarAsync() =>
        ConsultarAsync<Periodo>(Procedimientos.Periodo.Listar);

    public Task<Periodo?> AbiertoAsync() =>
        ConsultarUnoAsync<Periodo>(Procedimientos.Periodo.Abierto);

    public Task<PeriodoCreado?> CrearAsync(string nombre, DateOnly inicio, DateOnly fin) =>
        ConsultarUnoAsync<PeriodoCreado>(Procedimientos.Periodo.Crear,
            new { v_nombre = nombre, d_fechaInicio = inicio, d_fechaFin = fin });

    public Task CerrarAsync(int id) =>
        EjecutarAsync(Procedimientos.Periodo.Cerrar, new { i_id = id });
}
