using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace Matriculas.Api.Modulos.Constancias;

/// <summary>
/// Guarda y recupera archivos en Blob Storage.
///
/// En local apunta a Azurite, el emulador; en la maquina apuntara a una
/// cuenta de almacenamiento real. El codigo es el mismo: lo unico que
/// cambia es la cadena de conexion.
/// </summary>
public sealed class AlmacenDeArchivos
{
    private readonly BlobContainerClient contenedor;
    private bool contenedorListo;

    public AlmacenDeArchivos(IConfiguration configuracion)
    {
        var conexion = configuracion["Almacen:Conexion"]
            ?? throw new InvalidOperationException(
                "Falta Almacen:Conexion. En local la pone docker-compose.");

        var nombre = configuracion["Almacen:Contenedor"] ?? "constancias";

        contenedor = new BlobServiceClient(conexion).GetBlobContainerClient(nombre);
    }

    /// <summary>
    /// Sube el archivo y devuelve su ruta RELATIVA, que es lo que se
    /// guarda en la base: si manana cambia la cuenta o el dominio, no
    /// hay que tocar ninguna fila.
    /// </summary>
    public async Task<string> GuardarAsync(
        string ruta, byte[] contenido, string tipoMime, CancellationToken ct = default)
    {
        await AsegurarContenedorAsync(ct);

        var blob = contenedor.GetBlobClient(ruta);

        using var flujo = new MemoryStream(contenido, writable: false);

        await blob.UploadAsync(flujo, new BlobUploadOptions
        {
            HttpHeaders = new BlobHttpHeaders { ContentType = tipoMime }
        }, ct);

        return ruta;
    }

    public async Task<Stream?> AbrirAsync(string ruta, CancellationToken ct = default)
    {
        var blob = contenedor.GetBlobClient(ruta);

        if (!await blob.ExistsAsync(ct)) return null;

        var descarga = await blob.DownloadStreamingAsync(cancellationToken: ct);
        return descarga.Value.Content;
    }

    /// <summary>
    /// El contenedor se crea la primera vez que hace falta. Se recuerda
    /// con una bandera para no preguntar a Azure en cada subida.
    /// </summary>
    private async Task AsegurarContenedorAsync(CancellationToken ct)
    {
        if (contenedorListo) return;

        // Sin acceso publico: a los archivos solo se llega a traves de
        // la API, que comprueba antes quien los pide.
        await contenedor.CreateIfNotExistsAsync(PublicAccessType.None, cancellationToken: ct);
        contenedorListo = true;
    }
}
