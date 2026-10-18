using Matriculas.Api.Modulos.Docentes.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Docentes;

[ApiController]
[Route("api/docentes")]
[Authorize]
public sealed class DocentesController(DocenteServicio servicio) : ControllerBase
{
    // Cualquiera autenticado puede ver quien dicta que: el alumno lo
    // necesita para elegir cursos.
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] bool soloActivos = true)
        => Ok(await servicio.ListarAsync(soloActivos));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obtener(int id)
    {
        var docente = await servicio.ObtenerAsync(id);
        return docente is null ? NotFound() : Ok(docente);
    }

    [HttpPost]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Crear([FromBody] CrearDocenteDto dto)
    {
        var creado = await servicio.CrearAsync(dto);
        return CreatedAtAction(nameof(Obtener), new { id = creado!.DocenteId }, creado);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Desactivar(int id)
    {
        await servicio.DesactivarAsync(id);
        return NoContent();
    }
}
