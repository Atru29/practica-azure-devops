import { Routes } from '@angular/router';
import { guardaRol, guardaSesion } from './nucleo/guardas/guardas';

export const routes: Routes = [
  {
    path: 'entrar',
    loadComponent: () => import('./paginas/entrar/entrar').then(m => m.Entrar),
  },
  {
    path: 'panel',
    canActivate: [guardaSesion],
    loadComponent: () => import('./paginas/panel/panel').then(m => m.Panel),
  },

  // --- alumno ---
  {
    path: 'solicitar',
    canActivate: [guardaRol(['Alumno'])],
    loadComponent: () => import('./paginas/alumno/solicitar/solicitar').then(m => m.Solicitar),
  },
  {
    path: 'mis-matriculas',
    canActivate: [guardaRol(['Alumno'])],
    loadComponent: () => import('./paginas/alumno/mis-matriculas/mis-matriculas').then(m => m.MisMatriculas),
  },

  // --- gestion ---
  // La bandeja es solo de Gestor: /api/matriculas/pendientes rechaza a
  // Docente con 403, asi que dejarle entrar seria ensenarle un error.
  {
    path: 'bandeja',
    canActivate: [guardaRol(['Gestor'])],
    loadComponent: () => import('./paginas/gestor/bandeja/bandeja').then(m => m.Bandeja),
  },
  {
    path: 'alumnos',
    canActivate: [guardaRol(['Gestor', 'Docente'])],
    loadComponent: () => import('./paginas/gestor/alumnos/alumnos').then(m => m.Alumnos),
  },
  {
    path: 'cursos',
    canActivate: [guardaRol(['Gestor', 'Docente'])],
    loadComponent: () => import('./paginas/gestor/cursos/cursos').then(m => m.Cursos),
  },
  {
    path: 'periodos',
    canActivate: [guardaRol(['Gestor'])],
    loadComponent: () => import('./paginas/gestor/periodos/periodos').then(m => m.Periodos),
  },

  { path: '',   pathMatch: 'full', redirectTo: 'panel' },
  { path: '**', redirectTo: 'panel' },
];
