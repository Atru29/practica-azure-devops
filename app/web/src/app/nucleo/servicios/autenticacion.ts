import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { Rol, Sesion } from '../modelos/modelos';

const CLAVE_ALMACEN = 'sesion';

@Injectable({ providedIn: 'root' })
export class Autenticacion {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);

  /**
   * La sesion es una senal: cualquier plantilla que la lea se repinta
   * sola al entrar o salir, sin suscripciones ni avisos manuales.
   */
  private readonly _sesion = signal<Sesion | null>(this.leerDelAlmacen());

  readonly sesion = this._sesion.asReadonly();
  readonly autenticado = computed(() => this._sesion() !== null);
  readonly rol = computed<Rol | null>(() => this._sesion()?.rol ?? null);
  /**
   * Alumnos y docentes tienen nombre propio en su tabla. Un gestor no:
   * la tabla Usuario solo guarda correo, asi que se usa la parte de
   * delante de la arroba. Si algun dia Usuario guarda nombre, este
   * apano sobra.
   */
  readonly nombre = computed(() => {
    const s = this._sesion();
    if (!s) return '';
    const propio = s.nombre.trim();
    if (propio) return propio;
    const usuario = s.email.split('@')[0].replace(/[._-]+/g, ' ');
    return usuario.replace(/\b\w/g, c => c.toUpperCase());
  });

  async entrar(email: string, clave: string): Promise<void> {
    const sesion = await firstValueFrom(
      this.http.post<Sesion>('/api/autenticacion/entrar', { email, clave })
    );
    localStorage.setItem(CLAVE_ALMACEN, JSON.stringify(sesion));
    this._sesion.set(sesion);
  }

  salir(): void {
    localStorage.removeItem(CLAVE_ALMACEN);
    this._sesion.set(null);
    this.router.navigate(['/entrar']);
  }

  get token(): string | null {
    return this._sesion()?.token ?? null;
  }

  /**
   * Se guarda en localStorage para que recargar la pagina no te eche.
   * Si el token esta caducado se descarta: asi no se manda una peticion
   * condenada al 401 solo para descubrirlo.
   */
  private leerDelAlmacen(): Sesion | null {
    const bruto = localStorage.getItem(CLAVE_ALMACEN);
    if (!bruto) return null;

    try {
      const sesion = JSON.parse(bruto) as Sesion;
      if (new Date(sesion.expira) <= new Date()) {
        localStorage.removeItem(CLAVE_ALMACEN);
        return null;
      }
      return sesion;
    } catch {
      localStorage.removeItem(CLAVE_ALMACEN);
      return null;
    }
  }
}
