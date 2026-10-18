using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Constancias;

[ApiController]
[Route("api/matriculas/{matriculaId:int}/constancia")]
[Authorize]
public sealed class ConstanciasController(ConstanciaServicio servicio) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Descargar(int matriculaId, CancellationToken ct)
    {
        var rol = User.FindFirstValue(ClaimTypes.Role) ?? "";

        var (estado, archivo, nombre) =
            await servicio.ObtenerAsync(matriculaId, rol, AlumnoIdDelToken(), ct);

        return estado switch
        {
            ResultadoConstancia.NoExiste     => NotFound(),
            ResultadoConstancia.NoAutorizado => Forbid(),
            ResultadoConstancia.NoAprobada   => Conflict(new ProblemDetails
            {
                Status = StatusCodes.Status409Conflict,
                Title  = "Conflicto con el estado actual",
                Detail = "Solo una matricula aprobada tiene constancia."
            }),
            _ => File(archivo!, "application/pdf", nombre)
        };
    }

    private int? AlumnoIdDelToken() =>
        int.TryParse(User.FindFirstValue("alumnoId"), out var id) ? id : null;
}
