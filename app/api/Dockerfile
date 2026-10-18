# =====================================================================
#  Imagen de la API. Construccion en dos fases para que la imagen final
#  NO lleve el SDK de .NET: son ~800 MB que no hacen falta para ejecutar.
# =====================================================================

# ---------- fase 1: compilar ----------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS compilacion
WORKDIR /origen

# Primero SOLO los ficheros de proyecto y se restauran los paquetes.
# Docker cachea esa capa: mientras no cambien las dependencias, no se
# vuelven a descargar aunque cambie todo el codigo.
COPY global.json .
COPY Matriculas.Api/Matriculas.Api.csproj Matriculas.Api/
RUN dotnet restore Matriculas.Api/Matriculas.Api.csproj

# Ahora si, el codigo
COPY . .
RUN dotnet publish Matriculas.Api/Matriculas.Api.csproj \
      --configuration Release \
      --no-restore \
      --output /publicado

# ---------- fase 2: ejecutar ----------
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

# QuestPDF dibuja el texto con SkiaSharp, que necesita las bibliotecas
# de fuentes del sistema. La imagen de .NET no las trae: sin esto, el
# PDF falla al generarse con un error de biblioteca nativa que no dice
# nada. DejaVu da ademas tildes y enes.
# wget es para el healthcheck del compose: la imagen de .NET no trae ni
# wget ni curl, y sin el la API sale 'unhealthy' aunque responda bien.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libfontconfig1 fonts-dejavu-core wget \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Usuario sin privilegios. Las imagenes de .NET ya traen uno llamado
# 'app' (UID 1654) desde la version 8, asi que no hay que crearlo: solo
# usarlo. Sin esta linea el contenedor corre como root, y quien escape
# de el lo hace siendo root en el anfitrion.
USER app

COPY --from=compilacion --chown=app /publicado .

# 8080 y no 80: un usuario sin privilegios no puede abrir puertos
# por debajo del 1024.
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "Matriculas.Api.dll"]
