# Cabeceras de seguridad, en un fichero aparte porque hay que repetirlas
# en cada bloque que use add_header (nginx no las acumula entre niveles).
#
#   nosniff      el navegador no adivina el tipo de un fichero
#   DENY         la pagina no puede incrustarse en un marco ajeno
#   same-origin  no se filtra la URL completa al salir a otro sitio
add_header X-Content-Type-Options "nosniff"     always;
add_header X-Frame-Options        "DENY"        always;
add_header Referrer-Policy        "same-origin" always;

# HSTS: el navegador recuerda que este dominio va SIEMPRE por https y ya
# no intenta http, ni aunque se escriba a mano. Empieza en 1 dia a
# proposito: si el certificado fallara, un max-age largo dejaria a los
# usuarios sin poder entrar durante meses. Subir a 1 ano (31536000)
# cuando HTTPS lleve un tiempo funcionando sin problemas.
add_header Strict-Transport-Security "max-age=86400" always;
