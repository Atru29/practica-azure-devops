using Matriculas.Api.Modulos.Cursos.Dtos;
using Matriculas.Api.Modulos.Cursos.Modelos;

namespace Matriculas.Api.Modulos.Cursos;

public sealed class CursoServicio(CursoRepositorio repositorio)
{
    public Task<IEnumerable<Curso>> ListarAsync(
        byte? ciclo = null, int? docenteId = null, int? alumnoId = null) =>
        repositorio.ListarAsync(ciclo, docenteId, alumnoId);

    public Task<CursoCreado?> CrearAsync(CrearCursoDto dto) =>
        repositorio.CrearAsync(dto.DocenteId, dto.Codigo.Trim().ToUpperInvariant(),
                               dto.Nombre.Trim(), dto.Creditos, dto.Ciclo);

    public Task ActualizarAsync(int id, ActualizarCursoDto dto) =>
        repositorio.ActualizarAsync(id, dto.DocenteId, dto.Nombre.Trim(),
                                    dto.Creditos, dto.Ciclo);
}
