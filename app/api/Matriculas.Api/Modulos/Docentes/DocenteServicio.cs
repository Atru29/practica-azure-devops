using Matriculas.Api.Modulos.Docentes.Dtos;
using Matriculas.Api.Modulos.Docentes.Modelos;

namespace Matriculas.Api.Modulos.Docentes;

public sealed class DocenteServicio(DocenteRepositorio repositorio)
{
    public Task<IEnumerable<Docente>> ListarAsync(bool soloActivos = true) =>
        repositorio.ListarAsync(soloActivos);

    public Task<Docente?> ObtenerAsync(int id) => repositorio.ObtenerAsync(id);

    public Task<DocenteCreado?> CrearAsync(CrearDocenteDto dto) =>
        repositorio.CrearAsync(
            dto.Email.Trim().ToLowerInvariant(),
            BCrypt.Net.BCrypt.HashPassword(dto.Clave),
            dto.Codigo.Trim().ToUpperInvariant(),
            dto.Nombres.Trim(),
            dto.Apellidos.Trim(),
            dto.Especialidad?.Trim());

    public Task DesactivarAsync(int id) => repositorio.DesactivarAsync(id);
}
