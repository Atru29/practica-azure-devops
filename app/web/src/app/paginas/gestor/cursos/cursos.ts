import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Icono } from '../../../nucleo/iconos/icono';
import { Curso } from '../../../nucleo/modelos/modelos';
import { Api } from '../../../nucleo/servicios/api';
import { mensajeDeError } from '../../../nucleo/servicios/mensaje-error';

@Component({
  selector: 'app-cursos',
  imports: [FormsModule, Icono],
  templateUrl: './cursos.html',
})
export class Cursos {
  private readonly api = inject(Api);

  protected readonly todos = signal<Curso[]>([]);
  protected readonly cargando = signal(true);
  protected readonly error = signal('');
  protected readonly filtro = signal('');

  protected readonly visibles = computed(() => {
    const t = this.filtro().trim().toLowerCase();
    if (!t) return this.todos();
    return this.todos().filter(c =>
      `${c.nombre} ${c.codigo} ${c.docente}`.toLowerCase().includes(t));
  });

  protected readonly creditosTotales = computed(() =>
    this.todos().reduce((s, c) => s + c.creditos, 0));

  constructor() { this.cargar(); }

  private async cargar(): Promise<void> {
    try { this.todos.set(await this.api.cursos()); }
    catch (e) { this.error.set(mensajeDeError(e)); }
    finally { this.cargando.set(false); }
  }
}
