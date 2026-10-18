namespace Matriculas.Api.Comun;

/// <summary>
/// Traduce los codigos de error de los procedimientos a codigos HTTP.
/// El contrato esta definido en app/sql/04-procedimientos.sql.
/// </summary>
public static class ErroresSql
{
    /// <summary>A partir de 50000 son errores que escribimos nosotros.</summary>
    public const int PrimerErrorPropio = 50000;

    public static bool EsErrorPropio(int numero) => numero >= PrimerErrorPropio;

    public static int ACodigoHttp(int numero) => numero switch
    {
        >= 50001 and <= 50009 => StatusCodes.Status400BadRequest,   // datos invalidos
        >= 50010 and <= 50019 => StatusCodes.Status409Conflict,     // estado incorrecto
        >= 50020 and <= 50029 => StatusCodes.Status404NotFound,     // no encontrado
        _                     => StatusCodes.Status500InternalServerError
    };
}
