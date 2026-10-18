using System.Text;
using Matriculas.Api.Comun;
using Matriculas.Api.Modulos.Constancias;
using Matriculas.Api.Modulos.Alumnos;
using Matriculas.Api.Modulos.Cursos;
using Matriculas.Api.Modulos.Docentes;
using Matriculas.Api.Modulos.Identidad;
using Matriculas.Api.Modulos.Matriculas;
using Matriculas.Api.Modulos.Periodos;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;

var builder = WebApplication.CreateBuilder(args);

// ---------------------------------------------------------------------
//  Servicios
// ---------------------------------------------------------------------
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// QuestPDF pide declarar la licencia antes del primer documento. La
// Community es gratuita para particulares y para empresas que facturan
// menos de un millon de dolares al ano.
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

builder.Services.AddExceptionHandler<ManejadorDeErrores>();
builder.Services.AddProblemDetails();

// 'version' es la etiqueta de la imagen (el hash del commit), que pone
// el compose de produccion. La devuelve /salud y etiqueta las metricas.
// Clave con seccion propia a proposito: la imagen de .NET define
// DOTNET_VERSION, y ASP.NET le quita el prefijo, asi que una clave
// "Version" a secas devolveria la version del runtime (10.0.x).
var version = builder.Configuration["Despliegue:Version"] ?? "local";

// --- Observabilidad: metricas con OpenTelemetry ---
// La API mide cada peticion que recibe, cada llamada que hace hacia
// fuera (Blob Storage) y cada consulta a SQL, y lo envia por OTLP al
// Collector, que se lo pasa a Prometheus. Solo se activa si hay a donde
// enviarlo: en local, sin Otel:Endpoint, no cambia nada.
var destinoOtel = builder.Configuration["Otel:Endpoint"];
if (!string.IsNullOrWhiteSpace(destinoOtel))
{
    builder.Services.AddOpenTelemetry()
        .ConfigureResource(r => r.AddService("matriculas-api", serviceVersion: version))
        .WithMetrics(m => m
            .AddAspNetCoreInstrumentation()   // peticiones recibidas: ruta, metodo, codigo, duracion
            .AddHttpClientInstrumentation()   // peticiones hechas: aqui, Blob Storage
            .AddSqlClientInstrumentation()    // consultas a Azure SQL
            .AddRuntimeInstrumentation()      // memoria, recolector de basura, hilos de .NET
            .AddOtlpExporter((exportador, lector) =>
            {
                exportador.Endpoint = new Uri(destinoOtel);
                // Cada 15 s, como el scrape de Prometheus (por defecto, 60).
                lector.PeriodicExportingMetricReaderOptions.ExportIntervalMilliseconds = 15_000;
            }));
}

// --- Autenticacion por token ---
var claveJwt = builder.Configuration["Jwt:Clave"]
    ?? throw new InvalidOperationException(
        "Falta Jwt:Clave. En local: dotnet user-secrets set \"Jwt:Clave\" \"...\"");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opciones =>
    {
        opciones.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = builder.Configuration["Jwt:Emisor"],
            ValidAudience            = builder.Configuration["Jwt:Audiencia"],
            IssuerSigningKey         = new SymmetricSecurityKey(
                                           Encoding.UTF8.GetBytes(claveJwt)),

            // Sin esto, un token caducado sigue valiendo hasta 5 minutos
            // mas por una tolerancia de reloj que viene puesta de serie.
            ClockSkew                = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// --- Modulos ---
builder.Services.AddScoped<UsuarioRepositorio>();
builder.Services.AddScoped<AutenticacionServicio>();
builder.Services.AddScoped<AlumnoRepositorio>();
builder.Services.AddScoped<AlumnoServicio>();
builder.Services.AddScoped<DocenteRepositorio>();
builder.Services.AddScoped<DocenteServicio>();
builder.Services.AddScoped<CursoRepositorio>();
builder.Services.AddScoped<CursoServicio>();
builder.Services.AddScoped<PeriodoRepositorio>();
builder.Services.AddScoped<PeriodoServicio>();
builder.Services.AddScoped<MatriculaRepositorio>();
builder.Services.AddScoped<MatriculaServicio>();

// El almacen abre conexiones HTTP reutilizables: una sola instancia
// para toda la aplicacion, no una por peticion.
builder.Services.AddSingleton<AlmacenDeArchivos>();
builder.Services.AddScoped<ConstanciaServicio>();

// --- CORS solo para desarrollo ---
// En produccion no hace falta: nginx sirve Angular y la API bajo el
// mismo dominio, asi que el navegador no ve dos origenes distintos.
builder.Services.AddCors(o => o.AddPolicy("desarrollo", p => p
    .WithOrigins("http://localhost:4200")
    .AllowAnyHeader()
    .AllowAnyMethod()));

var app = builder.Build();

// ---------------------------------------------------------------------
//  Tuberia. El orden importa.
// ---------------------------------------------------------------------
app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseCors("desarrollo");
}

app.UseAuthentication();   // primero: quien eres
app.UseAuthorization();    // despues:  que puedes hacer
app.MapControllers();

// Punto de salud. NO consulta la base a proposito: si lo hiciera,
// mantendria despierta la base sin servidor y se comeria las 55 horas
// gratuitas del mes en dos dias. 'version' dice desde fuera que codigo
// esta corriendo.
app.MapGet("/salud", () => Results.Ok(new
{
    estado = "ok",
    version,
    fecha  = DateTime.UtcNow
}));

app.Run();
