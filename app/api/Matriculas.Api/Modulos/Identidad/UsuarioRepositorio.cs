using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Identidad.Modelos;

namespace Matriculas.Api.Modulos.Identidad;

public sealed class UsuarioRepositorio(IConfiguration configuracion)
    : DbFactoryBase(configuracion)
{
    public Task<UsuarioAutenticacion?> PorCorreoAsync(string email) =>
        ConsultarUnoAsync<UsuarioAutenticacion>(
            Procedimientos.Usuario.PorCorreo, new { v_email = email });
}
