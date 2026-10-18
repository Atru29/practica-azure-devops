using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Cursos.Modelos;

namespace Matriculas.Api.Modulos.Cursos;

public sealed class CursoRepositorio(IConfiguration configuracion)
    : DbFactoryBase(configuracion)
{
    public Task<IEnumerable<Curso>> ListarAsync(byte? ciclo, int? docenteId, int? alumnoId) =>
        ConsultarAsync<Curso>(Procedimientos.Curso.Listar,
            new { i_ciclo = ciclo, i_docenteId = docenteId, i_alumnoId = alumnoId });

    public Task<CursoCreado?> CrearAsync(
        int docenteId, string codigo, string nombre, byte creditos, byte ciclo) =>
        ConsultarUnoAsync<CursoCreado>(Procedimientos.Curso.Crear,
            new
            {
                i_docenteId = docenteId,
                v_codigo    = codigo,
                v_nombre    = nombre,
                i_creditos  = creditos,
                i_ciclo     = ciclo
            });

    public Task ActualizarAsync(
        int id, int docenteId, string nombre, byte creditos, byte ciclo) =>
        EjecutarAsync(Procedimientos.Curso.Actualizar,
            new
            {
                i_id        = id,
                i_docenteId = docenteId,
                v_nombre    = nombre,
                i_creditos  = creditos,
                i_ciclo     = ciclo
            });
}
