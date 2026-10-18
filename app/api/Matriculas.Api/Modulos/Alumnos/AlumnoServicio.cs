using Matriculas.Api.Modulos.Alumnos.Dtos;
using Matriculas.Api.Modulos.Alumnos.Modelos;

namespace Matriculas.Api.Modulos.Alumnos;

/// <summary>
/// Las reglas que no son ni validacion de formato ni invariantes de la
/// base. Aqui tambien se cifra la contrasena: la base NUNCA debe verla
/// en claro, ni siquiera de paso.
/// </summary>
public sealed class AlumnoServicio(AlumnoRepositorio repositorio)
{
    public Task<IEnumerable<Alumno>> ListarAsync(string? busqueda, bool soloActivos = true) =>
        repositorio.ListarAsync(busqueda, soloActivos);

    public Task<Alumno?> ObtenerAsync(int id) =>
        repositorio.ObtenerAsync(id);

    public async Task<AlumnoCreado?> CrearAsync(CrearAlumnoDto dto)
    {
        // El cifrado ocurre AQUI, antes de cruzar hacia la base.
        // BCrypt genera su propia sal y la guarda dentro del hash, por
        // eso no hace falta una columna aparte para ella.
        var cifrada = BCrypt.Net.BCrypt.HashPassword(dto.Clave);

        return await repositorio.CrearAsync(
            dto.Email.Trim().ToLowerInvariant(),   // el correo no distingue mayusculas
            cifrada,
            dto.Codigo.Trim().ToUpperInvariant(),
            dto.Nombres.Trim(),
            dto.Apellidos.Trim(),
            dto.Dni.Trim());
    }

    public Task ActualizarAsync(int id, ActualizarAlumnoDto dto) =>
        repositorio.ActualizarAsync(id, dto.Nombres.Trim(), dto.Apellidos.Trim(), dto.Dni.Trim());

    public Task DesactivarAsync(int id) =>
        repositorio.DesactivarAsync(id);
}
