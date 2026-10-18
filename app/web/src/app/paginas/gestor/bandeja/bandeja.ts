import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatriculaPendiente } from '../../../nucleo/modelos/modelos';
import { CajaAviso } from '../../../nucleo/componentes/caja-aviso';
import { Api } from '../../../nucleo/servicios/api';
import { crearAviso } from '../../../nucleo/servicios/aviso';
import { iniciales } from '../../../nucleo/servicios/iniciales';
import { mensajeDeError } from '../../../nucleo/servicios/mensaje-error';

@Component({
  selector: 'app-bandeja',
  imports: [DatePipe, FormsModule, CajaAviso],
  templateUrl: './bandeja.html',
  styleUrl: './bandeja.css',
})
export class Bandeja {
  private readonly api = inject(Api);

  protected readonly pendientes = signal<MatriculaPendiente[]>([]);
  protected readonly cargando = signal(true);

  /** Resultado de aprobar o rechazar: se borra solo a los 3 segundos. */
  protected readonly aviso = crearAviso();

  /** Fallo al traer la lista: se queda hasta que se recargue. */
  protected readonly errorCarga = signal('');

  /** Id de la matricula que se esta rechazando, o null. */
  protected readonly rechazando = signal<number | null>(null);
  protected readonly motivo = signal('');

  protected readonly iniciales = iniciales;

  constructor() { this.cargar(); }

  protected async cargar(): Promise<void> {
    this.cargando.set(true);
    this.errorCarga.set('');
    try {
      this.pendientes.set(await this.api.pendientes());
    } catch (e) {
      this.errorCarga.set(mensajeDeError(e));
    } finally {
      this.cargando.set(false);
    }
  }

  protected async aprobar(m: MatriculaPendiente): Promise<void> {
    try {
      await this.api.aprobar(m.id);
      await this.cargar();
      this.aviso.exito(`Matricula de ${m.alumno} aprobada.`);
    } catch (e) {
      this.aviso.error(mensajeDeError(e));
    }
  }

  protected abrirRechazo(id: number): void {
    this.rechazando.set(id);
    this.motivo.set('');
    this.aviso.limpiar();
  }

  protected cancelarRechazo(): void {
    this.rechazando.set(null);
    this.motivo.set('');
  }

  protected async confirmarRechazo(m: MatriculaPendiente): Promise<void> {
    try {
      await this.api.rechazar(m.id, this.motivo());
      this.rechazando.set(null);
      await this.cargar();
      this.aviso.exito(`Matricula de ${m.alumno} rechazada.`);
    } catch (e) {
      this.aviso.error(mensajeDeError(e));
    }
  }
}
