using Matriculas.Api.Modulos.Periodos.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Periodos;

[ApiController]
[Route("api/periodos")]
[Authorize]
public sealed class PeriodosController(PeriodoServicio servicio) : ControllerBase
{
    [HttpGet]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Listar() => Ok(await servicio.ListarAsync());

    /// <summary>El periodo en el que se puede matricular ahora mismo.</summary>
    [HttpGet("abierto")]
    public async Task<IActionResult> Abierto()
    {
        var periodo = await servicio.AbiertoAsync();
        return periodo is null ? NotFound() : Ok(periodo);
    }

    [HttpPost]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Crear([FromBody] CrearPeriodoDto dto)
        => Ok(await servicio.CrearAsync(dto));

    [HttpPost("{id:int}/cerrar")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Cerrar(int id)
    {
        await servicio.CerrarAsync(id);
        return NoContent();
    }
}
