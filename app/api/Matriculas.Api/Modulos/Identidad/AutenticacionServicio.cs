using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Matriculas.Api.Modulos.Identidad.Dtos;
using Microsoft.IdentityModel.Tokens;

namespace Matriculas.Api.Modulos.Identidad;

public sealed class AutenticacionServicio(
    UsuarioRepositorio repositorio,
    IConfiguration configuracion)
{
    public async Task<SesionDto?> EntrarAsync(EntrarDto dto)
    {
        var usuario = await repositorio.PorCorreoAsync(dto.Email.Trim().ToLowerInvariant());

        // Un solo mensaje para "no existe" y "clave incorrecta".
        // Si se distinguieran, cualquiera podria averiguar que correos
        // estan registrados probando uno a uno.
        if (usuario is null || !usuario.Activo)
            return null;

        if (!BCrypt.Net.BCrypt.Verify(dto.Clave, usuario.PasswordHash))
            return null;

        var expira = DateTime.UtcNow.AddHours(8);

        var afirmaciones = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, usuario.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(ClaimTypes.Role, usuario.Rol)
        };

        // El identificador de alumno o docente viaja dentro del token:
        // asi un alumno no puede pedir las matriculas de otro cambiando
        // un numero en la URL, porque el servidor usa el del token.
        if (usuario.AlumnoId  is int a) afirmaciones.Add(new Claim("alumnoId",  a.ToString()));
        if (usuario.DocenteId is int d) afirmaciones.Add(new Claim("docenteId", d.ToString()));

        var clave = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(LeerClaveDeFirma()));

        var token = new JwtSecurityToken(
            issuer:             configuracion["Jwt:Emisor"],
            audience:           configuracion["Jwt:Audiencia"],
            claims:             afirmaciones,
            expires:            expira,
            signingCredentials: new SigningCredentials(clave, SecurityAlgorithms.HmacSha256));

        return new SesionDto
        {
            Token     = new JwtSecurityTokenHandler().WriteToken(token),
            Expira    = expira,
            UsuarioId = usuario.Id,
            Email     = usuario.Email,
            Rol       = usuario.Rol,
            Nombre    = $"{usuario.Nombres} {usuario.Apellidos}".Trim(),
            AlumnoId  = usuario.AlumnoId,
            DocenteId = usuario.DocenteId
        };
    }

    private string LeerClaveDeFirma() =>
        configuracion["Jwt:Clave"]
        ?? throw new InvalidOperationException(
            "Falta Jwt:Clave. En local: dotnet user-secrets set \"Jwt:Clave\" \"...\"");
}
