import { Component, computed, input } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { inject } from '@angular/core';

/**
 * Los SVG viven aqui y no en cada plantilla. Un <svg> sin width/height
 * mide 300x150 por omision, asi que el tamano se fija siempre.
 */
const TRAZOS: Record<string, string> = {
  panel:     '<path d="M3 3h7v8H3zM14 3h7v5h-7zM14 11h7v10h-7zM3 14h7v7H3z"/>',
  matricula: '<path d="M9 2h6a2 2 0 012 2v1h2a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V6a1 1 0 011-1h2V4a2 2 0 012-2z"/>',
  alumnos:   '<path d="M12 12a4 4 0 100-8 4 4 0 000 8zM4 21a8 8 0 1116 0z"/>',
  cursos:    '<path d="M4 4a2 2 0 012-2h12a2 2 0 012 2v16l-4-2-4 2-4-2-4 2z"/>',
  periodos:  '<path d="M7 2v3M17 2v3M3 9h18M5 5h14a2 2 0 012 2v12a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2z" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
  reloj:     '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 7v5l3 2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
  creditos:  '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 7v10M9.5 9.5h5M9.5 14.5h5" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/>',
  salir:     '<path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
  check:     '<path d="M20 6L9 17l-5-5" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>',
  equis:     '<path d="M18 6L6 18M6 6l12 12" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>',
  buscar:    '<circle cx="11" cy="11" r="7" fill="none" stroke="currentColor" stroke-width="2"/><path d="M20 20l-4-4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
};

@Component({
  selector: 'app-icono',
  template: '<svg [attr.width]="tam()" [attr.height]="tam()" viewBox="0 0 24 24" fill="currentColor" [innerHTML]="trazo()"></svg>',
  styles: ':host { display: inline-flex; flex-shrink: 0; }',
})
export class Icono {
  readonly nombre = input.required<string>();
  readonly tam = input(17);

  private readonly sanitizador = inject(DomSanitizer);

  // Los trazos son constantes escritas aqui, no entrada del usuario:
  // por eso se pueden marcar como seguras sin riesgo.
  protected readonly trazo = computed<SafeHtml>(() =>
    this.sanitizador.bypassSecurityTrustHtml(TRAZOS[this.nombre()] ?? ''));
}
