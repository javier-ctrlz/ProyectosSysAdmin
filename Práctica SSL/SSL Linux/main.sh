#!/bin/bash
# main.sh
#   - Configurar el servidor FTP (ejecuta ftp.sh)
#   - Instalar servicios HTTP de forma local (usando las URL oficiales, http.sh)
#   - Instalar servicios HTTP descargando los archivos .tar.gz desde el FTP


cd "$(dirname "$0")"

# Función para configurar el servidor FTP
configurar_ftp() {
    echo ""
    echo "Iniciando configuración del servidor FTP..."
    if [ -x "./ftp.sh" ]; then
        ./ftp.sh
    else
        bash ftp.sh
    fi
}

# Función para instalar servicios HTTP de forma local (online)
instalar_http_local() {
    echo ""
    echo "Iniciando instalación local de servicios HTTP (desde fuentes oficiales)..."
    if [ -x "./http.sh" ]; then
        ./http.sh
    else
        bash http.sh
    fi
}

# Función para explorar el servidor FTP de forma interactiva y descargar el archivo .tar.gz
explorar_ftp() {
    local ftp_path="/"  # Directorio inicial en el FTP
    local selection
    local listado
    local indice
    local opcion_cancelar

    while true; do
        echo ""
        echo "Listando contenido de: ${FTP_BASE_URL}${ftp_path}"
        # Obtener listado de archivos/directorios usando lftp
        listado=()
        while IFS= read -r linea; do
            listado+=("$linea")
        done < <(lftp -c "open ${FTP_BASE_URL}; cls -1 ${ftp_path}")

        if [ ${#listado[@]} -eq 0 ]; then
            echo "No se encontraron archivos o directorios en ${ftp_path}."
            return 1
        fi

        # Mostrar la lista numerada
        indice=1
        for item in "${listado[@]}"; do
            echo "${indice}. ${item}"
            ((indice++))
        done
        opcion_cancelar=${indice}
        echo "${opcion_cancelar}. Cancelar"

        read -p "Selecciona una opción: " selection

        # Validar selección numérica
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$opcion_cancelar" ]; then
            echo "Selección no válida. Intenta de nuevo."
            continue
        fi

        # Si selecciona "Cancelar"
        if [ "$selection" -eq "$opcion_cancelar" ]; then
            echo "Operación cancelada."
            return 1
        fi

        # Obtener el elemento seleccionado (restando 1 al índice)
        local seleccionado="${listado[$((selection-1))]}"

        # Comprobar si es directorio: se intenta listar su contenido
        if lftp -c "open ${FTP_BASE_URL}; cls -1 ${ftp_path}${seleccionado}/" &>/dev/null; then
            # Es un directorio, actualizar la ruta y repetir
            ftp_path="${ftp_path}${seleccionado}"
            continue
        else
            # Es un archivo, verificar que sea .tar.gz
            if [[ "$seleccionado" != *.tar.gz ]]; then
                echo "El archivo '$seleccionado' no es un .tar.gz válido. Selecciona otro archivo o directorio."
                continue
            fi
            # Confirmar descarga
	   read -p "¿Desea descargar el archivo '$seleccionado'? (s/n): " confirmacion
	   if [[ "$confirmacion" =~ ^[sS] ]]; then
	       # Normalizar ftp_path: quitar las barras al inicio y al final para obtener solo el nombre de la carpeta
	       local carpeta_servicio
	       carpeta_servicio=$(echo "$ftp_path" | sed 's#^/*##; s#/*$##')
	    
	       # Extraer solo el nombre del archivo (sin rutas adicionales)
	       local archivo
	       archivo=$(basename "$seleccionado")
	    
	       # Construir la URL final: 
	       # FTP_BASE_URL sin la barra final, seguida de '/', la carpeta y el nombre del archivo.
	    url_normalizada="${FTP_BASE_URL%/}/${carpeta_servicio}/${archivo}"
	    
	    echo "Descargando ${url_normalizada}..."
	    if wget "$url_normalizada" -O "/tmp/${archivo}" &>/dev/null; then
		echo "Archivo descargado en /tmp/${archivo}"
		# Exportar la variable ARCHIVO_FTP con el formato deseado:
		export ARCHIVO="${archivo}"
		export DESCARGADO="true"
		return 0
	    else
		echo "Error en la descarga. Intenta nuevamente."
		return 1
	    fi
	else
	    echo "Descarga cancelada, selecciona otra opción."
	    continue
	fi
        fi
    done
}


# Función para instalar servicios HTTP descargando los .tar.gz desde el FTP
instalar_http_desde_ftp() {
    echo ""
    echo "Iniciando instalación de servicios HTTP (descargando archivos desde el FTP)..."
    
    # Se requiere que FTP_BASE_URL esté definido. Si no, lo definimos (o se puede obtener de funciones_http.sh)
    FTP_BASE_URL=${FTP_BASE_URL:-"ftp://localhost/"}
    
    # Llamar a la función para explorar y descargar el archivo .tar.gz desde el FTP
    if explorar_ftp; then
        echo "Archivo descargado correctamente desde el FTP."
        export INSTALACION_FUENTE="ftp"
        # Se podría pasar el archivo descargado a http.sh a través de la variable ARCHIVO_FTP si es necesario
        if [ -x "./http.sh" ]; then
            ./http.sh
        else
            bash http.sh
        fi
        unset INSTALACION_FUENTE
    else
        echo "No se descargó ningún archivo. Cancelando la instalación."
    fi
}


# Menú principal
while true; do
    unset DESCARGADO
    clear
    echo "======================================="
    echo "             MENÚ PRINCIPAL"
    echo "======================================="
    echo "1. Configurar servidor FTP"
    echo "2. Instalar servicios HTTP (instalación online)"
    echo "3. Instalar servicios HTTP (descargar .tar.gz desde FTP)"
    echo "4. Salir"
    echo "======================================="
    read -p "Selecciona una opción (1-4): " opcion

    case "$opcion" in
        1)
            configurar_ftp
            ;;
        2)
            instalar_http_local
            ;;
        3)
            instalar_http_desde_ftp
            ;;
        4)
            echo ""
            echo "Saliendo del script principal..."
            exit 0
            ;;
        *)
            echo ""
            echo "Opción no válida. Elige una opción entre 1 y 4."
            ;;
    esac

    read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
done

