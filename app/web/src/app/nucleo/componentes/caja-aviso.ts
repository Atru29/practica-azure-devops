import { Component, input } from '@angular/core';
import { Aviso } from '../servicios/aviso';

@Component({
  selector: 'app-aviso',
  template: `
    @if (de().texto(); as texto) {
      <p class="aviso" [class.ok]="de().tipo() === 'ok'" [class.error]="de().tipo() === 'error'">
        {{ texto }}
      </p>
    }
  `,
  styles: `
    .aviso { animation: entrar .18s ease-out; }
    @keyframes entrar {
      from { opacity: 0; transform: translateY(-4px); }
      to   { opacity: 1; transform: none; }
    }
  `,
})
export class CajaAviso {
  readonly de = input.required<Aviso>();
}
