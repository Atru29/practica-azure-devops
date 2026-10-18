using System.Security.Claims;
using Matriculas.Api.Modulos.Matriculas.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Matriculas;

[ApiController]
[Route("api/matriculas")]
[Authorize]
public sealed class MatriculasController(MatriculaServicio servicio) : ControllerBase
{
    // -----------------------------------------------------------------
    //  El alumno
    // -----------------------------------------------------------------

    /// <summary>
    /// El alumno solicita su matricula. El alumnoId sale del TOKEN,
    /// nunca del cuerpo: asi nadie puede matricular a otro.
    /// </summary>
    [HttpPost("solicitar")]
    [Authorize(Roles = "Alumno")]
    public async Task<IActionResult> Solicitar([FromBody] SolicitarMatriculaDto dto)
    {
        var alumnoId = AlumnoIdDelToken();
        if (alumnoId is null) return Forbid();

        var resultado = await servicio.SolicitarAsync(alumnoId.Value, dto);
        return CreatedAtAction(nameof(Obtener),
            new { id = resultado!.MatriculaId }, resultado);
    }

    /// <summary>Lo que el alumno ve de si mismo.</summary>
    [HttpGet("mias")]
    [Authorize(Roles = "Alumno")]
    public async Task<IActionResult> Mias()
    {
        var alumnoId = AlumnoIdDelToken();
        if (alumnoId is null) return Forbid();

        return Ok(await servicio.MiasAsync(alumnoId.Value));
    }

    // -----------------------------------------------------------------
    //  El gestor
    // -----------------------------------------------------------------

    [HttpGet("pendientes")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Pendientes([FromQuery] int? periodoId = null)
        => Ok(await servicio.ListarPendientesAsync(periodoId));

    [HttpPost("{id:int}/aprobar")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Aprobar(int id)
        => Ok(await servicio.AprobarAsync(id, UsuarioIdDelToken()));

    [HttpPost("{id:int}/rechazar")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Rechazar(int id, [FromBody] RechazarMatriculaDto dto)
        => Ok(await servicio.RechazarAsync(id, UsuarioIdDelToken(), dto));

    /// <summary>El gestor matricula a alguien y queda aprobada de una vez.</summary>
    [HttpPost]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> CrearAprobada([FromBody] CrearMatriculaAprobadaDto dto)
    {
        var resultado = await servicio.CrearAprobadaAsync(UsuarioIdDelToken(), dto);
        return CreatedAtAction(nameof(Obtener),
            new { id = resultado!.MatriculaId }, resultado);
    }

    // -----------------------------------------------------------------
    //  Comun
    // -----------------------------------------------------------------

    /// <summary>
    /// El detalle. Un alumno solo puede ver la suya; gestores y docentes,
    /// cualquiera. La comprobacion esta en el servicio, no aqui.
    /// </summary>
    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obtener(int id)
    {
        var rol = User.FindFirstValue(ClaimTypes.Role) ?? "";
        var (detalle, autorizado) = await servicio.ObtenerAsync(id, rol, AlumnoIdDelToken());

        if (detalle is null) return NotFound();
        if (!autorizado)     return Forbid();

        return Ok(detalle);
    }

    // -----------------------------------------------------------------

    private int UsuarioIdDelToken() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private int? AlumnoIdDelToken() =>
        int.TryParse(User.FindFirstValue("alumnoId"), out var id) ? id : null;
}
