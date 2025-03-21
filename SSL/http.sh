#!/bin/bash
# http.sh:
# Script principal para la instalación de servicios HTTP.
# Zapien Rivera Jesús Javier
# 302 IS

source "$(dirname "$0")/funciones_http.sh"

# --- Inicio del script ---
while true; do
    if [[ "$DESCARGADO" == "true" ]]; then
	    echo ""
	    echo "Se detectó archivo descargado: $ARCHIVO"
	    echo "Extrayendo servicio desde el nombre del archivo..."

	    # Extraer el nombre del servicio usando regex (nginx, tomcat o lighttpd)
	    if [[ "$ARCHIVO" =~ (nginx|tomcat|lighttpd) ]]; then
		servicio="${BASH_REMATCH[1]}"
	    else
		echo "No se pudo determinar el servicio a instalar a partir del archivo '$ARCHIVO'."
		exit 1
	    fi	
	    case "$servicio" in
		    nginx)
			opcion_servicio=1
			;;
		    tomcat)
			opcion_servicio=2
			;;
		    lighttpd)
			opcion_servicio=3
			;;
		    *)
			echo "Servicio desconocido: $servicio"
			exit 1
			;;
	    esac
    else
	    echo ""
	    echo "=== Instalación de Servicios HTTP ==="
	    echo ""
	    echo "======================================="
	    echo "  Selecciona el servicio HTTP a instalar"
	    echo "======================================="
	    echo "1. Nginx"
	    echo "2. Tomcat"
	    echo "3. Lighttpd"
	    echo "4. Salir"
	    echo "======================================="
	    echo ""
	    read -p "Selecciona una opción (1-4): " opcion_servicio
    fi

	    case "$opcion_servicio" in
		1)
		    instalar_servicio_http "nginx" 
		    ;;
		2)
		    instalar_servicio_http "tomcat" 
		    ;;
		3)
		    instalar_servicio_http "lighttpd" 
		    ;;
		4)
		    echo "Saliendo del script..."
		    exit 0
		    ;;
		*)
		    echo "Opción no válida. Por favor, selecciona una opción del 1 al 4."
		    ;;
	    esac
     unset DESCARGADO
done

