using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Alumnos.Modelos;

namespace Matriculas.Api.Modulos.Alumnos;

/// <summary>
/// Una llamada por procedimiento. Nada mas.
/// Si aqui aparece un "if" que decide algo del negocio, esta en la
/// capa equivocada: eso va en el servicio.
/// </summary>
public sealed class AlumnoRepositorio(IConfiguration configuracion)
    : DbFactoryBase(configuracion)
{
    public Task<IEnumerable<Alumno>> ListarAsync(string? busqueda, bool soloActivos) =>
        ConsultarAsync<Alumno>(Procedimientos.Alumno.Listar,
            new { v_busqueda = busqueda, b_soloActivos = soloActivos });

    public Task<Alumno?> ObtenerAsync(int id) =>
        ConsultarUnoAsync<Alumno>(Procedimientos.Alumno.Obtener,
            new { i_id = id });

    public Task<AlumnoCreado?> CrearAsync(
        string email, string claveCifrada, string codigo,
        string nombres, string apellidos, string dni) =>
        ConsultarUnoAsync<AlumnoCreado>(Procedimientos.Alumno.Crear,
            new
            {
                v_email     = email,
                v_clave     = claveCifrada,
                v_codigo    = codigo,
                v_nombres   = nombres,
                v_apellidos = apellidos,
                v_dni       = dni
            });

    public Task ActualizarAsync(int id, string nombres, string apellidos, string dni) =>
        EjecutarAsync(Procedimientos.Alumno.Actualizar,
            new { i_id = id, v_nombres = nombres, v_apellidos = apellidos, v_dni = dni });

    public Task DesactivarAsync(int id) =>
        EjecutarAsync(Procedimientos.Alumno.Desactivar, new { i_id = id });
}
