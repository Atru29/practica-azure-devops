using Microsoft.AspNetCore.Diagnostics;
using Microsoft.Data.SqlClient;

namespace Matriculas.Api.Comun;

/// <summary>
/// Convierte las excepciones en respuestas HTTP con el formato
/// ProblemDetails (RFC 7807), que es lo que espera cualquier cliente
/// moderno y lo que Angular puede leer sin inventarse nada.
/// </summary>
public sealed class ManejadorDeErrores(ILogger<ManejadorDeErrores> registro)
    : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext contexto, Exception excepcion, CancellationToken ct)
    {
        if (excepcion is SqlException sql)
        {
            var codigo = ErroresSql.ACodigoHttp(sql.Number);

            // Los mensajes de NUESTROS procedimientos son seguros de
            // mostrar: los escribimos para que el usuario los lea.
            // Los de SQL Server NO: filtran nombres de tablas, columnas
            // y restricciones, que es informacion util para un atacante.
            var mensaje = ErroresSql.EsErrorPropio(sql.Number)
                ? sql.Message
                : "Se produjo un error al procesar la solicitud.";

            if (!ErroresSql.EsErrorPropio(sql.Number))
                registro.LogError(sql, "Error SQL {Numero} en {Ruta}",
                                  sql.Number, contexto.Request.Path);

            await Responder(contexto, codigo, mensaje, sql.Number, ct);
            return true;
        }

        registro.LogError(excepcion, "Error no controlado en {Ruta}",
                          contexto.Request.Path);

        await Responder(contexto, StatusCodes.Status500InternalServerError,
                        "Se produjo un error al procesar la solicitud.", null, ct);
        return true;
    }

    private static async Task Responder(
        HttpContext contexto, int codigo, string mensaje, int? numeroSql,
        CancellationToken ct)
    {
        contexto.Response.StatusCode = codigo;

        await contexto.Response.WriteAsJsonAsync(new
        {
            status = codigo,
            title  = codigo switch
            {
                StatusCodes.Status400BadRequest => "Datos invalidos",
                StatusCodes.Status404NotFound   => "No encontrado",
                StatusCodes.Status409Conflict   => "Conflicto con el estado actual",
                _                               => "Error del servidor"
            },
            detail      = mensaje,
            codigoError = numeroSql,
            traceId     = contexto.TraceIdentifier
        }, ct);
    }
}
