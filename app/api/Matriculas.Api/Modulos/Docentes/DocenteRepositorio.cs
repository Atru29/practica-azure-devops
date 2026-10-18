using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Docentes.Modelos;

namespace Matriculas.Api.Modulos.Docentes;

public sealed class DocenteRepositorio(IConfiguration configuracion)
    : DbFactoryBase(configuracion)
{
    public Task<IEnumerable<Docente>> ListarAsync(bool soloActivos) =>
        ConsultarAsync<Docente>(Procedimientos.Docente.Listar,
            new { b_soloActivos = soloActivos });

    public Task<Docente?> ObtenerAsync(int id) =>
        ConsultarUnoAsync<Docente>(Procedimientos.Docente.Obtener, new { i_id = id });

    public Task<DocenteCreado?> CrearAsync(
        string email, string claveCifrada, string codigo,
        string nombres, string apellidos, string? especialidad) =>
        ConsultarUnoAsync<DocenteCreado>(Procedimientos.Docente.Crear,
            new
            {
                v_email        = email,
                v_clave        = claveCifrada,
                v_codigo       = codigo,
                v_nombres      = nombres,
                v_apellidos    = apellidos,
                v_especialidad = especialidad
            });

    public Task DesactivarAsync(int id) =>
        EjecutarAsync(Procedimientos.Docente.Desactivar, new { i_id = id });
}
