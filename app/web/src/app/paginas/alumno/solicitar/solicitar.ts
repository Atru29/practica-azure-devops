import { Component, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { CajaAviso } from '../../../nucleo/componentes/caja-aviso';
import { Curso, Periodo } from '../../../nucleo/modelos/modelos';
import { Api } from '../../../nucleo/servicios/api';
import { crearAviso } from '../../../nucleo/servicios/aviso';
import { mensajeDeError } from '../../../nucleo/servicios/mensaje-error';

const MAXIMO_CREDITOS = 24;

@Component({
  selector: 'app-solicitar',
  imports: [CajaAviso],
  templateUrl: './solicitar.html',
  styleUrl: './solicitar.css',
})
export class Solicitar {
  private readonly api = inject(Api);
  private readonly router = inject(Router);

  protected readonly periodo = signal<Periodo | null>(null);
  protected readonly cursos = signal<Curso[]>([]);
  protected readonly elegidos = signal<Set<number>>(new Set());
  protected readonly cargando = signal(true);
  protected readonly enviando = signal(false);

  /** El de la accion: desaparece solo a los 3 segundos. */
  protected readonly aviso = crearAviso();

  /** El de la carga: se queda, porque sin cursos no hay nada que hacer. */
  protected readonly errorCarga = signal('');

  protected readonly maximo = MAXIMO_CREDITOS;

  /** Se recalcula solo cada vez que cambia la seleccion. */
  protected readonly creditos = computed(() =>
    this.cursos()
      .filter(c => this.elegidos().has(c.id))
      .reduce((suma, c) => suma + c.creditos, 0));

  protected readonly excede = computed(() => this.creditos() > MAXIMO_CREDITOS);
  protected readonly puedeEnviar = computed(() =>
    this.elegidos().size > 0 && !this.excede() && !this.enviando());

  constructor() { this.cargar(); }

  private async cargar(): Promise<void> {
    try {
      const [periodo, cursos] = await Promise.all([
        this.api.periodoAbierto(),
        this.api.cursos(),
      ]);
      this.periodo.set(periodo);
      this.cursos.set(cursos);
    } catch (e) {
      this.errorCarga.set(mensajeDeError(e));
    } finally {
      this.cargando.set(false);
    }
  }

  protected alternar(curso: Curso): void {
    // El bloqueo tambien se comprueba en el procedimiento: esto solo
    // evita que el alumno llegue a enviar algo que iba a fallar.
    if (curso.bloqueado) return;

    // Un Set nuevo, no el mismo mutado: las senales comparan por
    // referencia y no detectarian el cambio.
    const copia = new Set(this.elegidos());
    copia.has(curso.id) ? copia.delete(curso.id) : copia.add(curso.id);
    this.elegidos.set(copia);
  }

  protected estaElegido = (id: number) => this.elegidos().has(id);

  protected async enviar(): Promise<void> {
    const periodo = this.periodo();
    if (!periodo) return;

    this.aviso.limpiar();
    this.enviando.set(true);

    try {
      await this.api.solicitarMatricula(periodo.id, [...this.elegidos()]);
      await this.router.navigate(['/mis-matriculas']);
    } catch (e) {
      this.aviso.error(mensajeDeError(e));
    } finally {
      this.enviando.set(false);
    }
  }
}
