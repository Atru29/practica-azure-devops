import { DestroyRef, inject, signal } from '@angular/core';

export type TipoAviso = 'ok' | 'error';

const DURACION_MS = 3000;

/**
 * Un mensaje que se borra solo pasados unos segundos.
 *
 * Es para avisos de ACCION ("matricula aprobada", "ya tienes una"),
 * no para errores de carga: si la pagina no ha podido traer sus datos,
 * el mensaje tiene que quedarse o el usuario se queda mirando una
 * tabla vacia sin saber por que.
 */
export class Aviso {
  private temporizador?: ReturnType<typeof setTimeout>;

  readonly texto = signal('');
  readonly tipo  = signal<TipoAviso>('error');

  constructor(private readonly duracionMs: number = DURACION_MS) {}

  error(texto: string): void { this.mostrar(texto, 'error'); }
  exito(texto: string): void { this.mostrar(texto, 'ok'); }

  mostrar(texto: string, tipo: TipoAviso = 'error'): void {
    // Reinicia la cuenta: dos avisos seguidos no comparten reloj.
    this.limpiar();
    this.texto.set(texto);
    this.tipo.set(tipo);
    this.temporizador = setTimeout(() => this.texto.set(''), this.duracionMs);
  }

  limpiar(): void {
    if (this.temporizador !== undefined) clearTimeout(this.temporizador);
    this.temporizador = undefined;
    this.texto.set('');
  }
}

/**
 * Se llama como campo del componente. Asi queda registrado el aparte
 * de limpieza: si el usuario cambia de pagina antes de que pasen los
 * 3 segundos, el temporizador se cancela en lugar de dispararse sobre
 * un componente ya destruido.
 */
export function crearAviso(duracionMs: number = DURACION_MS): Aviso {
  const aviso = new Aviso(duracionMs);
  inject(DestroyRef).onDestroy(() => aviso.limpiar());
  return aviso;
}
