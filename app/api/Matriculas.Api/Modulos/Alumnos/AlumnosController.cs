using Matriculas.Api.Modulos.Alumnos.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Matriculas.Api.Modulos.Alumnos;

/// <summary>
/// Solo HTTP: leer la peticion, elegir el codigo de estado, devolver.
/// Ninguna regla de negocio y ninguna llamada a la base.
/// </summary>
[ApiController]
[Route("api/alumnos")]
[Authorize]                        // por defecto: hay que estar autenticado
public sealed class AlumnosController(AlumnoServicio servicio) : ControllerBase
{
    // Consultar el padron lo pueden hacer gestores y docentes.
    // Un alumno no tiene por que ver la lista de sus companeros.
    [HttpGet]
    [Authorize(Roles = "Gestor,Docente")]
    public async Task<IActionResult> Listar(
        [FromQuery] string? busqueda = null,
        [FromQuery] bool soloActivos = true)
        => Ok(await servicio.ListarAsync(busqueda, soloActivos));

    [HttpGet("{id:int}")]
    [Authorize(Roles = "Gestor,Docente")]
    public async Task<IActionResult> Obtener(int id)
    {
        var alumno = await servicio.ObtenerAsync(id);
        return alumno is null ? NotFound() : Ok(alumno);
    }

    // Dar de alta, modificar y desactivar es cosa del gestor.
    [HttpPost]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Crear([FromBody] CrearAlumnoDto dto)
    {
        var creado = await servicio.CrearAsync(dto);

        // 201 con la cabecera Location apuntando al recurso nuevo.
        return CreatedAtAction(nameof(Obtener), new { id = creado!.AlumnoId }, creado);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Actualizar(int id, [FromBody] ActualizarAlumnoDto dto)
    {
        await servicio.ActualizarAsync(id, dto);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Gestor")]
    public async Task<IActionResult> Desactivar(int id)
    {
        await servicio.DesactivarAsync(id);
        return NoContent();
    }
}
