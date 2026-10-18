import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Autenticacion } from '../servicios/autenticacion';

/**
 * Anade la cabecera Authorization a cada peticion. Sin esto habria que
 * acordarse en cada llamada, y el dia que se olvide una, 401.
 */
export const interceptorToken: HttpInterceptorFn = (peticion, siguiente) => {
  const token = inject(Autenticacion).token;

  if (!token) return siguiente(peticion);

  return siguiente(peticion.clone({
    setHeaders: { Authorization: `Bearer ${token}` }
  }));
};
