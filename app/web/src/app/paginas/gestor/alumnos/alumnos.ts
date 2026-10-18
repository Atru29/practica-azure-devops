import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Icono } from '../../../nucleo/iconos/icono';
import { Alumno } from '../../../nucleo/modelos/modelos';
import { Api } from '../../../nucleo/servicios/api';
import { iniciales } from '../../../nucleo/servicios/iniciales';
import { mensajeDeError } from '../../../nucleo/servicios/mensaje-error';

@Component({
  selector: 'app-alumnos',
  imports: [FormsModule, Icono],
  templateUrl: './alumnos.html',
})
export class Alumnos {
  private readonly api = inject(Api);

  protected readonly todos = signal<Alumno[]>([]);
  protected readonly cargando = signal(true);
  protected readonly error = signal('');
  protected readonly filtro = signal('');

  protected readonly iniciales = iniciales;

  /** El filtro se aplica en el navegador: la lista es pequena. */
  protected readonly visibles = computed(() => {
    const t = this.filtro().trim().toLowerCase();
    if (!t) return this.todos();
    return this.todos().filter(a =>
      `${a.nombres} ${a.apellidos} ${a.codigo} ${a.email}`.toLowerCase().includes(t));
  });

  constructor() { this.cargar(); }

  private async cargar(): Promise<void> {
    try { this.todos.set(await this.api.alumnos()); }
    catch (e) { this.error.set(mensajeDeError(e)); }
    finally { this.cargando.set(false); }
  }
}
