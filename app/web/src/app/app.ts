import { Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Icono } from './nucleo/iconos/icono';
import { Autenticacion } from './nucleo/servicios/autenticacion';
import { iniciales } from './nucleo/servicios/iniciales';
import { Rol } from './nucleo/modelos/modelos';

interface Enlace { ruta: string; icono: string; texto: string; roles: Rol[]; }
interface Grupo  { titulo: string; enlaces: Enlace[]; }

@Component({
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Icono],
  selector: 'app-root',
  styleUrl: './app.css',
  templateUrl: './app.html',
})
export class App {
  protected readonly auth = inject(Autenticacion);

  private readonly grupos: Grupo[] = [
    {
      titulo: 'General',
      enlaces: [
        { ruta: '/panel', icono: 'panel', texto: 'Panel', roles: ['Alumno', 'Gestor', 'Docente'] },
      ],
    },
    {
      titulo: 'Academico',
      enlaces: [
        { ruta: '/solicitar',      icono: 'matricula', texto: 'Solicitar matricula', roles: ['Alumno'] },
        { ruta: '/mis-matriculas', icono: 'cursos',    texto: 'Mis matriculas',      roles: ['Alumno'] },
        { ruta: '/bandeja',        icono: 'matricula', texto: 'Matriculas',          roles: ['Gestor'] },
        { ruta: '/alumnos',        icono: 'alumnos',   texto: 'Alumnos',             roles: ['Gestor', 'Docente'] },
        { ruta: '/cursos',         icono: 'cursos',    texto: 'Cursos',              roles: ['Gestor', 'Docente'] },
        { ruta: '/periodos',       icono: 'periodos',  texto: 'Periodos',            roles: ['Gestor'] },
      ],
    },
  ];

  /** Solo los enlaces que su rol puede abrir; los grupos vacios se caen. */
  protected readonly menu = computed<Grupo[]>(() => {
    const rol = this.auth.rol();
    if (!rol) return [];
    return this.grupos
      .map(g => ({ ...g, enlaces: g.enlaces.filter(e => e.roles.includes(rol)) }))
      .filter(g => g.enlaces.length > 0);
  });

  protected readonly iniciales = computed(() => iniciales(this.auth.nombre()));
}
