import { HttpErrorResponse } from '@angular/common/http';
import { ErrorApi } from '../modelos/modelos';

/**
 * Saca el texto util de un error de la API.
 *
 * La API devuelve dos formas distintas:
 *   - ProblemDetails propio      { detail: "El alumno ya tiene..." }
 *   - validacion de ASP.NET      { errors: { Dni: ["..."], ... } }
 */
export function mensajeDeError(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) {
    return 'No se pudo completar la operacion.';
  }

  if (error.status === 0) {
    return 'No hay conexion con el servidor.';
  }

  if (error.status === 401) {
    return 'Correo o contrasena incorrectos.';
  }

  const cuerpo = error.error as (ErrorApi & { errors?: Record<string, string[]> }) | null;

  if (cuerpo?.errors) {
    return Object.values(cuerpo.errors).flat().join(' ');
  }

  return cuerpo?.detail ?? 'No se pudo completar la operacion.';
}
