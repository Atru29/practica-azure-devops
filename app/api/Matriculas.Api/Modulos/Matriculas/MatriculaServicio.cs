using Matriculas.Api.Modulos.Matriculas.Dtos;
using Matriculas.Api.Modulos.Matriculas.Modelos;

namespace Matriculas.Api.Modulos.Matriculas;

/// <summary>
/// Reglas que no puede comprobar la base porque dependen de QUIEN pide.
/// Las de estado y las de integridad ya viven en el procedimiento y en
/// el esquema; aqui solo esta la autorizacion sobre datos concretos.
/// </summary>
public sealed class MatriculaServicio(MatriculaRepositorio repositorio)
{
    public Task<MatriculaResultado?> SolicitarAsync(int alumnoId, SolicitarMatriculaDto dto) =>
        repositorio.SolicitarAsync(alumnoId, dto.PeriodoId, AListaCsv(dto.Cursos));

    public Task<MatriculaResultado?> CrearAprobadaAsync(
        int gestorId, CrearMatriculaAprobadaDto dto) =>
        repositorio.CrearAprobadaAsync(dto.AlumnoId, dto.PeriodoId,
                                       AListaCsv(dto.Cursos), gestorId);

    public Task<MatriculaResultado?> AprobarAsync(int matriculaId, int gestorId) =>
        repositorio.AprobarAsync(matriculaId, gestorId);

    public Task<MatriculaResultado?> RechazarAsync(
        int matriculaId, int gestorId, RechazarMatriculaDto dto) =>
        repositorio.RechazarAsync(matriculaId, gestorId, dto.Observacion.Trim());

    public Task<IEnumerable<MatriculaPendiente>> ListarPendientesAsync(int? periodoId) =>
        repositorio.ListarPendientesAsync(periodoId);

    public Task<IEnumerable<MatriculaDeAlumno>> MiasAsync(int alumnoId) =>
        repositorio.PorAlumnoAsync(alumnoId);

    /// <summary>
    /// Un alumno solo puede ver SU matricula. Gestores y docentes, todas.
    /// Devuelve null si no existe y false en 'autorizado' si existe pero
    /// no es suya: son dos respuestas HTTP distintas (404 y 403).
    /// </summary>
    public async Task<(MatriculaDetalle? detalle, bool autorizado)> ObtenerAsync(
        int matriculaId, string rol, int? alumnoIdDelToken)
    {
        var detalle = await repositorio.ObtenerAsync(matriculaId);
        if (detalle is null) return (null, true);

        var autorizado = rol != "Alumno" || detalle.Cabecera.AlumnoId == alumnoIdDelToken;
        return (detalle, autorizado);
    }

    /// <summary>
    /// Los procedimientos reciben los cursos como '1,3,7'. Convertir aqui
    /// y no en el controlador mantiene el formato de la base en una sola
    /// capa: si manana se cambia a un parametro con valores de tabla,
    /// solo se toca esto.
    /// </summary>
    private static string AListaCsv(int[] cursos) => string.Join(',', cursos.Distinct());
}
