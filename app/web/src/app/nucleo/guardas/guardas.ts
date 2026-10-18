import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { Rol } from '../modelos/modelos';
import { Autenticacion } from '../servicios/autenticacion';

/** Hay que haber entrado. */
export const guardaSesion: CanActivateFn = () => {
  const auth = inject(Autenticacion);
  const router = inject(Router);

  return auth.autenticado() ? true : router.createUrlTree(['/entrar']);
};

/**
 * Ademas, hay que tener uno de los roles indicados en la ruta.
 *
 * OJO: esto solo oculta pantallas. La seguridad de verdad esta en la
 * API, que comprueba el rol del token en cada peticion. Un guarda del
 * navegador se salta escribiendo la URL a mano.
 */
export const guardaRol = (roles: Rol[]): CanActivateFn => () => {
  const auth = inject(Autenticacion);
  const router = inject(Router);

  if (!auth.autenticado()) return router.createUrlTree(['/entrar']);

  const rol = auth.rol();
  return rol && roles.includes(rol) ? true : router.createUrlTree(['/']);
};
