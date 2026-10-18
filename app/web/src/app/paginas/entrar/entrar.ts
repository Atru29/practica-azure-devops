import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { CajaAviso } from '../../nucleo/componentes/caja-aviso';
import { Icono } from '../../nucleo/iconos/icono';
import { crearAviso } from '../../nucleo/servicios/aviso';
import { mensajeDeError } from '../../nucleo/servicios/mensaje-error';
import { Autenticacion } from '../../nucleo/servicios/autenticacion';

interface CuentaDemo { etiqueta: string; email: string; rol: string; }

@Component({
  selector: 'app-entrar',
  imports: [FormsModule, Icono, CajaAviso],
  templateUrl: './entrar.html',
  styleUrl: './entrar.css',
})
export class Entrar {
  private readonly auth = inject(Autenticacion);
  private readonly router = inject(Router);

  /** Es una demostracion: las credenciales se muestran en pantalla. */
  protected readonly cuentas: CuentaDemo[] = [
    { etiqueta: 'Alumno',  email: 'ana.quispe@universidad-demo.edu', rol: 'Alumno'  },
    { etiqueta: 'Alumno',  email: 'luis.ramos@universidad-demo.edu', rol: 'Alumno'  },
    { etiqueta: 'Gestor',  email: 'gestor@universidad-demo.edu',     rol: 'Gestor'  },
    { etiqueta: 'Docente', email: 'm.torres@universidad-demo.edu',   rol: 'Docente' },
  ];
  protected readonly claveDemo = 'admin123.$';

  protected email = signal('');
  protected clave = signal('');
  protected readonly aviso = crearAviso();
  protected cargando = signal(false);

  protected elegir(cuenta: CuentaDemo): void {
    this.email.set(cuenta.email);
    this.clave.set(this.claveDemo);
    this.aviso.limpiar();
  }

  protected async entrar(): Promise<void> {
    this.aviso.limpiar();
    this.cargando.set(true);

    try {
      await this.auth.entrar(this.email(), this.clave());
      await this.router.navigate(['/']);
    } catch (e) {
      this.aviso.error(mensajeDeError(e));
    } finally {
      this.cargando.set(false);
    }
  }
}
