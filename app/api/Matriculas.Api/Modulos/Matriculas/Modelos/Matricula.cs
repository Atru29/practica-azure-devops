namespace Matriculas.Api.Modulos.Matriculas.Modelos;

/// <summary>Una fila de la bandeja del gestor.</summary>
public sealed class MatriculaPendiente
{
    public int      Id             { get; init; }
    public string   AlumnoCodigo   { get; init; } = "";
    public string   Alumno         { get; init; } = "";
    public string   Periodo        { get; init; } = "";
    public DateTime FechaSolicitud { get; init; }
    public int      Cursos         { get; init; }
    public int      Creditos       { get; init; }
}

/// <summary>Lo que ve el alumno de sus propias matriculas.</summary>
public sealed class MatriculaDeAlumno
{
    public int       Id              { get; init; }
    public string    Periodo         { get; init; } = "";
    public string    Estado          { get; init; } = "";
    public DateTime  FechaSolicitud  { get; init; }
    public DateTime? FechaResolucion { get; init; }
    public string?   Observacion     { get; init; }
    public string?   ConstanciaRuta  { get; init; }
    public int       Cursos          { get; init; }
    public int       Creditos        { get; init; }
}

/// <summary>Cabecera del detalle: el primer conjunto de usp_Matricula_Obtener.</summary>
public sealed class MatriculaCabecera
{
    public int       Id                   { get; init; }
    public int       AlumnoId             { get; init; }
    public string    AlumnoCodigo         { get; init; } = "";
    public string    Alumno               { get; init; } = "";
    public string    Periodo              { get; init; } = "";
    public string    Estado               { get; init; } = "";
    public DateTime  FechaSolicitud       { get; init; }
    public DateTime? FechaResolucion      { get; init; }
    public string?   Gestor               { get; init; }
    public string?   Observacion          { get; init; }
    public string?   ConstanciaRuta       { get; init; }
    public DateTime? ConstanciaGeneradaEn { get; init; }
}

/// <summary>Un curso del detalle: el segundo conjunto.</summary>
public sealed class MatriculaCurso
{
    public int    Id       { get; init; }
    public string Codigo   { get; init; } = "";
    public string Nombre   { get; init; } = "";
    public byte   Creditos { get; init; }
    public byte   Ciclo    { get; init; }
    public string Docente  { get; init; } = "";
}

/// <summary>Los dos conjuntos juntos, que es lo que se devuelve por HTTP.</summary>
public sealed class MatriculaDetalle
{
    public required MatriculaCabecera         Cabecera { get; init; }
    public required IEnumerable<MatriculaCurso> Cursos { get; init; }
}

public sealed class MatriculaResultado
{
    public int     MatriculaId { get; init; }
    public string  Estado      { get; init; } = "";
    public int?    Creditos    { get; init; }
}
