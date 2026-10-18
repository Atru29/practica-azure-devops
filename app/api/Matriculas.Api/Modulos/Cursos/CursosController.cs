using System.Security.Claims;
using Matriculas.Api.Modulos.Cursos.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Cursos;

[ApiController]
[Route("api/cursos")]
[Authorize]
public sealed class CursosController(CursoServicio servicio) : ControllerBase
{
    // Abierto a cualquiera autenticado: el alumno necesita el catalogo
    // para elegir en que se matricula.
    [HttpGet]
    public async Task<IActionResult> Listar(
        [FromQuery] byte? ciclo = null,
        [FromQuery] int? docenteId = null)
        // El alumno sale del token, no de la consulta: asi nadie puede
        // preguntar "que tiene bloqueado fulano".
        => Ok(await servicio.ListarAsync(ciclo, docenteId, AlumnoIdDelToken()));

    [HttpPost]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Crear([FromBody] CrearCursoDto dto)
        => Ok(await servicio.CrearAsync(dto));

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Actualizar(int id, [FromBody] ActualizarCursoDto dto)
    {
        await servicio.ActualizarAsync(id, dto);
        return NoContent();
    }

    private int? AlumnoIdDelToken() =>
        int.TryParse(User.FindFirstValue("alumnoId"), out var id) ? id : null;
}
