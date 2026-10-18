import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { registerLocaleData } from '@angular/common';
import localeEs from '@angular/common/locales/es';
import { ApplicationConfig, LOCALE_ID, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { interceptorToken } from './nucleo/interceptores/token';
import { routes } from './app.routes';

// Numeros con coma decimal y fechas en castellano. Sin esto Angular
// usa en-US y escribe "7.5" donde aqui se escribe "7,5".
registerLocaleData(localeEs);

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([interceptorToken])),
    { provide: LOCALE_ID, useValue: 'es' },
  ],
};
