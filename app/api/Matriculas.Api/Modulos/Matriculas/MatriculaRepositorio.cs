using Dapper;
using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Matriculas.Modelos;

namespace Matriculas.Api.Modulos.Matriculas;

public sealed class MatriculaRepositorio(IConfiguration configuracion)
    : DbFactoryBase(configuracion)
{
    public Task<MatriculaResultado?> SolicitarAsync(int alumnoId, int periodoId, string cursos) =>
        ConsultarUnoAsync<MatriculaResultado>(Procedimientos.Matricula.Solicitar,
            new { i_alumnoId = alumnoId, i_periodoId = periodoId, v_cursos = cursos });

    public Task<MatriculaResultado?> CrearAprobadaAsync(
        int alumnoId, int periodoId, string cursos, int gestorId) =>
        ConsultarUnoAsync<MatriculaResultado>(Procedimientos.Matricula.CrearAprobada,
            new { i_alumnoId = alumnoId, i_periodoId = periodoId,
                  v_cursos = cursos, i_gestorId = gestorId });

    public Task<MatriculaResultado?> AprobarAsync(int matriculaId, int gestorId) =>
        ConsultarUnoAsync<MatriculaResultado>(Procedimientos.Matricula.Aprobar,
            new { i_matriculaId = matriculaId, i_gestorId = gestorId });

    public Task<MatriculaResultado?> RechazarAsync(int matriculaId, int gestorId, string observacion) =>
        ConsultarUnoAsync<MatriculaResultado>(Procedimientos.Matricula.Rechazar,
            new { i_matriculaId = matriculaId, i_gestorId = gestorId,
                  v_observacion = observacion });

    public Task<IEnumerable<MatriculaPendiente>> ListarPendientesAsync(int? periodoId) =>
        ConsultarAsync<MatriculaPendiente>(Procedimientos.Matricula.ListarPendientes,
            new { i_periodoId = periodoId });

    public Task<IEnumerable<MatriculaDeAlumno>> PorAlumnoAsync(int alumnoId) =>
        ConsultarAsync<MatriculaDeAlumno>(Procedimientos.Matricula.PorAlumno,
            new { i_alumnoId = alumnoId });

    /// <summary>
    /// usp_Matricula_Obtener devuelve DOS conjuntos: cabecera y cursos.
    /// Se leen en orden; si se invierte, Dapper devuelve basura.
    /// </summary>
    public Task<MatriculaDetalle?> ObtenerAsync(int matriculaId) =>
        ConsultarMultipleAsync<MatriculaDetalle?>(
            Procedimientos.Matricula.Obtener,
            new { i_matriculaId = matriculaId },
            async lector =>
            {
                var cabecera = await lector.ReadFirstOrDefaultAsync<MatriculaCabecera>();
                if (cabecera is null) return null;

                var cursos = await lector.ReadAsync<MatriculaCurso>();
                return new MatriculaDetalle { Cabecera = cabecera, Cursos = cursos };
            });

    public Task GuardarConstanciaAsync(int matriculaId, string ruta) =>
        EjecutarAsync(Procedimientos.Matricula.GuardarConstancia,
            new { i_matriculaId = matriculaId, v_ruta = ruta });
}
