// Espejo de lo que devuelve la API. Si cambia alla, cambia aqui.

export type Rol = 'Alumno' | 'Gestor' | 'Docente';

export interface Sesion {
  token: string;
  expira: string;
  usuarioId: number;
  email: string;
  rol: Rol;
  nombre: string;
  alumnoId: number | null;
  docenteId: number | null;
}

export interface Alumno {
  id: number;
  codigo: string;
  nombres: string;
  apellidos: string;
  dni: string;
  email: string;
  activo: boolean;
}

export interface Periodo {
  id: number;
  nombre: string;
  fechaInicio: string;
  fechaFin: string;
  estado: string;
  matriculas?: number;
}

export interface Curso {
  id: number;
  codigo: string;
  nombre: string;
  creditos: number;
  ciclo: number;
  docenteId: number;
  docente: string;

  /** Codigos que este curso exige aprobados. null si no exige nada. */
  requisitos: string | null;

  /** El alumno que consulta no cumple los requisitos. */
  bloqueado: boolean;
}

export interface MatriculaPendiente {
  id: number;
  alumnoCodigo: string;
  alumno: string;
  periodo: string;
  fechaSolicitud: string;
  cursos: number;
  creditos: number;
}

export interface MatriculaDeAlumno {
  id: number;
  periodo: string;
  estado: 'Solicitada' | 'Aprobada' | 'Rechazada';
  fechaSolicitud: string;
  fechaResolucion: string | null;
  observacion: string | null;
  constanciaRuta: string | null;
  cursos: number;
  creditos: number;
}

export interface MatriculaResultado {
  matriculaId: number;
  estado: string;
  creditos: number | null;
}

/** Lo que devuelve la API cuando algo falla. */
export interface ErrorApi {
  status: number;
  title: string;
  detail: string;
  codigoError: number | null;
}
