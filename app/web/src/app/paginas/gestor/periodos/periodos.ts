import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { Periodo } from '../../../nucleo/modelos/modelos';
import { Api } from '../../../nucleo/servicios/api';
import { mensajeDeError } from '../../../nucleo/servicios/mensaje-error';

@Component({
  selector: 'app-periodos',
  imports: [DatePipe],
  templateUrl: './periodos.html',
})
export class Periodos {
  private readonly api = inject(Api);

  protected readonly periodos = signal<Periodo[]>([]);
  protected readonly cargando = signal(true);
  protected readonly error = signal('');

  constructor() { this.cargar(); }

  private async cargar(): Promise<void> {
    try { this.periodos.set(await this.api.periodos()); }
    catch (e) { this.error.set(mensajeDeError(e)); }
    finally { this.cargando.set(false); }
  }
}
