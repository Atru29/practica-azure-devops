import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import {
  Alumno, Curso, MatriculaDeAlumno, MatriculaPendiente, MatriculaResultado, Periodo
} from '../modelos/modelos';

/**
 * Las rutas van sin dominio: '/api/...'.
 *
 * En desarrollo, proxy.conf.json las reenvia a localhost:5080.
 * En produccion, nginx hace lo mismo hacia el contenedor de la API.
 * Resultado: el navegador siempre ve UN solo origen, y CORS no existe.
 */
@Injectable({ providedIn: 'root' })
export class Api {
  private readonly http = inject(HttpClient);

  // ---- catalogos ----
  periodoAbierto = () =>
    firstValueFrom(this.http.get<Periodo>('/api/periodos/abierto'));

  cursos = () =>
    firstValueFrom(this.http.get<Curso[]>('/api/cursos'));

  /** Solo Gestor. Docente recibiria 403. */
  periodos = () =>
    firstValueFrom(this.http.get<Periodo[]>('/api/periodos'));

  /** Gestor y Docente. */
  alumnos = () =>
    firstValueFrom(this.http.get<Alumno[]>('/api/alumnos'));

  // ---- alumno ----
  solicitarMatricula = (periodoId: number, cursos: number[]) =>
    firstValueFrom(this.http.post<MatriculaResultado>(
      '/api/matriculas/solicitar', { periodoId, cursos }));

  misMatriculas = () =>
    firstValueFrom(this.http.get<MatriculaDeAlumno[]>('/api/matriculas/mias'));

  /**
   * La constancia llega como PDF, no como JSON.
   *
   * Se pide con responseType 'blob' porque el interceptor tiene que
   * anadir el token igual que en el resto: no vale un enlace normal,
   * que no lleva cabeceras.
   */
  constancia = (matriculaId: number) =>
    firstValueFrom(this.http.get(`/api/matriculas/${matriculaId}/constancia`,
      { responseType: 'blob' }));

  // ---- gestor ----
  pendientes = () =>
    firstValueFrom(this.http.get<MatriculaPendiente[]>('/api/matriculas/pendientes'));

  aprobar = (id: number) =>
    firstValueFrom(this.http.post<MatriculaResultado>(
      `/api/matriculas/${id}/aprobar`, {}));

  rechazar = (id: number, observacion: string) =>
    firstValueFrom(this.http.post<MatriculaResultado>(
      `/api/matriculas/${id}/rechazar`, { observacion }));
}
