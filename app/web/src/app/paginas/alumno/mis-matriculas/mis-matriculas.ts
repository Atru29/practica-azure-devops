import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { MatriculaDeAlumno } from '../../../nucleo/modelos/modelos';
import { CajaAviso } from '../../../nucleo/componentes/caja-aviso';
import { Api } from '../../../nucleo/servicios/api';
import { crearAviso } from '../../../nucleo/servicios/aviso';
import { mensajeDeError } from '../../../nucleo/servicios/mensaje-error';

@Component({
  selector: 'app-mis-matriculas',
  imports: [DatePipe, CajaAviso],
  templateUrl: './mis-matriculas.html',
  styleUrl: './mis-matriculas.css',
})
export class MisMatriculas {
  private readonly api = inject(Api);

  protected readonly matriculas = signal<MatriculaDeAlumno[]>([]);
  protected readonly cargando = signal(true);
  protected readonly errorCarga = signal('');
  protected readonly aviso = crearAviso();

  /** Id de la matricula cuya constancia se esta descargando. */
  protected readonly descargando = signal<number | null>(null);

  constructor() { this.cargar(); }

  /**
   * Descarga la constancia.
   *
   * No puede ser un <a href> normal: la peticion necesita la cabecera
   * Authorization, y un enlace no la lleva. Asi que se pide el archivo
   * por HTTP y se le pasa al navegador como si viniera de un enlace.
   */
  protected async descargar(m: MatriculaDeAlumno): Promise<void> {
    this.descargando.set(m.id);
    try {
      const archivo = await this.api.constancia(m.id);
      const url = URL.createObjectURL(archivo);

      const enlace = document.createElement('a');
      enlace.href = url;
      enlace.download = `constancia-${m.periodo}.pdf`;
      enlace.click();

      // Sin esto el navegador retiene el archivo en memoria hasta que
      // se cierra la pestana.
      URL.revokeObjectURL(url);
    } catch (e) {
      this.aviso.error(mensajeDeError(e));
    } finally {
      this.descargando.set(null);
    }
  }

  private async cargar(): Promise<void> {
    try {
      this.matriculas.set(await this.api.misMatriculas());
    } catch (e) {
      this.errorCarga.set(mensajeDeError(e));
    } finally {
      this.cargando.set(false);
    }
  }
}
