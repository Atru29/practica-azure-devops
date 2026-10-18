using System.Security.Claims;
using Matriculas.Api.Modulos.Identidad.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Identidad;

[ApiController]
[Route("api/autenticacion")]
public sealed class AutenticacionController(AutenticacionServicio servicio) : ControllerBase
{
    [HttpPost("entrar")]
    [AllowAnonymous]
    public async Task<IActionResult> Entrar([FromBody] EntrarDto dto)
    {
        var sesion = await servicio.EntrarAsync(dto);

        return sesion is null
            ? Unauthorized(new { detail = "Correo o contrasena incorrectos." })
            : Ok(sesion);
    }

    /// <summary>
    /// Devuelve quien eres segun el token. Util para que Angular
    /// compruebe al arrancar si la sesion sigue viva.
    /// </summary>
    [HttpGet("yo")]
    [Authorize]
    public IActionResult Yo() => Ok(new
    {
        usuarioId = User.FindFirstValue(ClaimTypes.NameIdentifier),
        email     = User.FindFirstValue(ClaimTypes.Email),
        rol       = User.FindFirstValue(ClaimTypes.Role),
        alumnoId  = User.FindFirstValue("alumnoId"),
        docenteId = User.FindFirstValue("docenteId")
    });
}
