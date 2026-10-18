using Matriculas.Api.Modulos.Matriculas.Modelos;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace Matriculas.Api.Modulos.Constancias;

/// <summary>
/// Dibuja la constancia de matricula.
///
/// Solo recibe datos ya comprobados: no consulta la base ni decide si
/// la matricula puede tener constancia. Eso lo hace quien lo llama.
/// </summary>
public static class ConstanciaPdf
{
    private const string Institucion = "Universidad Demo";
    private const string Verde       = "#2f6a4d";
    private const string VerdeSuave  = "#e4f3ea";
    private const string Gris        = "#4e6a5e";
    private const string Linea       = "#dfe4ea";

    public static byte[] Generar(MatriculaCabecera m, IReadOnlyList<MatriculaCurso> cursos)
    {
        var creditos = cursos.Sum(c => c.Creditos);

        return Document.Create(doc =>
        {
            doc.Page(pagina =>
            {
                pagina.Size(PageSizes.A4);
                pagina.Margin(2, Unit.Centimetre);
                pagina.DefaultTextStyle(t => t.FontSize(10).FontColor(Colors.Black));

                pagina.Header().Element(e => Cabecera(e, m));
                pagina.Content().Element(e => Cuerpo(e, m, cursos, creditos));
                pagina.Footer().Element(e => Pie(e, m));
            });
        }).GeneratePdf();
    }

    // ------------------------------------------------------------------
    private static void Cabecera(IContainer c, MatriculaCabecera m) =>
        c.PaddingBottom(20).Column(col =>
        {
            col.Item().Row(fila =>
            {
                fila.RelativeItem().Column(izq =>
                {
                    izq.Item().Text(Institucion).FontSize(15).Bold().FontColor(Verde);
                    izq.Item().Text("Oficina de Registros Academicos").FontSize(9).FontColor(Gris);
                });

                fila.ConstantItem(150).AlignRight().Column(der =>
                {
                    der.Item().Text("CONSTANCIA DE MATRICULA").FontSize(9).Bold().FontColor(Gris);
                    der.Item().Text($"N.o {m.Id:D6}").FontSize(9).FontColor(Gris);
                });
            });

            col.Item().PaddingTop(12).LineHorizontal(2).LineColor(Verde);
        });

    // ------------------------------------------------------------------
    private static void Cuerpo(
        IContainer c, MatriculaCabecera m, IReadOnlyList<MatriculaCurso> cursos, int creditos) =>
        c.Column(col =>
        {
            col.Spacing(18);

            col.Item().Text(t =>
            {
                t.DefaultTextStyle(e => e.LineHeight(1.5f));
                t.Span("La Oficina de Registros Academicos hace constar que ");
                t.Span(m.Alumno).Bold();
                t.Span(", con codigo ");
                t.Span(m.AlumnoCodigo).Bold();
                t.Span(", se encuentra matriculado(a) en el periodo academico ");
                t.Span(m.Periodo).Bold();
                t.Span(" en los cursos que se detallan a continuacion.");
            });

            // ---- tabla de cursos ----
            col.Item().Table(tabla =>
            {
                tabla.ColumnsDefinition(cd =>
                {
                    cd.ConstantColumn(58);    // codigo
                    cd.RelativeColumn();      // nombre
                    cd.ConstantColumn(118);   // docente
                    cd.ConstantColumn(38);    // ciclo
                    // 62 y no 50: con 50, la palabra CREDITOS se parte
                    // en dos lineas.
                    cd.ConstantColumn(62);    // creditos
                });

                tabla.Header(h =>
                {
                    foreach (var (texto, derecha) in new[]
                    {
                        ("CODIGO", false), ("CURSO", false), ("DOCENTE", false),
                        ("CICLO", true), ("CREDITOS", true)
                    })
                    {
                        var celda = h.Cell().Background(VerdeSuave).Padding(6);
                        var txt = derecha ? celda.AlignRight() : celda;
                        txt.Text(texto).FontSize(8).Bold().FontColor(Verde);
                    }
                });

                foreach (var curso in cursos)
                {
                    tabla.Cell().Element(Celda).Text(curso.Codigo);
                    tabla.Cell().Element(Celda).Text(curso.Nombre);
                    tabla.Cell().Element(Celda).Text(curso.Docente).FontColor(Gris);
                    tabla.Cell().Element(Celda).AlignRight().Text(curso.Ciclo.ToString());
                    tabla.Cell().Element(Celda).AlignRight().Text(curso.Creditos.ToString());
                }

                // ---- fila de totales ----
                tabla.Cell().ColumnSpan(2).Element(Total).Text("TOTAL").Bold();
                tabla.Cell().ColumnSpan(2).Element(Total).AlignRight()
                     .Text($"{cursos.Count} curso(s)").Bold();
                tabla.Cell().Element(Total).AlignRight().Text(creditos.ToString()).Bold();

                static IContainer Celda(IContainer x) =>
                    x.BorderBottom(1).BorderColor(Linea).Padding(6);

                static IContainer Total(IContainer x) =>
                    x.BorderTop(1).BorderColor(Verde).PaddingVertical(7).PaddingHorizontal(6);
            });

            // ---- datos de la resolucion ----
            col.Item().PaddingTop(6).Row(fila =>
            {
                Dato(fila.RelativeItem(), "ESTADO", m.Estado);
                Dato(fila.RelativeItem(), "APROBADA EL",
                     m.FechaResolucion?.ToString("dd/MM/yyyy HH:mm") ?? "-");
                Dato(fila.RelativeItem(), "SOLICITADA EL",
                     m.FechaSolicitud.ToString("dd/MM/yyyy HH:mm"));
            });

            static void Dato(IContainer x, string rotulo, string valor) =>
                x.Column(cc =>
                {
                    cc.Item().Text(rotulo).FontSize(7.5f).Bold().FontColor(Gris);
                    cc.Item().Text(valor).FontSize(10);
                });
        });

    // ------------------------------------------------------------------
    private static void Pie(IContainer c, MatriculaCabecera m) =>
        c.PaddingTop(16).Column(col =>
        {
            col.Item().LineHorizontal(1).LineColor(Linea);

            col.Item().PaddingTop(8).Row(fila =>
            {
                fila.RelativeItem().Text(t =>
                {
                    t.DefaultTextStyle(e => e.FontSize(7.5f).FontColor(Gris));
                    t.Line("Documento generado automaticamente. No requiere firma manuscrita.");
                    // En UTC a proposito: el servidor puede estar en otra
                    // zona horaria que quien lo lee.
                    t.Span($"Emitido el {DateTime.UtcNow:dd/MM/yyyy HH:mm} UTC");
                });

                fila.ConstantItem(110).AlignRight().AlignBottom()
                    .Text(t => t.Span($"Verificacion: {m.Id:D6}")
                                .FontSize(7.5f).FontColor(Gris));
            });
        });
}
