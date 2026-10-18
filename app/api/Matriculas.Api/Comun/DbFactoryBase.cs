using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Matriculas.Api.Comun;

/// <summary>
/// La unica clase que conoce Dapper. Los repositorios heredan de ella
/// y no saben que existe ADO.NET, ni CommandType, ni cadenas de conexion.
/// </summary>
public abstract class DbFactoryBase
{
    private readonly string _cadena;

    protected DbFactoryBase(IConfiguration configuracion)
    {
        _cadena = configuracion.GetConnectionString("Matriculas")
            ?? throw new InvalidOperationException(
                "Falta la cadena de conexion 'Matriculas'. " +
                "En local: dotnet user-secrets set \"ConnectionStrings:Matriculas\" \"...\"");
    }

    /// <summary>
    /// Cada llamada abre su propia conexion y la cierra al terminar.
    /// No se comparte ni se guarda: ADO.NET ya mantiene por dentro un
    /// grupo de conexiones reutilizables. Guardarla seria reinventarlo mal.
    /// </summary>
    private SqlConnection Conexion() => new(_cadena);

    protected async Task<IEnumerable<T>> ConsultarAsync<T>(
        string procedimiento, object? parametros = null)
    {
        await using var con = Conexion();
        return await con.QueryAsync<T>(
            procedimiento, parametros, commandType: CommandType.StoredProcedure);
    }

    protected async Task<T?> ConsultarUnoAsync<T>(
        string procedimiento, object? parametros = null)
    {
        await using var con = Conexion();
        return await con.QueryFirstOrDefaultAsync<T>(
            procedimiento, parametros, commandType: CommandType.StoredProcedure);
    }

    protected async Task EjecutarAsync(
        string procedimiento, object? parametros = null)
    {
        await using var con = Conexion();
        await con.ExecuteAsync(
            procedimiento, parametros, commandType: CommandType.StoredProcedure);
    }

    /// <summary>
    /// Para los procedimientos que devuelven VARIOS conjuntos de resultados,
    /// como usp_Matricula_Obtener (cabecera + cursos).
    /// La conexion NO se puede cerrar antes de leerlos, de ahi que el
    /// lector se pase a una funcion en lugar de devolverlo.
    /// </summary>
    protected async Task<T> ConsultarMultipleAsync<T>(
        string procedimiento,
        object? parametros,
        Func<SqlMapper.GridReader, Task<T>> leer)
    {
        await using var con = Conexion();
        using var lector = await con.QueryMultipleAsync(
            procedimiento, parametros, commandType: CommandType.StoredProcedure);
        return await leer(lector);
    }
}
