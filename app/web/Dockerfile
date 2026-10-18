# =====================================================================
#  Frontend: se compila con Node y se sirve con nginx.
#
#  La imagen final NO lleva Node: Angular genera HTML, JavaScript y CSS
#  estaticos, y para servirlos basta nginx. Eso baja de ~1,1 GB a ~60 MB
#  y quita de en medio todo el superficie de ataque de Node y sus
#  dependencias.
# =====================================================================

FROM node:22-alpine AS compilacion
WORKDIR /origen

# Primero solo los manifiestos: mientras no cambien las dependencias,
# Docker reutiliza la capa de npm ci aunque cambie todo el codigo.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build -- --configuration production


FROM nginxinc/nginx-unprivileged:1.29-alpine AS final

# Esta imagen ya corre como el usuario 'nginx' y escucha en el 8080,
# sin privilegios. La oficial de nginx arranca su proceso maestro como
# root.
COPY nginx.conf    /etc/nginx/conf.d/default.conf
COPY seguridad.inc /etc/nginx/conf.d/seguridad.inc
COPY --from=compilacion /origen/dist/web/browser /usr/share/nginx/html

EXPOSE 8080 8443
