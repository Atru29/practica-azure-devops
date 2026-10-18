import { Component, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Icono } from '../../nucleo/iconos/icono';
import { Alumno, Curso, MatriculaDeAlumno, MatriculaPendiente, Periodo } from '../../nucleo/modelos/modelos';
import { Api } from '../../nucleo/servicios/api';
import { Autenticacion } from '../../nucleo/servicios/autenticacion';
import { iniciales } from '../../nucleo/servicios/iniciales';
import { mensajeDeError } from '../../nucleo/servicios/mensaje-error';

interface Barra { etiqueta: string; valor: number; texto: string; pct: number; }

@Component({
  selector: 'app-panel',
  imports: [DatePipe, DecimalPipe, RouterLink, Icono],
  templateUrl: './panel.html',
  styleUrl: './panel.css',
})
export class Panel {
  private readonly api = inject(Api);
  protected readonly auth = inject(Autenticacion);

  protected readonly cargando = signal(true);
  protected readonly error = signal('');

  // --- gestor ---
  protected readonly alumnos    = signal<Alumno[]>([]);
  protected readonly cursos     = signal<Curso[]>([]);
  protected readonly periodos   = signal<Periodo[]>([]);
  protected readonly pendientes = signal<MatriculaPendiente[]>([]);

  // --- alumno ---
  protected readonly mias            = signal<MatriculaDeAlumno[]>([]);
  protected readonly periodoAbierto  = signal<Periodo | null>(null);

  protected readonly esGestor  = computed(() => this.auth.rol() === 'Gestor');
  protected readonly esDocente = computed(() => this.auth.rol() === 'Docente');

  constructor() { this.cargar(); }

  private async cargar(): Promise<void> {
    try {
      if (this.esGestor()) {
        // En paralelo: cuatro peticiones independientes no tienen por que
        // esperarse unas a otras.
        const [alumnos, cursos, periodos, pendientes] = await Promise.all([
          this.api.alumnos(), this.api.cursos(), this.api.periodos(), this.api.pendientes(),
        ]);
        this.alumnos.set(alumnos);
        this.cursos.set(cursos);
        this.periodos.set(periodos);
        this.pendientes.set(pendientes);
      } else if (this.esDocente()) {
        const [periodo, cursos] = await Promise.all([
          this.api.periodoAbierto().catch(() => null),
          this.api.cursos(),
        ]);
        this.periodoAbierto.set(periodo);
        this.cursos.set(cursos);
      } else {
        const [periodo, mias] = await Promise.all([
          this.api.periodoAbierto().catch(() => null),
          this.api.misMatriculas(),
        ]);
        this.periodoAbierto.set(periodo);
        this.mias.set(mias);
      }
    } catch (e) {
      this.error.set(mensajeDeError(e));
    } finally {
      this.cargando.set(false);
    }
  }

  // ------------------------------ indicadores ------------------------------
  protected readonly alumnosActivos = computed(() => this.alumnos().filter(a => a.activo).length);

  protected readonly enCurso = computed(() =>
    this.periodos().find(p => p.estado === 'Abierto') ?? null);

  protected readonly matriculasDelPeriodo = computed(() => this.enCurso()?.matriculas ?? 0);

  protected readonly creditosMedios = computed(() => {
    const lista = this.pendientes();
    if (lista.length === 0) return 0;
    return lista.reduce((s, m) => s + m.creditos, 0) / lista.length;
  });

  /** Cuantos dias lleva esperando la solicitud mas antigua. */
  protected readonly esperaMasLarga = computed(() => {
    const fechas = this.pendientes().map(m => new Date(m.fechaSolicitud).getTime());
    if (fechas.length === 0) return null;
    const dias = (Date.now() - Math.min(...fechas)) / 86_400_000;
    return dias < 1 ? 'la mas antigua, hoy' : `la mas antigua, hace ${Math.floor(dias)} dia(s)`;
  });

  // -------------------------------- barras --------------------------------
  protected readonly porPeriodo = computed<Barra[]>(() => {
    const lista = this.periodos().slice(0, 5);
    const tope = Math.max(1, ...lista.map(p => p.matriculas ?? 0));
    return lista.map(p => ({
      etiqueta: p.nombre,
      valor: p.matriculas ?? 0,
      texto: String(p.matriculas ?? 0),
      pct: Math.round(100 * (p.matriculas ?? 0) / tope),
    }));
  });

  protected readonly porCiclo = computed<Barra[]>(() => {
    const cuenta = new Map<number, number>();
    for (const c of this.cursos()) cuenta.set(c.ciclo, (cuenta.get(c.ciclo) ?? 0) + 1);
    const tope = Math.max(1, ...cuenta.values());
    return [...cuenta.entries()]
      .sort((a, b) => a[0] - b[0])
      .map(([ciclo, n]) => ({
        etiqueta: `Ciclo ${ciclo}`,
        valor: n,
        texto: `${n} curso(s)`,
        pct: Math.round(100 * n / tope),
      }));
  });

  // ------------------------------- del alumno -------------------------------
  protected readonly aprobadas = computed(() => this.mias().filter(m => m.estado === 'Aprobada').length);
  protected readonly enEspera  = computed(() => this.mias().filter(m => m.estado === 'Solicitada').length);
  protected readonly creditosActuales = computed(() =>
    this.mias().find(m => m.estado === 'Aprobada')?.creditos ?? 0);

  // --- del docente ---
  /** El docenteId viaja en el token, igual que el alumnoId. */
  protected readonly misCursos = computed(() => {
    const id = this.auth.sesion()?.docenteId;
    return id ? this.cursos().filter(c => c.docenteId === id) : [];
  });

  protected readonly misCreditos = computed(() =>
    this.misCursos().reduce((s, c) => s + c.creditos, 0));

  protected readonly misCiclos = computed(() =>
    new Set(this.misCursos().map(c => c.ciclo)).size);

  protected readonly iniciales = iniciales;

  /** Porcentaje transcurrido del periodo, para la barra de avance. */
  protected readonly avance = computed(() => {
    const p = this.enCurso() ?? this.periodoAbierto();
    if (!p) return 0;
    const ini = new Date(p.fechaInicio).getTime();
    const fin = new Date(p.fechaFin).getTime();
    if (fin <= ini) return 0;
    return Math.min(100, Math.max(0, Math.round(100 * (Date.now() - ini) / (fin - ini))));
  });
}
