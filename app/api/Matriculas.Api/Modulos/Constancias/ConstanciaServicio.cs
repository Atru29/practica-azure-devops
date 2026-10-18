using Matriculas.Api.Modulos.Matriculas;
using Matriculas.Api.Modulos.Matriculas.Modelos;

namespace Matriculas.Api.Modulos.Constancias;

public enum ResultadoConstancia
{
    Entregada,
    NoExiste,
    NoAutorizado,
    NoAprobada
}

public sealed class ConstanciaServicio(
    MatriculaRepositorio repositorio,
    AlmacenDeArchivos    almacen,
    ILogger<ConstanciaServicio> registro)
{
    /// <summary>
    /// Devuelve el PDF de la constancia.
    ///
    /// Se genera la primera vez que alguien la pide y se guarda en el
    /// almacen; a partir de ahi se entrega el archivo ya existente. Asi
    /// la constancia de un alumno que nunca la descarga no ocupa nada,
    /// y la de quien la pide diez veces se genera una sola.
    /// </summary>
    public async Task<(ResultadoConstancia estado, Stream? archivo, string? nombre)> ObtenerAsync(
        int matriculaId, string rol, int? alumnoIdDelToken, CancellationToken ct = default)
    {
        var detalle = await repositorio.ObtenerAsync(matriculaId);
        if (detalle is null) return (ResultadoConstancia.NoExiste, null, null);

        var cabecera = detalle.Cabecera;

        // Un alumno solo puede bajarse la suya. El gestor, cualquiera.
        if (rol == "Alumno" && cabecera.AlumnoId != alumnoIdDelToken)
            return (ResultadoConstancia.NoAutorizado, null, null);

        if (cabecera.Estado != "Aprobada")
            return (ResultadoConstancia.NoAprobada, null, null);

        var nombreArchivo = $"constancia-{cabecera.AlumnoCodigo}-{cabecera.Periodo}.pdf";

        // ¿Ya estaba generada?
        if (!string.IsNullOrWhiteSpace(cabecera.ConstanciaRuta))
        {
            var guardado = await almacen.AbrirAsync(cabecera.ConstanciaRuta, ct);
            if (guardado is not null)
                return (ResultadoConstancia.Entregada, guardado, nombreArchivo);

            // La base dice que existe pero en el almacen no esta. Puede
            // pasar si alguien borro el contenedor. Se vuelve a generar
            // en vez de devolver un error que nadie sabria arreglar.
            registro.LogWarning(
                "La matricula {Id} apunta a {Ruta} pero el archivo no esta. Se regenera.",
                matriculaId, cabecera.ConstanciaRuta);
        }

        var pdf = ConstanciaPdf.Generar(cabecera, detalle.Cursos.ToList());

        // La ruta agrupa por periodo: con muchas constancias, listar las
        // de un periodo concreto es inmediato.
        var ruta = $"{cabecera.Periodo}/{cabecera.AlumnoCodigo}-{matriculaId}.pdf";

        await almacen.GuardarAsync(ruta, pdf, "application/pdf", ct);
        await repositorio.GuardarConstanciaAsync(matriculaId, ruta);

        return (ResultadoConstancia.Entregada, new MemoryStream(pdf), nombreArchivo);
    }
}
